import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MusicFolderAccess") {
      MusicFolderAccess.register(with: registrar)
    }
  }
}

/// Lets the user pick a music folder that lives outside the app, such as a
/// Syncthing folder, and keeps access to it across launches.
///
/// iOS only grants a picked folder's path while the app holds its
/// security-scoped URL, so a bookmark of each folder is saved and resolved
/// again on launch. Once access is started, plain dart:io file access under
/// that path works (reading, scanning, writing tags in place).
final class MusicFolderAccess: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
  private static let bookmarksKey = "musicFolderBookmarks"
  private var pendingResult: FlutterResult?
  /// Folders currently being accessed; access is held until the app exits.
  private var accessed: [URL] = []

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "insta_playlist/music_folders", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(MusicFolderAccess(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickFolder":
      pickFolder(result)
    case "restoreFolders":
      result(restoreFolders())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickFolder(_ result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "busy", message: "A pick is already in progress", details: nil))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(code: "no_view", message: "Nothing to present the picker from", details: nil))
      return
    }
    pendingResult = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
    finish(nil)
  }

  func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first, startAccessing(url) else {
      finish(FlutterError(code: "no_access", message: "Couldn't access that folder", details: nil))
      return
    }
    do {
      let bookmark = try url.bookmarkData()
      var bookmarks = savedBookmarks().filter { resolve($0)?.standardizedFileURL != url.standardizedFileURL }
      bookmarks.append(bookmark)
      UserDefaults.standard.set(bookmarks, forKey: Self.bookmarksKey)
    } catch {
      // Still usable for this session, just not remembered.
    }
    finish(url.path)
  }

  /// Resolves the saved folders, starts access to each, and returns their
  /// paths. Folders that can't be resolved right now (e.g. the sync app was
  /// removed) are skipped but kept, in case they come back.
  private func restoreFolders() -> [String] {
    var paths: [String] = []
    var bookmarks = savedBookmarks()
    for (i, bookmark) in bookmarks.enumerated() {
      var stale = false
      guard let url = try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &stale),
            startAccessing(url)
      else { continue }
      if stale, let fresh = try? url.bookmarkData() {
        bookmarks[i] = fresh
      }
      paths.append(url.path)
    }
    UserDefaults.standard.set(bookmarks, forKey: Self.bookmarksKey)
    return paths
  }

  private func startAccessing(_ url: URL) -> Bool {
    if accessed.contains(url.standardizedFileURL) { return true }
    guard url.startAccessingSecurityScopedResource() else {
      // Folders inside the app's own container aren't security-scoped.
      return FileManager.default.isReadableFile(atPath: url.path)
    }
    accessed.append(url.standardizedFileURL)
    return true
  }

  private func savedBookmarks() -> [Data] {
    UserDefaults.standard.array(forKey: Self.bookmarksKey) as? [Data] ?? []
  }

  private func resolve(_ bookmark: Data) -> URL? {
    var stale = false
    return try? URL(resolvingBookmarkData: bookmark, bookmarkDataIsStale: &stale)
  }

  private func finish(_ value: Any?) {
    pendingResult?(value)
    pendingResult = nil
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}
