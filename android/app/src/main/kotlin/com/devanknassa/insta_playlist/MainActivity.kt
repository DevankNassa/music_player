package com.devanknassa.insta_playlist

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.DocumentsContract
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

// audio_service needs the activity to share its FlutterEngine with the
// background playback service that owns the media notification.
class MainActivity : AudioServiceActivity() {
    private val folders = MusicFolderAccess(this)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "insta_playlist/music_folders")
            .setMethodCallHandler(folders::handle)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!folders.onActivityResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }
}

/// Lets the user pick a music folder, such as a Syncthing folder, and keeps
/// write access to it across launches without "All files access" (which
/// Google Play only allows for file managers and the like).
///
/// Reading and scanning still go through plain file paths, which
/// READ_MEDIA_AUDIO allows. Writing to files another app created is blocked
/// through paths, so tags are written to a temp copy and copied back over
/// the original through the folder's persisted document-tree grant.
private class MusicFolderAccess(private val activity: Activity) {
    private var pendingPick: MethodChannel.Result? = null

    fun handle(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "restoreFolders" -> result.success(grantedFolders().map { it.second })
            "writeBack" -> writeBack(call.argument("path")!!, call.argument("source")!!, result)
            else -> result.notImplemented()
        }
    }

    private fun pickFolder(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "A pick is already in progress", null)
            return
        }
        pendingPick = result
        activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), REQUEST_PICK)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK) return false
        val result = pendingPick ?: return true
        pendingPick = null
        val tree = data?.data
        if (resultCode != Activity.RESULT_OK || tree == null) {
            result.success(null)
            return true
        }
        val path = treePath(tree)
        if (path == null) {
            result.error("no_access", "Pick a folder on the device's storage", null)
            return true
        }
        activity.contentResolver.takePersistableUriPermission(
            tree,
            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
        )
        result.success(path)
        return true
    }

    /// Replaces the contents of [path] with those of [source], through the
    /// grant of whichever picked folder contains [path].
    private fun writeBack(path: String, source: String, result: MethodChannel.Result) {
        val (tree, root) = grantedFolders().firstOrNull { (_, root) -> path.startsWith("$root/") }
            ?: return result.error("no_access", "This song isn't in a folder added with + Add", null)
        Thread {
            try {
                val treeId = DocumentsContract.getTreeDocumentId(tree)
                val relative = path.removePrefix("$root/")
                val docId = if (treeId.endsWith(":")) treeId + relative else "$treeId/$relative"
                val doc = DocumentsContract.buildDocumentUriUsingTree(tree, docId)
                // "wt" truncates; plain "w" leaves stale bytes if the file shrank.
                activity.contentResolver.openOutputStream(doc, "wt")!!.use { out ->
                    File(source).inputStream().use { it.copyTo(out) }
                }
                activity.runOnUiThread { result.success(null) }
            } catch (e: Exception) {
                activity.runOnUiThread { result.error("write_failed", e.message, null) }
            }
        }.start()
    }

    /// Picked folders this app still has write access to, with their paths.
    private fun grantedFolders(): List<Pair<Uri, String>> =
        activity.contentResolver.persistedUriPermissions
            .filter { it.isWritePermission }
            .mapNotNull { perm -> treePath(perm.uri)?.let { perm.uri to it } }

    /// Turns a tree URI like `primary:Music/Sync` into the matching
    /// filesystem path, or null if it isn't on local storage (e.g. a cloud
    /// provider), where path-based scanning can't reach.
    private fun treePath(tree: Uri): String? {
        if (tree.authority != "com.android.externalstorage.documents") return null
        val (volume, relative) = DocumentsContract.getTreeDocumentId(tree).split(":", limit = 2)
            .let { it[0] to it.getOrElse(1) { "" } }
        @Suppress("DEPRECATION")
        val volumeRoot = if (volume == "primary") {
            Environment.getExternalStorageDirectory().path
        } else {
            "/storage/$volume"
        }
        return if (relative.isEmpty()) volumeRoot else "$volumeRoot/$relative"
    }

    companion object {
        private const val REQUEST_PICK = 4711
    }
}
