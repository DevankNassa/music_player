import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString();
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class QuickTagScreen extends StatelessWidget {
  const QuickTagScreen({super.key});

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
    final updated = {...song.tags, trimmed};
    await context.read<LibraryStore>().setTags(song, updated);
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
          Wrap(
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
                    context.read<LibraryStore>().setTags(current, updated);
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
          const Spacer(),
          Builder(
            builder: (context) {
              final duration = queuePlayer.duration;
              final position = queuePlayer.position;
              final seekable = duration > Duration.zero;
              final clampedMs = position.inMilliseconds
                  .clamp(0, seekable ? duration.inMilliseconds : 0)
                  .toDouble();
              return Column(
                children: [
                  Slider(
                    value: clampedMs,
                    max: seekable ? duration.inMilliseconds.toDouble() : 1,
                    onChanged: seekable
                        ? (value) => queuePlayer.seek(Duration(milliseconds: value.round()))
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position)),
                        Text(_formatDuration(duration)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 36,
                onPressed: queuePlayer.hasPrevious ? queuePlayer.previous : null,
                icon: const Icon(Icons.skip_previous),
              ),
              IconButton(
                iconSize: 56,
                onPressed: queuePlayer.togglePlayPause,
                icon: Icon(
                  queuePlayer.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                ),
              ),
              IconButton(
                iconSize: 36,
                onPressed: queuePlayer.hasNext ? queuePlayer.next : null,
                icon: const Icon(Icons.skip_next),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
