import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../services/tag_service.dart';

/// The app's shared song library. Tags are persisted straight to each
/// file's own metadata (see TagService), so this store is just an
/// in-memory reflection of what's on disk for the songs added this run.
class LibraryStore extends ChangeNotifier {
  final List<Song> _songs = [];

  List<Song> get songs => List.unmodifiable(_songs);

  Set<String> get allTags => _songs.expand((s) => s.tags).toSet();

  void addSongs(List<Song> newSongs) {
    if (newSongs.isEmpty) return;
    _songs.addAll(newSongs);
    notifyListeners();
  }

  Future<void> setTags(Song song, Set<String> tags) async {
    await TagService.writeTags(song.filePath, tags);
    final index = _songs.indexWhere((s) => s.filePath == song.filePath);
    if (index != -1) {
      _songs[index] = song.copyWith(tags: tags);
      notifyListeners();
    }
  }
}
