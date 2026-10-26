import 'package:flutter/material.dart';

import '../state/queue_player.dart';
import '../theme/organic.dart';
import 'disc.dart';
import 'organic.dart';
import 'seek_bar.dart';

/// Floating dark mini-player dock shown above the tab bar on Library and
/// Mix, so playback stays reachable wherever you are in the app. Screens it
/// floats over pad their scroll content by [dockClearance].
class NowPlayingBar extends StatelessWidget {
  final QueuePlayer queuePlayer;

  const NowPlayingBar({super.key, required this.queuePlayer});

  /// Bottom padding a scrolling screen needs so its last row can scroll out
  /// from under the dock.
  static const dockClearance = 98.0;

  @override
  Widget build(BuildContext context) {
    final song = queuePlayer.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Organic.neutral900,
        borderRadius: BorderRadius.circular(30),
        boxShadow: Organic.shadowLg,
      ),
      child: Row(
        children: [
          RingPlayButton(
            size: 50,
            innerSize: 40,
            progress: queuePlayer.progress,
            playing: queuePlayer.isPlaying,
            onPressed: queuePlayer.togglePlayPause,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Organic.headingStyle(16, color: Organic.neutral100, height: 1.3),
                ),
                Text(
                  [
                    if (song.artist != null) song.artist!,
                    formatDuration(queuePlayer.position),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Organic.neutral100.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          RoundIconButton(
            icon: Icons.skip_previous_rounded,
            tooltip: 'Previous',
            kind: RoundButtonKind.ghost,
            color: Organic.neutral100,
            size: 36,
            iconSize: 22,
            onPressed: queuePlayer.hasPrevious ? queuePlayer.previous : null,
          ),
          RoundIconButton(
            icon: Icons.skip_next_rounded,
            tooltip: 'Next',
            kind: RoundButtonKind.ghost,
            color: Organic.neutral100,
            size: 36,
            iconSize: 22,
            onPressed: queuePlayer.hasNext ? queuePlayer.next : null,
          ),
        ],
      ),
    );
  }
}
