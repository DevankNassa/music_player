import 'package:flutter/material.dart';

import '../state/queue_player.dart';

String formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString();
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// A seek slider with current/total time labels, bound to a [QueuePlayer].
class SeekBar extends StatelessWidget {
  final QueuePlayer queuePlayer;
  final EdgeInsets labelPadding;

  const SeekBar({
    super.key,
    required this.queuePlayer,
    this.labelPadding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    final duration = queuePlayer.duration;
    final position = queuePlayer.position;
    final seekable = duration > Duration.zero;
    final clampedMs =
        position.inMilliseconds.clamp(0, seekable ? duration.inMilliseconds : 0).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: clampedMs,
            max: seekable ? duration.inMilliseconds.toDouble() : 1,
            onChanged: seekable
                ? (value) => queuePlayer.seek(Duration(milliseconds: value.round()))
                : null,
          ),
        ),
        Padding(
          padding: labelPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(position), style: Theme.of(context).textTheme.labelSmall),
              Text(formatDuration(duration), style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}
