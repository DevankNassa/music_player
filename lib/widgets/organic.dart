import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/organic.dart';

/// Small building blocks shared by the screens, following the Organic
/// mocks: bottom sheets, sheet rows, tag pills, round buttons.

/// Bottom sheet with the mocks' cream background, 32px top corners and
/// grab handle.
Future<T?> showOrganicSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Organic.bg,
    barrierColor: const Color(0x66201E1D),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => Padding(
      // Keeps an inline text field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Organic.neutral400,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Flexible(child: builder(context)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// A tappable row in an Organic sheet; highlights accent-100 on hover/press.
class SheetRow extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool filled;
  final EdgeInsets padding;

  const SheetRow({
    super.key,
    required this.child,
    required this.onTap,
    this.filled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Organic.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: Organic.accent100,
        highlightColor: Organic.accent100,
        splashColor: Colors.transparent,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Filled green pill for a tag on the current song, with a remove button.
class TagPill extends StatelessWidget {
  final String tag;
  final VoidCallback onRemove;

  const TagPill({super.key, required this.tag, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: Organic.accent2_600,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: const TextStyle(
              color: Organic.neutral100,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 2),
          SizedBox.square(
            dimension: 26,
            child: Material(
              type: MaterialType.circle,
              color: Colors.transparent,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRemove,
                hoverColor: Organic.accent2_700,
                highlightColor: Organic.accent2_700,
                child: Tooltip(
                  message: 'Remove tag',
                  child: const Icon(Icons.close_rounded, size: 15, color: Organic.neutral100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain rounded pill button (e.g. "+ Add tag").
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double height;
  final TextStyle? style;
  final Color? borderColor;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = Organic.bg,
    this.height = 34,
    this.style,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: StadiumBorder(
        side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: Organic.accent100,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style:
                  style ??
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Organic.text),
            ),
          ),
        ),
      ),
    );
  }
}

enum RoundButtonKind { primary, secondary, ghost }

/// Circular icon button in the mocks' three styles: primary (accent fill),
/// secondary (hairline outline) and ghost (no chrome, inherits colour).
/// Disabled buttons fade to 45%, matching `.btn:disabled`.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final RoundButtonKind kind;
  final Color? color;
  final List<BoxShadow>? shadow;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.size,
    required this.iconSize,
    this.kind = RoundButtonKind.secondary,
    this.color,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, side) = switch (kind) {
      RoundButtonKind.primary => (Organic.accent, Organic.bg, BorderSide.none),
      RoundButtonKind.secondary => (
        Colors.transparent,
        Organic.text,
        const BorderSide(color: Organic.divider),
      ),
      RoundButtonKind.ghost => (Colors.transparent, color ?? Organic.text, BorderSide.none),
    };
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: shadow),
        child: Material(
          color: bg,
          shape: CircleBorder(side: side),
          clipBehavior: Clip.antiAlias,
          child: Tooltip(
            message: tooltip,
            child: InkWell(
              onTap: onPressed,
              hoverColor: kind == RoundButtonKind.primary
                  ? Organic.accent600
                  : (color ?? Organic.text).withValues(alpha: 0.07),
              highlightColor: kind == RoundButtonKind.primary
                  ? Organic.accent700
                  : (color ?? Organic.text).withValues(alpha: 0.14),
              splashColor: Colors.transparent,
              child: Icon(icon, size: iconSize, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rect outline, for the "+ New tag" placeholder tile.
class DashedOutline extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color color;
  final double strokeWidth;

  const DashedOutline({
    super.key,
    required this.child,
    required this.radius,
    this.color = Organic.neutral400,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        radius: radius,
        color: color,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  final double radius;
  final Color color;
  final double strokeWidth;

  const _DashedRRectPainter({required this.radius, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, inset, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    const dash = 6.0, gap = 5.0;
    for (final PathMetric metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => old.color != color || old.radius != radius;
}

/// Centred muted message for a tab with nothing to show yet.
class EmptyState extends StatelessWidget {
  final String text;

  const EmptyState({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Organic.neutral700),
        ),
      ),
    );
  }
}
