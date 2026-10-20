import 'package:flutter/material.dart';

import '../state/queue_player.dart';

/// Prev / play-pause / next row bound to a [QueuePlayer].
class PlaybackControls extends StatelessWidget {
  final QueuePlayer queuePlayer;
  final double playPauseSize;
  final double sideButtonSize;

  const PlaybackControls({
    super.key,
    required this.queuePlayer,
    this.playPauseSize = 56,
    this.sideButtonSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: sideButtonSize,
          onPressed: queuePlayer.hasPrevious ? queuePlayer.previous : null,
          icon: const Icon(Icons.skip_previous),
        ),
        IconButton(
          iconSize: playPauseSize,
          onPressed: queuePlayer.togglePlayPause,
          icon: Icon(
            queuePlayer.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
          ),
        ),
        IconButton(
          iconSize: sideButtonSize,
          onPressed: queuePlayer.hasNext ? queuePlayer.next : null,
          icon: const Icon(Icons.skip_next),
        ),
      ],
    );
  }
}
