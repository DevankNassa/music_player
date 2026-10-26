import 'package:flutter/material.dart';

import '../state/queue_player.dart';
import '../theme/organic.dart';
import 'organic.dart';

/// The Player's centred transport: outlined prev / big accent play-pause /
/// outlined next, bound to a [QueuePlayer].
class PlaybackControls extends StatelessWidget {
  final QueuePlayer queuePlayer;

  const PlaybackControls({super.key, required this.queuePlayer});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIconButton(
          icon: Icons.skip_previous_rounded,
          tooltip: 'Previous',
          size: 54,
          iconSize: 26,
          onPressed: queuePlayer.hasPrevious ? queuePlayer.previous : null,
        ),
        const SizedBox(width: 22),
        RoundIconButton(
          icon: queuePlayer.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          tooltip: queuePlayer.isPlaying ? 'Pause' : 'Play',
          kind: RoundButtonKind.primary,
          size: 78,
          iconSize: 36,
          shadow: Organic.shadowMd,
          onPressed: queuePlayer.togglePlayPause,
        ),
        const SizedBox(width: 22),
        RoundIconButton(
          icon: Icons.skip_next_rounded,
          tooltip: 'Next',
          size: 54,
          iconSize: 26,
          onPressed: queuePlayer.hasNext ? queuePlayer.next : null,
        ),
      ],
    );
  }
}
