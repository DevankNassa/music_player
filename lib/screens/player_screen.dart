import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';
import '../widgets/playback_controls.dart';
import '../widgets/seek_bar.dart';
import '../widgets/tag_actions.dart';

/// Full-screen view of the song that's playing. Unlike Quick Tag, which
/// lays out every tag as a toggle, this shows just the song's own tags,
/// each removable, with a picker for adding more.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  Future<void> _showAddTagSheet(BuildContext context, Song song) async {
    final available = context
        .read<LibraryStore>()
        .allTags
        .where((t) => !song.tags.contains(t))
        .toList()
      ..sort();

    // null = "New tag…" was picked.
    final picked = await showModalBottomSheet<_TagChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New tag…'),
                onTap: () => Navigator.of(context).pop(const _TagChoice(null)),
              ),
              if (available.isNotEmpty) const Divider(),
              ...available.map(
                (tag) => ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: Text(tag),
                  onTap: () => Navigator.of(context).pop(_TagChoice(tag)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final tag = picked.tag;
    if (tag == null) {
      await promptNewTag(context, song);
    } else {
      await saveTags(context, song, {...song.tags, tag});
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryStore = context.watch<LibraryStore>();
    final queuePlayer = context.watch<QueuePlayer>();
    final library = libraryStore.songs;
    final playing = queuePlayer.currentSong;
    final theme = Theme.of(context);

    if (playing == null) {
      if (library.isEmpty) {
        return const Center(child: Text('Nothing playing. Add songs in the Library tab.'));
      }
      return Center(
        child: FilledButton.icon(
          onPressed: () => queuePlayer.setQueue(library),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Play library'),
        ),
      );
    }

    final current = currentLibraryCopy(libraryStore, playing);
    final tags = current.tags.toList()..sort();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.music_note,
                  size: 120,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          current.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (current.artist != null)
          Text(
            current.artist!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        const SizedBox(height: 16),
        SeekBar(queuePlayer: queuePlayer),
        Center(child: PlaybackControls(queuePlayer: queuePlayer)),
        const SizedBox(height: 24),
        Text('Tags', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tags.map(
              (tag) => InputChip(
                label: Text(tag),
                onDeleted: () =>
                    saveTags(context, current, {...current.tags}..remove(tag)),
                deleteButtonTooltipMessage: 'Remove tag',
              ),
            ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text('Add tag'),
              onPressed: () => _showAddTagSheet(context, current),
            ),
          ],
        ),
      ],
    );
  }
}

/// Wraps the bottom sheet result so "New tag…" (null tag) is distinguishable
/// from the sheet being dismissed (null result).
class _TagChoice {
  final String? tag;
  const _TagChoice(this.tag);
}
