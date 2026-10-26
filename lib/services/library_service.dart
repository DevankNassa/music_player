import 'dart:convert';
import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/song.dart';
import 'tag_service.dart';

const audioExtensions = {'.mp3', '.flac', '.wav', '.m4a', '.aac', '.ogg', '.opus'};

bool isAudioFile(String filePath) => audioExtensions.contains(p.extension(filePath).toLowerCase());

class LibraryService {
  /// Individually SAF-picked files get their own access grant automatically,
  /// but recursively walking a folder path (scanFolder, folder watching)
  /// needs the broader audio/storage permission on Android. No-op on
  /// desktop, where permission_handler has no platform implementation.
  static Future<bool> ensureAudioPermission() async {
    if (!Platform.isAndroid) return true;
    if ((await Permission.audio.request()).isGranted) return true;
    return (await Permission.storage.request()).isGranted;
  }

  /// Writing tags into files another app saved (e.g. Downloads) needs
  /// "All files access" on Android 11+; READ_MEDIA_AUDIO only allows
  /// reading them. Requesting it opens the system settings toggle.
  static Future<bool> ensureWritePermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    if ((await Permission.manageExternalStorage.request()).isGranted) return true;
    // Android 10 and below have no "All files access"; storage covers writes.
    return (await Permission.storage.request()).isGranted;
  }

  static const _iosFolders = MethodChannel('insta_playlist/music_folders');

  /// Opens the system file picker for audio files and returns a [Song] for
  /// each one picked, with metadata (title/artist/tags) read from the file.
  static Future<List<Song>> pickSongs() async {
    final files = await FilePicker.pickFiles(type: FileType.audio);

    final songs = <Song>[];
    for (final file in files) {
      final path = file.path;
      if (path == null) continue;
      songs.add(await loadSongFromPath(path));
    }
    return songs;
  }

  /// Opens the system folder picker and returns its path, or null if
  /// canceled or audio permission was denied.
  ///
  /// On iOS the folder (e.g. a Syncthing folder) is remembered with a
  /// security-scoped bookmark so it stays readable and taggable in place
  /// across launches; see MusicFolderAccess in ios/Runner/AppDelegate.swift.
  static Future<String?> pickFolder() async {
    if (Platform.isIOS) return _iosFolders.invokeMethod<String>('pickFolder');
    if (!await ensureAudioPermission()) return null;
    final folder = await FilePicker.getDirectoryPath();
    if (folder != null && _isDesktop) await _rememberDesktopFolder(folder);
    return folder;
  }

  /// Returns the folders picked in earlier sessions, so the library comes
  /// back on launch. On iOS this also regains access to them.
  static Future<List<String>> restoreFolders() async {
    if (Platform.isIOS) {
      return await _iosFolders.invokeListMethod<String>('restoreFolders') ?? [];
    }
    if (!_isDesktop) return [];
    return (await _readDesktopFolders()).where((f) => Directory(f).existsSync()).toList();
  }

  static bool get _isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  /// Desktop has no bookmark mechanism to lean on; picked folder paths are
  /// just kept in a JSON list in the app support directory.
  static Future<File> _desktopFoldersFile() async =>
      File(p.join((await getApplicationSupportDirectory()).path, 'music_folders.json'));

  static Future<List<String>> _readDesktopFolders() async {
    try {
      final file = await _desktopFoldersFile();
      if (!file.existsSync()) return [];
      return List<String>.from(jsonDecode(await file.readAsString()) as List);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _rememberDesktopFolder(String folder) async {
    final folders = await _readDesktopFolders();
    if (folders.contains(folder)) return;
    final file = await _desktopFoldersFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode([...folders, folder]));
  }

  /// Recursively scans a folder for audio files and loads each as a [Song].
  static Future<List<Song>> scanFolder(String folderPath) async {
    final songs = <Song>[];
    for (final path in await listAudioFiles(folderPath)) {
      songs.add(await loadSongFromPath(path));
    }
    return songs;
  }

  /// Paths of the audio files anywhere under [folderPath], without reading
  /// their metadata.
  static Future<List<String>> listAudioFiles(String folderPath) async {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return [];

    final paths = <String>[];
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && isAudioFile(entity.path)) paths.add(entity.path);
    }
    return paths;
  }

  static Future<Song> loadSongFromPath(String filePath) async {
    // A file with unreadable metadata is still playable, so add it under
    // its file name rather than failing the whole add.
    Tag? tag;
    try {
      tag = await TagService.readRawTag(filePath);
    } catch (_) {}
    final fileName = p.basenameWithoutExtension(filePath);
    return Song(
      filePath: filePath,
      title: (tag?.title?.trim().isNotEmpty ?? false) ? tag!.title! : fileName,
      artist: tag?.trackArtist,
      tags: TagService.extractTags(tag),
    );
  }
}
