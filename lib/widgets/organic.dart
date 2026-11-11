import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../theme/organic.dart';
import 'disc.dart';

/// Small building blocks shared by the screens, following the Organic
/// mocks: bottom sheets, sheet rows, tag pills, round buttons.

/// Bottom sheet with the mocks' cream background, 32px top corners and
/// grab handle.
Future<T?> showOrganicSheet<T>({required BuildContext context, required WidgetBuilder builder}) {
  final c = Organic.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.isDark ? c.surface : c.bg,
    barrierColor: Colors.black.withValues(alpha: c.isDark ? 0.6 : 0.4),
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
                      color: c.neutral400,
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

/// Shrinks its child a touch while a finger is down on it, so buttons and
/// tiles feel pressed rather than just tinted.
class PressScale extends StatefulWidget {
  final Widget child;
  final double scale;
  final bool enabled;

  const PressScale({super.key, required this.child, this.scale = 0.94, this.enabled = true});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down && mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down && widget.enabled ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 70 : 180),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
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
    final c = Organic.of(context);
    return Material(
      // Sheets sit on `surface` in dark, so a filled row steps up from it.
      color: filled ? (c.isDark ? c.neutral200 : c.surface) : Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: c.accent100,
        highlightColor: c.accent100,
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
    final c = Organic.of(context);
    return Container(
      height: 34,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(color: c.accent2_600, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: TextStyle(color: c.neutral100, fontWeight: FontWeight.w600, fontSize: 13),
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
                hoverColor: c.accent2_700,
                highlightColor: c.accent2_700,
                child: Tooltip(
                  message: 'Remove tag',
                  child: Icon(Icons.close_rounded, size: 15, color: c.neutral100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Plain rounded pill button (e.g. "+ Add tag"), optionally with a leading
/// icon. Fills with the background colour unless given a [color].
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;
  final double height;
  final TextStyle? style;
  final Color? borderColor;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color,
    this.height = 34,
    this.style,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    final textStyle = style ?? TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: c.text);
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: PressScale(
        enabled: onTap != null,
        scale: 0.96,
        child: Material(
          color: color ?? c.bg,
          shape: StadiumBorder(
            side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            hoverColor: c.accent100,
            highlightColor: c.accent100,
            child: Container(
              height: height,
              padding: EdgeInsets.only(left: icon == null ? 14 : 10, right: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 17, color: textStyle.color),
                    const SizedBox(width: 5),
                  ],
                  Text(label, style: textStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum RoundButtonKind { primary, secondary, ghost }

/// Circular icon button in the mocks' three styles: primary (accent fill),
/// secondary (hairline outline) and ghost (no chrome). [color] recolours the
/// icon, and the outline with it, for buttons that sit on a dark card.
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
    final c = Organic.of(context);
    final ink = color ?? c.text;
    final (bg, fg, side) = switch (kind) {
      RoundButtonKind.primary => (c.accent, c.bg, BorderSide.none),
      RoundButtonKind.secondary => (
        Colors.transparent,
        ink,
        BorderSide(color: color == null ? c.divider : ink.withValues(alpha: 0.24)),
      ),
      RoundButtonKind.ghost => (Colors.transparent, ink, BorderSide.none),
    };
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: PressScale(
        enabled: onPressed != null,
        scale: 0.9,
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
                    ? c.accent600
                    : ink.withValues(alpha: 0.07),
                highlightColor: kind == RoundButtonKind.primary
                    ? c.accent600
                    : ink.withValues(alpha: 0.14),
                child: Icon(icon, size: iconSize, color: fg),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rect outline, for the "+ New tag" placeholder
/// tile. Neutral-400 unless given a [color].
class DashedOutline extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color? color;
  final double strokeWidth;

  const DashedOutline({
    super.key,
    required this.child,
    required this.radius,
    this.color,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(
        radius: radius,
        color: color ?? Organic.of(context).neutral400,
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

/// What a tab shows when it has nothing yet: a still record, an optional
/// heading, a muted line of [text] and an optional [action] button.
class EmptyState extends StatelessWidget {
  final String? title;
  final String text;
  final Widget? action;

  const EmptyState({super.key, this.title, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final c = Organic.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RecordDisc(size: 116),
            const SizedBox(height: 22),
            if (title != null) ...[
              Text(title!, textAlign: TextAlign.center, style: Organic.headingStyle(24)),
              const SizedBox(height: 8),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.neutral700, height: 1.4),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Cream confirmation dialog from the mocks: heading, muted body, Cancel
/// and an accent action. Resolves to true only if the action was tapped.
Future<bool> showOrganicConfirm({
  required BuildContext context,
  required String title,
  required String body,
  required String action,
}) async {
  final c = Organic.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: c.isDark ? 0.65 : 0.45),
    builder: (context) => Dialog(
      backgroundColor: c.isDark ? c.surface : c.bg,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Organic.headingStyle(22)),
            const SizedBox(height: 10),
            Text(body, style: TextStyle(fontSize: 14, color: c.neutral700)),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(action)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}

/// Heading-font section title with an optional muted note on the right,
/// as on the Settings screens.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? note;
  final EdgeInsets padding;

  const SectionHeader(
    this.title, {
    super.key,
    this.note,
    this.padding = const EdgeInsets.symmetric(horizontal: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(title, style: Organic.headingStyle(20))),
          if (note != null)
            Text(note!, style: TextStyle(fontSize: 12, color: Organic.of(context).neutral700)),
        ],
      ),
    );
  }
}
