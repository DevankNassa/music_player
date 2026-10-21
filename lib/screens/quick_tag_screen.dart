import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';
import '../widgets/playback_controls.dart';
import '../widgets/seek_bar.dart';

class QuickTagScreen extends StatelessWidget {
  const QuickTagScreen({super.key});

  Future<void> _saveTags(
    BuildContext context,
    Song song,
    Set<String> tags,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<LibraryStore>().setTags(song, tags);
    } on TagWriteException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _promptNewTag(BuildContext context, Song song) async {
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
    await _saveTags(context, song, {...song.tags, trimmed});
  }

  @override
  Widget build(BuildContext context) {
    final libraryStore = context.watch<LibraryStore>();
    final queuePlayer = context.watch<QueuePlayer>();
    final library = libraryStore.songs;
    final playing = queuePlayer.currentSong;

    if (library.isEmpty) {
      return const Center(child: Text('Add songs in the Library tab first.'));
    }

    if (playing == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => queuePlayer.setQueue(library),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start tagging session'),
        ),
      );
    }

    // Tags can change while the song plays; always read the current
    // value from the library, not the (possibly stale) queued copy.
    final current = library.firstWhere(
      (s) => s.filePath == playing.filePath,
      orElse: () => playing,
    );
    final allTags = libraryStore.allTags;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(current.title, style: Theme.of(context).textTheme.headlineSmall),
          if (current.artist != null)
            Text(current.artist!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 24),
          Text('Tags', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          // Tags are unlimited, so let them scroll rather than push the
          // playback controls off screen.
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...allTags.map((tag) {
                    final applied = current.tags.contains(tag);
                    return FilterChip(
                      label: Text(tag),
                      selected: applied,
                      onSelected: (selected) {
                        final updated = {...current.tags};
                        selected ? updated.add(tag) : updated.remove(tag);
                        _saveTags(context, current, updated);
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('New tag'),
                    onPressed: () => _promptNewTag(context, current),
                  ),
                ],
              ),
            ),
          ),
          SeekBar(queuePlayer: queuePlayer),
          PlaybackControls(queuePlayer: queuePlayer),
        ],
      ),
    );
  }
}
