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

/// Asks for a new tag name and adds it to [song].
Future<void> promptNewTag(BuildContext context, Song song) async {
  final controller = TextEditingController();
  final newTag = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New tag'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. family-road-trip'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Add'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  final trimmed = newTag?.trim();
  if (trimmed == null || trimmed.isEmpty) return;
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
