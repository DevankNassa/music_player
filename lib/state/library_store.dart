import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/song.dart';
import '../services/library_service.dart';
import '../services/tag_service.dart';

/// The app's shared song library. Tags are persisted straight to each
/// file's own metadata (see TagService), so this store is just an
/// in-memory reflection of what's on disk for the songs added this run.
///
/// Folders added via [addFolder] are watched for new files for the rest of
/// the session, so dropping a new track into a watched folder adds it
/// automatically. Picked folders are restored on launch on iOS and desktop
/// (see LibraryService.restoreFolders).
class LibraryStore extends ChangeNotifier {
  final List<Song> _songs = [];
  final Set<String> _knownPaths = {};
  final List<String> _watchedFolders = [];
  final List<StreamSubscription<FileSystemEvent>> _watchSubscriptions = [];

  List<Song> get songs => List.unmodifiable(_songs);
  List<String> get watchedFolders => List.unmodifiable(_watchedFolders);

  Set<String> get allTags => _songs.expand((s) => s.tags).toSet();

  void addSongs(List<Song> newSongs) {
    final toAdd = newSongs.where((s) => _knownPaths.add(s.filePath)).toList();
    if (toAdd.isEmpty) return;
    _songs.addAll(toAdd);
    notifyListeners();
  }

  Future<void> addFolder(String folderPath) async {
    final songs = await LibraryService.scanFolder(folderPath);
    addSongs(songs);
    if (!_watchedFolders.contains(folderPath)) {
      _watchedFolders.add(folderPath);
      _watchFolder(folderPath);
    }
  }

  /// Picks up songs added to or deleted from the folders while the app
  /// wasn't watching, e.g. synced by Syncthing while in the background, or
  /// on iOS, where folders can't be watched at all.
  Future<void> rescanFolders() async {
    final onDisk = <String>{};
    for (final folder in _watchedFolders) {
      onDisk.addAll(await LibraryService.listAudioFiles(folder));
    }

    final before = _songs.length;
    _songs.removeWhere((s) {
      final inFolder = _watchedFolders.any((f) => p.isWithin(f, s.filePath));
      final gone = inFolder && !onDisk.contains(s.filePath);
      if (gone) _knownPaths.remove(s.filePath);
      return gone;
    });
    var changed = _songs.length != before;

    for (final path in onDisk) {
      if (!_knownPaths.add(path)) continue;
      _songs.add(await LibraryService.loadSongFromPath(path));
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void _watchFolder(String folderPath) {
    if (!FileSystemEntity.isWatchSupported) return;
    final sub = Directory(folderPath)
        .watch(events: FileSystemEvent.create, recursive: true)
        .listen((event) async {
      if (event.isDirectory) return;
      if (!isAudioFile(event.path)) return;
      if (!_knownPaths.add(event.path)) return;
      final song = await LibraryService.loadSongFromPath(event.path);
      _songs.add(song);
      notifyListeners();
    }, onError: (_) {});
    _watchSubscriptions.add(sub);
  }

  /// Throws [TagWriteException] if the file couldn't be written, so the UI
  /// can tell the user instead of the tag silently not sticking.
  Future<void> setTags(Song song, Set<String> tags) async {
    if (!await LibraryService.ensureWritePermission()) {
      throw const TagWriteException(
        'Allow "All files access" for Insta-Playlist in system settings to save tags.',
      );
    }
    try {
      await TagService.writeTags(song.filePath, tags);
    } catch (e) {
      throw TagWriteException("Couldn't save tags to this file: $e");
    }
    final index = _songs.indexWhere((s) => s.filePath == song.filePath);
    if (index != -1) {
      _songs[index] = song.copyWith(tags: tags);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final sub in _watchSubscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

class TagWriteException implements Exception {
  final String message;
  const TagWriteException(this.message);

  @override
  String toString() => message;
}
