import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/song.dart';
import '../state/library_store.dart';
import '../state/queue_player.dart';
import '../state/tag_pad_settings.dart';
import '../theme/organic.dart';
import '../widgets/disc.dart';
import '../widgets/organic.dart';
import '../widgets/seek_bar.dart';
import '../widgets/tag_actions.dart';

/// Quick Tag mode, laid out for one thumb: the song being tagged is named at
/// the top, a big two-column pad of every tag in the library fills the
/// middle (pinned tags first, see Settings → Pinned tags), and the transport
/// sits at the bottom where the thumb already is. Tapping a tile toggles it
/// on the playing song.
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
    final c = Organic.of(context);
    final libraryStore = context.watch<LibraryStore>();
    final queuePlayer = context.watch<QueuePlayer>();
    final library = libraryStore.songs;
    final playing = queuePlayer.currentSong;

    if (library.isEmpty) {
      return const EmptyState(text: 'Add songs in the Library tab first.');
    }

    if (playing == null) {
      return EmptyState(
        title: 'Tag as you listen',
        text: 'Songs play one after another while you tap the tags that fit.',
        action: FilledButton(
          onPressed: () => queuePlayer.setQueue(library),
          child: const Text('Start tagging session'),
        ),
      );
    }

    final current = currentLibraryCopy(libraryStore, playing);
    final tagPad = context.watch<TagPadSettings>();
    final arranged = tagPad.arrange(libraryStore.allTags, libraryStore.songCountWithTag);

    Widget tile(String tag) => _TagTile(
      tag: tag,
      songCount: libraryStore.songCountWithTag(tag),
      applied: current.tags.contains(tag),
      onTap: () {
        HapticFeedback.selectionClick();
        final updated = {...current.tags};
        updated.contains(tag) ? updated.remove(tag) : updated.add(tag);
        saveTags(context, current, updated);
      },
    );

    OutlineInputBorder tileBorder(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(26),
      borderSide: BorderSide(color: color),
    );

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SongHeader(
            song: current,
            position: queuePlayer.queueIndex + 1,
            total: queuePlayer.queueLength,
          ),
          Expanded(
            // Tags are unlimited, so the pad scrolls between the header and
            // the transport.
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                const SliverPadding(padding: EdgeInsets.only(top: 2)),
                if (arranged.pinned.isNotEmpty) ...[
                  _padGrid([for (final tag in arranged.pinned) tile(tag)]),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Row(
                        children: [
                          Text(
                            tagPad.sort == TagSort.mostUsed
                                ? 'All other tags · most used'
                                : 'All other tags · A–Z',
                            style: TextStyle(fontSize: 12, color: c.neutral700),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Divider(height: 1, color: c.divider)),
                        ],
                      ),
                    ),
                  ),
                ],
                _padGrid([
                  for (final tag in arranged.rest) tile(tag),
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
                        border: tileBorder(c.divider),
                        enabledBorder: tileBorder(c.divider),
                        focusedBorder: tileBorder(c.accent),
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
                          hoverColor: c.accent100,
                          highlightColor: c.accent100,
                          child: Center(
                            child: Text(
                              '+ New tag',
                              style: Organic.headingStyle(17, color: c.neutral700),
                            ),
                          ),
                        ),
                      ),
                    ),
                ]),
                const SliverPadding(padding: EdgeInsets.only(bottom: 14)),
              ],
            ),
          ),
          // The keyboard needs the room while a new tag is being typed.
          if (!_typing)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _Transport(queuePlayer: queuePlayer),
            ),
        ],
      ),
    );
  }

  static Widget _padGrid(List<Widget> tiles) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    sliver: SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 72,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      delegate: SliverChildListDelegate(tiles),
    ),
  );
}

/// Which song the pad is tagging: its place in the queue, title, artist and
/// how many tags it has so far.
class _SongHeader extends StatelessWidget {
  final Song song;
  final int position;
  final int total;

  const _SongHeader({required this.song, required this.position, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    final count = song.tags.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 10, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tagging · $position of $total'.toUpperCase(),
                  style: Organic.eyebrowStyle(c.accent700),
                ),
                const SizedBox(height: 4),
                Text(
                  song.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Organic.headingStyle(24, height: 1.12),
                ),
                if (song.artist != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      song.artist!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.neutral700),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: count == 0 ? c.surface : c.accent2_200,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count on this song',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: count == 0 ? c.neutral700 : c.accent2_800,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    final c = Organic.of(context);
    final fg = applied ? c.neutral100 : c.text;
    return Semantics(
      toggled: applied,
      child: PressScale(
        scale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: applied ? c.accent2_600 : c.surface,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Row(
                  children: [
                    Expanded(
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
                    // A tick pops in on the tiles this song has.
                    AnimatedScale(
                      scale: applied ? 1 : 0,
                      duration: const Duration(milliseconds: 220),
                      curve: applied ? Curves.easeOutBack : Curves.easeIn,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: c.neutral100.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded, size: 16, color: c.accent2_600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dark card at the bottom of the screen: seek bar, then large previous /
/// play-pause / next buttons spread across the width.
class _Transport extends StatelessWidget {
  final QueuePlayer queuePlayer;

  const _Transport({required this.queuePlayer});

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: c.cardDecoration(radius: 32, boxShadow: c.shadowMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SeekBar(queuePlayer: queuePlayer, dark: true),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RoundIconButton(
                icon: Icons.skip_previous_rounded,
                tooltip: 'Previous',
                color: c.onCard,
                size: 56,
                iconSize: 30,
                onPressed: queuePlayer.hasPrevious ? queuePlayer.previous : null,
              ),
              RingPlayButton(
                size: 72,
                innerSize: 58,
                progress: queuePlayer.progress,
                playing: queuePlayer.isPlaying,
                onPressed: queuePlayer.togglePlayPause,
              ),
              RoundIconButton(
                icon: Icons.skip_next_rounded,
                tooltip: 'Next',
                color: c.onCard,
                size: 56,
                iconSize: 30,
                onPressed: queuePlayer.hasNext ? queuePlayer.next : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
