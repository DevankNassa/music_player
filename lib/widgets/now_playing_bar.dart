import 'package:flutter/material.dart';

import '../state/queue_player.dart';
import 'playback_controls.dart';
import 'seek_bar.dart';

/// Persistent mini-player shown above the bottom nav on every tab, so
/// playback controls and the seeker are reachable no matter where you are
/// in the app.
class NowPlayingBar extends StatelessWidget {
  final QueuePlayer queuePlayer;

  const NowPlayingBar({super.key, required this.queuePlayer});

  @override
  Widget build(BuildContext context) {
    final song = queuePlayer.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (song.artist != null)
                            Text(
                              song.artist!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    PlaybackControls(
                      queuePlayer: queuePlayer,
                      playPauseSize: 40,
                      sideButtonSize: 28,
                    ),
                  ],
                ),
              ),
              SeekBar(
                queuePlayer: queuePlayer,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
