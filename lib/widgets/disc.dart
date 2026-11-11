import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/organic.dart';
import 'organic.dart';

/// Paints the record disc from the mocks: an optional progress ring
/// (filling clockwise from 12 o'clock), then concentric groove bands, then
/// the centre hole. [grooveColor] and [shineColor] add fine groove lines and
/// the two soft highlights of light catching vinyl. Also used off-screen to
/// render the notification artwork.
class DiscPainter extends CustomPainter {
  /// 0..1, or null for no ring.
  final double? progress;
  final double ringWidth;
  final Color? ringColor;
  final Color? ringTrackColor;

  /// Painted outside-in: each band is (outer radius as a fraction of the
  /// disc's radius, colour).
  final List<(double, Color)> bands;
  final double holeFraction;
  final Color holeColor;
  final Color? grooveColor;
  final Color? shineColor;

  const DiscPainter({
    this.progress,
    this.ringWidth = 0,
    this.ringColor,
    this.ringTrackColor,
    required this.bands,
    required this.holeFraction,
    required this.holeColor,
    this.grooveColor,
    this.shineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final fill = Paint()..isAntiAlias = true;

    var discRadius = outer;
    final p = progress;
    if (p != null && ringWidth > 0) {
      canvas.drawCircle(center, outer, fill..color = ringTrackColor!);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outer),
        -math.pi / 2,
        2 * math.pi * p.clamp(0.0, 1.0),
        true,
        fill..color = ringColor!,
      );
      discRadius = outer - ringWidth;
    }
    for (final (fraction, color) in bands) {
      canvas.drawCircle(center, discRadius * fraction, fill..color = color);
    }
    final groove = grooveColor;
    if (groove != null) {
      final line = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, discRadius / 260)
        ..color = groove;
      final step = math.max(3.0, discRadius / 30);
      for (var r = discRadius - step; r > discRadius * holeFraction + step; r -= step) {
        canvas.drawCircle(center, r, line);
      }
    }
    final shine = shineColor;
    if (shine != null) {
      final clear = shine.withValues(alpha: 0);
      canvas.drawCircle(
        center,
        discRadius,
        Paint()
          ..isAntiAlias = true
          ..shader = SweepGradient(
            // Two opposite glints, upper-left and lower-right.
            transform: const GradientRotation(-math.pi * 0.86),
            colors: [clear, shine, clear, clear, shine, clear, clear],
            stops: const [0, 0.07, 0.14, 0.5, 0.57, 0.64, 1],
          ).createShader(Rect.fromCircle(center: center, radius: discRadius)),
      );
    }
    canvas.drawCircle(center, discRadius * holeFraction, fill..color = holeColor);
  }

  @override
  bool shouldRepaint(DiscPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.ringTrackColor != ringTrackColor ||
      old.holeColor != holeColor ||
      old.grooveColor != grooveColor ||
      old.shineColor != shineColor ||
      old.bands.length != bands.length ||
      (bands.isNotEmpty && old.bands.first != bands.first);
}

/// The paper label in the middle of the record. It carries an off-centre
/// mark, which is what makes the record visibly turn.
class _LabelPainter extends CustomPainter {
  final Color color;
  final Color ink;
  final Color hole;

  const _LabelPainter({required this.color, required this.ink, required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final fill = Paint()..isAntiAlias = true;
    canvas.drawCircle(center, r, fill..color = color);
    final line = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, r * 0.07)
      ..color = ink;
    // Two short arcs of "print", one longer than the other.
    canvas.drawArc(Rect.fromCircle(center: center, radius: r * 0.72), -2.5, 1.5, false, line);
    canvas.drawArc(Rect.fromCircle(center: center, radius: r * 0.72), 0.9, 0.7, false, line);
    canvas.drawCircle(center + Offset(r * 0.5, r * 0.1), r * 0.09, fill..color = ink);
    canvas.drawCircle(center, r * 0.2, fill..color = hole);
  }

