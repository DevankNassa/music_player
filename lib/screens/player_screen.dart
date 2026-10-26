import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';
import '../theme/organic.dart';
import '../widgets/disc.dart';
import '../widgets/organic.dart';
import '../widgets/playback_controls.dart';
import '../widgets/seek_bar.dart';
import '../widgets/tag_actions.dart';

/// Full-screen view of the song that's playing. Unlike the Tag pad, which
/// lays out every tag as a toggle, this shows just the song's own tags,
/// each removable, with a picker for adding more.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  /// The disc hangs off the top-right corner, partly offscreen.
  static const _discSize = 330.0;
  static const _discTop = -30.0;

  Future<void> _showAddTagSheet(BuildContext context, Song song) async {
    final available =
        context.read<LibraryStore>().allTags.where((t) => !song.tags.contains(t)).toList()..sort();

    final picked = await showOrganicSheet<String>(
      context: context,
      builder: (context) => _AddTagSheet(available: available),
    );
    if (picked == null || !context.mounted) return;
    await addNewTag(context, song, picked);
  }

  @override
  Widget build(BuildContext context) {
    final libraryStore = context.watch<LibraryStore>();
    final queuePlayer = context.watch<QueuePlayer>();
    final library = libraryStore.songs;
    final playing = queuePlayer.currentSong;

    if (playing == null) {
      if (library.isEmpty) {
        return const EmptyState(text: 'Nothing playing. Add songs in the Library tab.');
      }
      return Center(
        child: FilledButton(
          onPressed: () => queuePlayer.setQueue(library),
          child: const Text('Play library'),
        ),
      );
    }

    final current = currentLibraryCopy(libraryStore, playing);
    final tags = current.tags.toList()..sort();
    final topInset = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned(
          right: -70,
          top: _discTop,
          child: PlayerDisc(size: _discSize, progress: queuePlayer.progress),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Text(
                  'Now playing · ${queuePlayer.queueIndex + 1} of ${queuePlayer.queueLength}'
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: Organic.accent700,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    // Start the title just below the disc, wherever the
                    // status bar puts the top of this column.
                    (_discTop + _discSize + 4 - topInset - 28).clamp(16.0, double.infinity),
                    14,
                    14,
                  ),
                  children: [
                    // The tags card is 8px wider than this text column.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(current.title, style: Organic.headingStyle(30, height: 1.1)),
                          if (current.artist != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                current.artist!,
                                style: const TextStyle(fontSize: 15, color: Organic.neutral700),
                              ),
                            ),
                          const SizedBox(height: 20),
                          SeekBar(queuePlayer: queuePlayer),
                          const SizedBox(height: 12),
                          Center(child: PlaybackControls(queuePlayer: queuePlayer)),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                    _TagsCard(
                      tags: tags,
                      onRemove: (tag) => saveTags(context, current, {...current.tags}..remove(tag)),
                      onAdd: () => _showAddTagSheet(context, current),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagsCard extends StatelessWidget {
  final List<String> tags;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  const _TagsCard({required this.tags, required this.onRemove, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(color: Organic.surface, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text('Tags', style: Organic.headingStyle(18))),
              Text(
                '${tags.length} on this song',
                style: const TextStyle(fontSize: 12, color: Organic.neutral700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final tag in tags) TagPill(tag: tag, onRemove: () => onRemove(tag)),
              if (tags.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text(
                    'No tags yet.',
                    style: TextStyle(fontSize: 13, color: Organic.neutral700),
                  ),
                ),
              PillButton(label: '+ Add tag', onTap: onAdd),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lists the library's other tags; "New tag…" turns into an inline field.
/// Pops with the chosen or typed tag name.
class _AddTagSheet extends StatefulWidget {
  final List<String> available;

  const _AddTagSheet({required this.available});

  @override
  State<_AddTagSheet> createState() => _AddTagSheetState();
}

class _AddTagSheetState extends State<_AddTagSheet> {
  bool _typing = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        if (_typing)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: TextField(
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'e.g. family-road-trip'),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          )
        else
          SheetRow(
            filled: true,
            padding: const EdgeInsets.all(12),
            onTap: () => setState(() => _typing = true),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Organic.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, size: 20, color: Organic.neutral100),
                ),
                const SizedBox(width: 12),
                const Text('New tag…', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ),
        const SizedBox(height: 2),
        for (final tag in widget.available)
          SheetRow(
            onTap: () => Navigator.of(context).pop(tag),
            child: Text(tag, style: const TextStyle(fontSize: 15)),
          ),
      ],
    );
  }
}
