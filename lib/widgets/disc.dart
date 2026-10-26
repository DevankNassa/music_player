import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/organic.dart';

/// Paints the record disc from the mocks: an optional progress ring
/// (filling clockwise from 12 o'clock), then concentric groove bands, then
/// the centre hole. Also used off-screen to render the notification artwork.
class DiscPainter extends CustomPainter {
  /// 0..1, or null for no ring.
  final double? progress;
  final double ringWidth;
  final Color ringColor;
  final Color ringTrackColor;

  /// Painted outside-in: each band is (outer radius as a fraction of the
  /// disc's radius, colour).
  final List<(double, Color)> bands;
  final double holeFraction;
  final Color holeColor;

  const DiscPainter({
    this.progress,
    this.ringWidth = 0,
    this.ringColor = Organic.accent,
    this.ringTrackColor = Organic.accent200,
    required this.bands,
    required this.holeFraction,
    required this.holeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final fill = Paint()..isAntiAlias = true;

    var discRadius = outer;
    final p = progress;
    if (p != null && ringWidth > 0) {
      canvas.drawCircle(center, outer, fill..color = ringTrackColor);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outer),
        -math.pi / 2,
        2 * math.pi * p.clamp(0.0, 1.0),
        true,
        fill..color = ringColor,
      );
      discRadius = outer - ringWidth;
    }
    for (final (fraction, color) in bands) {
      canvas.drawCircle(center, discRadius * fraction, fill..color = color);
    }
    canvas.drawCircle(center, discRadius * holeFraction, fill..color = holeColor);
  }

  @override
  bool shouldRepaint(DiscPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.ringTrackColor != ringTrackColor ||
      old.holeColor != holeColor;
}

/// Player disc: green grooved record inside an accent progress ring.
class PlayerDisc extends StatelessWidget {
  final double size;
  final double progress;

  const PlayerDisc({super.key, required this.size, required this.progress});

  @override
  Widget build(BuildContext context) {
    // Proportions from mock 4a: 330 outer, 300 disc, 26px grooves, 62 hole.
    return CustomPaint(
      size: Size.square(size),
      painter: DiscPainter(
        progress: progress,
        ringWidth: size * 15 / 330,
        bands: const [
          (1, Organic.accent2_400),
          (124 / 150, Organic.accent2_300),
          (98 / 150, Organic.accent2_400),
          (72 / 150, Organic.accent2_300),
        ],
        holeFraction: 31 / 150,
        holeColor: Organic.bg,
      ),
    );
  }
}

/// Round play/pause button wrapped in a thin progress ring, as on the dark
/// mini-player dock and the Tag tab's now-playing card.
class RingPlayButton extends StatelessWidget {
  final double size;
  final double innerSize;
  final double progress;
  final bool playing;
  final VoidCallback onPressed;

  const RingPlayButton({
    super.key,
    required this.size,
    required this.innerSize,
    required this.progress,
    required this.playing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playing ? 'Pause' : 'Play',
      child: GestureDetector(
        onTap: onPressed,
        child: CustomPaint(
          size: Size.square(size),
          painter: DiscPainter(
            progress: progress,
            ringWidth: (size - innerSize) / 2,
            ringColor: Organic.accent400,
            ringTrackColor: Organic.neutral700,
            bands: const [],
            holeFraction: 1,
            holeColor: Organic.neutral900,
          ),
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: innerSize * 0.45,
              color: Organic.neutral100,
            ),
          ),
        ),
      ),
    );
  }
}
