import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_store.dart';

/// Tag editing shared by the Quick Tag and Player tabs.

/// Saves [tags] to [song]'s file, showing a snackbar if the write fails.
Future<void> saveTags(BuildContext context, Song song, Set<String> tags) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await context.read<LibraryStore>().setTags(song, tags);
  } on TagWriteException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// Adds a tag typed into one of the inline "New tag" fields to [song].
/// Blank input is ignored.
Future<void> addNewTag(BuildContext context, Song song, String name) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return;
  await saveTags(context, song, {...song.tags, trimmed});
}

/// Tags can change while a song plays; read the current value from the
/// library, not the (possibly stale) queued copy.
Song currentLibraryCopy(LibraryStore libraryStore, Song playing) {
  return libraryStore.songs.firstWhere(
    (s) => s.filePath == playing.filePath,
    orElse: () => playing,
  );
}
