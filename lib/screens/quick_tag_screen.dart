import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';
import '../theme/organic.dart';
import '../widgets/disc.dart';
import '../widgets/organic.dart';
import '../widgets/seek_bar.dart';
import '../widgets/tag_actions.dart';

/// Quick Tag mode: a compact now-playing card over a big two-column pad of
/// every tag in the library. Tapping a tile toggles it on the playing song.
class QuickTagScreen extends StatefulWidget {
  const QuickTagScreen({super.key});

  @override
  State<QuickTagScreen> createState() => _QuickTagScreenState();
}

class _QuickTagScreenState extends State<QuickTagScreen> {
  /// The "+ New tag" tile becomes a text field while this is true.
  bool _typing = false;

  @override
  Widget build(BuildContext context) {
    final libraryStore = context.watch<LibraryStore>();
    final queuePlayer = context.watch<QueuePlayer>();
    final library = libraryStore.songs;
    final playing = queuePlayer.currentSong;

    if (library.isEmpty) {
      return const EmptyState(text: 'Add songs in the Library tab first.');
    }

    if (playing == null) {
      return Center(
        child: FilledButton(
          onPressed: () => queuePlayer.setQueue(library),
          child: const Text('Start tagging session'),
        ),
      );
    }

    final current = currentLibraryCopy(libraryStore, playing);
    final allTags = libraryStore.allTags.toList()..sort();
    int songCount(String tag) => library.where((s) => s.tags.contains(tag)).length;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: _NowPlayingCard(queuePlayer: queuePlayer, song: current),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text('Tag pad', style: Organic.headingStyle(20))),
                Text(
                  '${current.tags.length} on this song',
                  style: const TextStyle(fontSize: 12, color: Organic.neutral700),
                ),
              ],
            ),
          ),
          Expanded(
            // Tags are unlimited, so the pad scrolls rather than pushing the
            // now-playing card off screen.
            child: GridView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 72,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              children: [
                for (final tag in allTags)
                  _TagTile(
                    tag: tag,
                    songCount: songCount(tag),
                    applied: current.tags.contains(tag),
                    onTap: () {
                      final updated = {...current.tags};
                      updated.contains(tag) ? updated.remove(tag) : updated.add(tag);
                      saveTags(context, current, updated);
                    },
                  ),
                if (_typing)
                  TextField(
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 16),
                    expands: true,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'New tag…',
                      border: _tileBorder(Organic.divider),
                      enabledBorder: _tileBorder(Organic.divider),
                      focusedBorder: _tileBorder(Organic.accent),
                    ),
                    onTapOutside: (_) => setState(() => _typing = false),
                    onSubmitted: (value) {
                      setState(() => _typing = false);
                      addNewTag(context, current, value);
                    },
                  )
                else
                  DashedOutline(
                    radius: 26,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() => _typing = true),
                        hoverColor: Organic.accent100,
                        child: Center(
                          child: Text(
                            '+ New tag',
                            style: Organic.headingStyle(17, color: Organic.neutral700),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static OutlineInputBorder _tileBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(26),
    borderSide: BorderSide(color: color),
  );
}

class _TagTile extends StatelessWidget {
  final String tag;
  final int songCount;
  final bool applied;
  final VoidCallback onTap;

  const _TagTile({
    required this.tag,
    required this.songCount,
    required this.applied,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = applied ? Organic.neutral100 : Organic.text;
    return Semantics(
      toggled: applied,
      child: Material(
        color: applied ? Organic.accent2_600 : Organic.surface,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Organic.headingStyle(17, color: fg, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  '$songCount ${songCount == 1 ? 'song' : 'songs'}',
                  style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark card with ring play button, title, stacked prev/next and a seek bar.
class _NowPlayingCard extends StatelessWidget {
  final QueuePlayer queuePlayer;
  final Song song;

  const _NowPlayingCard({required this.queuePlayer, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(color: Organic.neutral900, borderRadius: BorderRadius.circular(30)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              RingPlayButton(
                size: 64,
                innerSize: 52,
                progress: queuePlayer.progress,
                playing: queuePlayer.isPlaying,
                onPressed: queuePlayer.togglePlayPause,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Organic.headingStyle(20, color: Organic.neutral100, height: 1.15),
                    ),
                    if (song.artist != null)
                      Text(
                        song.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Organic.neutral100.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RoundIconButton(
                    icon: Icons.skip_previous_rounded,
                    tooltip: 'Previous',
                    kind: RoundButtonKind.ghost,
                    color: Organic.neutral100,
                    size: 32,
                    iconSize: 20,
                    onPressed: queuePlayer.hasPrevious ? queuePlayer.previous : null,
                  ),
                  const SizedBox(height: 4),
                  RoundIconButton(
                    icon: Icons.skip_next_rounded,
                    tooltip: 'Next',
                    kind: RoundButtonKind.ghost,
                    color: Organic.neutral100,
                    size: 32,
                    iconSize: 20,
                    onPressed: queuePlayer.hasNext ? queuePlayer.next : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SeekBar(queuePlayer: queuePlayer, dark: true),
        ],
      ),
    );
  }
}