  @override
  bool shouldRepaint(_LabelPainter old) => old.color != color || old.ink != ink || old.hole != hole;
}

/// A sage record with a clay label, in the current theme's colours. The
/// label turns by [turns] (an animation in whole revolutions) if given.
class RecordDisc extends StatelessWidget {
  final double size;
  final Animation<double>? turns;

  const RecordDisc({super.key, required this.size, this.turns});

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    // Proportions from mock 4a: 300 disc, 26px grooves.
    final label = CustomPaint(
      size: Size.square(size * 0.36),
      painter: _LabelPainter(color: c.accent, ink: c.bg.withValues(alpha: 0.8), hole: c.bg),
    );
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              size: Size.square(size),
              painter: DiscPainter(
                bands: [
                  (1, c.accent2_400),
                  (124 / 150, c.accent2_300),
                  (98 / 150, c.accent2_400),
                  (72 / 150, c.accent2_300),
                ],
                holeFraction: 0,
                holeColor: c.bg,
                grooveColor: c.accent2_800.withValues(alpha: c.isDark ? 0.07 : 0.1),
                shineColor: Colors.white.withValues(alpha: c.isDark ? 0.1 : 0.34),
              ),
            ),
          ),
          if (turns == null) label else RotationTransition(turns: turns!, child: label),
        ],
      ),
    );
  }
}

/// Player disc: the record inside an accent progress ring. It turns while
/// [spinning] and holds its angle when paused.
class PlayerDisc extends StatefulWidget {
  final double size;
  final double progress;
  final bool spinning;

  const PlayerDisc({super.key, required this.size, required this.progress, this.spinning = false});

  @override
  State<PlayerDisc> createState() => _PlayerDiscState();
}

class _PlayerDiscState extends State<PlayerDisc> with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PlayerDisc old) {
    super.didUpdateWidget(old);
    if (old.spinning != widget.spinning) _sync();
  }

  void _sync() {
    final spin = widget.spinning && !MediaQuery.disableAnimationsOf(context);
    if (spin && !_turns.isAnimating) {
      _turns.repeat();
    } else if (!spin && _turns.isAnimating) {
      _turns.stop();
    }
  }

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    final size = widget.size;
    // Proportions from mock 4a: 330 outer, 300 disc.
    final ringWidth = size * 15 / 330;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: DiscPainter(
              progress: widget.progress,
              ringWidth: ringWidth,
              ringColor: c.accent,
              ringTrackColor: c.isDark ? c.accent300 : c.accent200,
              bands: const [],
              holeFraction: 0,
              holeColor: c.bg,
            ),
          ),
          RecordDisc(size: size - 2 * ringWidth, turns: _turns),
        ],
      ),
    );
  }
}

/// A thin progress arc around the edge of its box.
class _RingPainter extends CustomPainter {
  final double progress;
  final double width;
  final Color color;
  final Color track;

  const _RingPainter({
    required this.progress,
    required this.width,
    required this.color,
    required this.track,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - width) / 2,
    );
    final stroke = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;
    canvas.drawArc(rect, 0, 2 * math.pi, false, stroke..color = track);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        stroke..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

/// Round accent play/pause button wrapped in a thin progress ring, as on the
/// mini-player dock and the Tag tab's transport. Made for the dark cards.
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
    final c = Organic.of(context);
    return Semantics(
      button: true,
      label: playing ? 'Pause' : 'Play',
      child: PressScale(
        scale: 0.9,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: CustomPaint(
            painter: _RingPainter(
              progress: progress,
              width: math.max(2.5, (size - innerSize) / 4),
              color: c.cardAccent,
              track: c.onCard.withValues(alpha: 0.16),
            ),
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: Container(
                  width: innerSize,
                  height: innerSize,
                  decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: innerSize * 0.52,
                    color: c.isDark ? c.bg : c.onCard,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
