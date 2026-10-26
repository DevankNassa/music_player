import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/library_store.dart';
import '../state/queue_player.dart';
import '../widgets/playback_controls.dart';
import '../widgets/seek_bar.dart';
import '../widgets/tag_actions.dart';

class QuickTagScreen extends StatelessWidget {
  const QuickTagScreen({super.key});

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

    final current = currentLibraryCopy(libraryStore, playing);
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
                        saveTags(context, current, updated);
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('New tag'),
                    onPressed: () => promptNewTag(context, current),
                  ),
                ],
              ),
            ),
          ),
          SeekBar(queuePlayer: queuePlayer),
          Center(child: PlaybackControls(queuePlayer: queuePlayer)),
        ],
      ),
    );
  }
}
