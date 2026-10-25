import 'dart:io';

import 'package:audiotags/audiotags.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
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
    return FilePicker.getDirectoryPath();
  }

  /// iOS only: regains access to the folders picked in earlier sessions and
  /// returns their paths.
  static Future<List<String>> restoreFolders() async {
    if (!Platform.isIOS) return [];
    return await _iosFolders.invokeListMethod<String>('restoreFolders') ?? [];
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
