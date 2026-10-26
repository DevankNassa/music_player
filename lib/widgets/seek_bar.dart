import 'package:flutter/material.dart';

import '../state/queue_player.dart';
import '../theme/organic.dart';

String formatDuration(Duration d) {
  final minutes = d.inMinutes.toString();
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

/// The Player's seek bar: a thick rounded track with a ringed thumb, elapsed
/// time on the left and time remaining on the right. Tap anywhere on the
/// track to jump there, or drag the thumb.
///
/// [dark] is the slimmer variant for dark cards (the Tag tab's now-playing
/// card), styled after the media notification mock: light fill on a brown
/// track, and total length on the right instead of time remaining.
class SeekBar extends StatefulWidget {
  final QueuePlayer queuePlayer;
  final bool dark;

  const SeekBar({super.key, required this.queuePlayer, this.dark = false});

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  /// While dragging, the thumb follows the finger; the seek is sent on
  /// release so position ticks don't fight the drag.
  double? _dragFraction;

  bool get _seekable => widget.queuePlayer.duration > Duration.zero;

  double _fractionAt(Offset local, double width) => (local.dx / width).clamp(0.0, 1.0);

  void _seekTo(double fraction) {
    final duration = widget.queuePlayer.duration;
    widget.queuePlayer.seek(duration * fraction);
  }

  @override
  Widget build(BuildContext context) {
    final queuePlayer = widget.queuePlayer;
    final duration = queuePlayer.duration;
    final fraction = _dragFraction ?? queuePlayer.progress;
    final position = _dragFraction == null ? queuePlayer.position : duration * fraction;
    final remaining = duration - position;
    final dark = widget.dark;
    final trackHeight = dark ? 6.0 : 8.0;
    final thumbSize = dark ? 14.0 : 20.0;
    final fillColor = dark ? Organic.accent200 : Organic.accent;
    final labelStyle = dark
        ? TextStyle(fontSize: 11, color: Organic.neutral100.withValues(alpha: 0.75))
        : const TextStyle(fontSize: 12, color: Organic.neutral700);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Semantics(
              slider: true,
              label: 'Seek',
              value: formatDuration(position),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _seekable ? (d) => _seekTo(_fractionAt(d.localPosition, width)) : null,
                onHorizontalDragStart: _seekable
                    ? (d) => setState(() => _dragFraction = _fractionAt(d.localPosition, width))
                    : null,
                onHorizontalDragUpdate: _seekable
                    ? (d) => setState(() => _dragFraction = _fractionAt(d.localPosition, width))
                    : null,
                onHorizontalDragEnd: _seekable
                    ? (_) {
                        _seekTo(_dragFraction ?? fraction);
                        setState(() => _dragFraction = null);
                      }
                    : null,
                onHorizontalDragCancel: () => setState(() => _dragFraction = null),
                child: SizedBox(
                  height: dark ? 18 : 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: trackHeight,
                        decoration: BoxDecoration(
                          color: dark ? Organic.accent600 : Organic.neutral300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Container(
                        height: trackHeight,
                        width: width * fraction,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      Positioned(
                        left: width * fraction - thumbSize / 2,
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            color: dark ? Organic.neutral100 : Organic.accent,
                            shape: BoxShape.circle,
                            boxShadow: dark
                                ? null
                                : const [
                                    BoxShadow(color: Organic.bg, spreadRadius: 4),
                                    ...Organic.shadowSm,
                                  ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: dark ? 0 : 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatDuration(position), style: labelStyle),
            Text(
              dark
                  ? formatDuration(duration)
                  : '-${formatDuration(remaining.isNegative ? Duration.zero : remaining)}',
              style: labelStyle,
            ),
          ],
        ),
      ],
    );
  }
}
