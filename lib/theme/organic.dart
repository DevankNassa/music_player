import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The "Organic" design system (claude.ai/design project Insta-Playlist
/// Mocks, `_ds/organic-*/styles.css`): type, plus access to the colours of
/// whichever palette is showing.
abstract final class Organic {
  static const heading = 'Caprasimo';
  static const body = 'Figtree';

  /// The palette for the theme [context] is in. Screens read ramp steps from
  /// here rather than from ColorScheme roles, since the mocks pick specific
  /// steps (e.g. accent-700 for the active tab label).
  static OrganicColors of(BuildContext context) => Theme.of(context).extension<OrganicColors>()!;

  /// Caprasimo only ships one weight; size and colour carry the hierarchy.
  /// Without a [color] the text takes the theme's text colour.
  static TextStyle headingStyle(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: heading,
    fontSize: size,
    height: height ?? 1.12,
    letterSpacing: -0.015 * size,
    color: color,
  );

  /// Small tracked-out caps label, e.g. "NOW PLAYING · 3 OF 40".
  static TextStyle eyebrowStyle(Color color) =>
      TextStyle(fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w600, color: color);
}

/// One Organic palette. [light] is the mocks' own; [dark] is the same clay
/// and sage on roasted-coffee browns.
///
/// The ramps keep their meaning across palettes rather than their lightness:
/// step 100 is always the quietest tint against the background and 800 the
/// strongest, so `accent100` is a pale peach in light and a deep rust in
/// dark. Likewise `neutral100` is always the colour for text on a filled
/// shape (an accent button, an applied tag).
@immutable
class OrganicColors extends ThemeExtension<OrganicColors> {
  final Brightness brightness;

  final Color bg;
  final Color surface;
  final Color text;
  final Color accent;
  final Color accent2;
  final Color divider;

  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;

  final Color accent100;
  final Color accent200;
  final Color accent300;
  final Color accent400;
  final Color accent500;
  final Color accent600;
  final Color accent700;
  final Color accent800;

  final Color accent2_100;
  final Color accent2_200;
  final Color accent2_300;
  final Color accent2_400;
  final Color accent2_600;
  final Color accent2_700;
  final Color accent2_800;

  /// The dark "now playing" cards (mini-player dock, Tag tab transport):
  /// a top-to-bottom gradient from [card] to [cardEnd], hairline [cardEdge],
  /// with [onCard] text and [cardAccent] for progress.
  final Color card;
  final Color cardEnd;
  final Color cardEdge;
  final Color onCard;
  final Color cardAccent;

  final Color shadow;

  const OrganicColors({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.accent2,
    required this.divider,
    required this.neutral100,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
    required this.accent100,
    required this.accent200,
    required this.accent300,
    required this.accent400,
    required this.accent500,
    required this.accent600,
    required this.accent700,
    required this.accent800,
    required this.accent2_100,
    required this.accent2_200,
    required this.accent2_300,
    required this.accent2_400,
    required this.accent2_600,
    required this.accent2_700,
    required this.accent2_800,
    required this.card,
    required this.cardEnd,
    required this.cardEdge,
    required this.onCard,
    required this.cardAccent,
    required this.shadow,
  });

  static const light = OrganicColors(
    brightness: Brightness.light,
    bg: Color(0xFFF5EAD8),
    surface: Color(0xFFEBDDC5),
    text: Color(0xFF201E1D),
    accent: Color(0xFFC67139),
    accent2: Color(0xFF7A8A5E),
    divider: Color(0x29201E1D), // text @ 16%
    neutral100: Color(0xFFF9F4ED),
    neutral200: Color(0xFFEEE7DB),
    neutral300: Color(0xFFDCD3C4),
    neutral400: Color(0xFFC0B6A5),
    neutral500: Color(0xFFA19786),
    neutral600: Color(0xFF82796A),
    neutral700: Color(0xFF645C50),
    neutral800: Color(0xFF474238),
    neutral900: Color(0xFF2E2B25),
    accent100: Color(0xFFFFF2EB),
    accent200: Color(0xFFFFE1D0),
    accent300: Color(0xFFFFC6A5),
    accent400: Color(0xFFF6A06B),
    accent500: Color(0xFFD67F48),
    accent600: Color(0xFFB2622D),
    accent700: Color(0xFF8C491A),
    accent800: Color(0xFF643312),
    accent2_100: Color(0xFFF0FAE1),
    accent2_200: Color(0xFFE1EECC),
    accent2_300: Color(0xFFCCDBB2),
    accent2_400: Color(0xFFAEBF92),
    accent2_600: Color(0xFF728157),
    accent2_700: Color(0xFF56633F),
    accent2_800: Color(0xFF3D472B),
    card: Color(0xFF3A342C),
    cardEnd: Color(0xFF262320),
    cardEdge: Color(0x00000000),
    onCard: Color(0xFFF9F4ED),
    cardAccent: Color(0xFFF6A06B),
    shadow: Color(0xFF2E2B25),
  );

  static const dark = OrganicColors(
    brightness: Brightness.dark,
    bg: Color(0xFF17130F),
    surface: Color(0xFF231D17),
    text: Color(0xFFF3E9DA),
    accent: Color(0xFFDD8750),
    accent2: Color(0xFF9DB07C),
    divider: Color(0x24F3E9DA), // text @ 14%
    neutral100: Color(0xFF15110D),
    neutral200: Color(0xFF2B241D),
    neutral300: Color(0xFF3B3229),
    neutral400: Color(0xFF574C40),
    neutral500: Color(0xFF8A7F70),
    neutral600: Color(0xFF9C9181),
    neutral700: Color(0xFFB8AD9C),
    neutral800: Color(0xFFD5CBBB),
    neutral900: Color(0xFFEDE4D6),
    accent100: Color(0xFF33221A),
    accent200: Color(0xFF472B1B),
    accent300: Color(0xFF6B3D22),
    accent400: Color(0xFFA85F30),
    accent500: Color(0xFFDD8750),
    accent600: Color(0xFFE89962),
    accent700: Color(0xFFF6A977),
    accent800: Color(0xFFFFD2B5),
    accent2_100: Color(0xFF232B19),
    accent2_200: Color(0xFF2F3A21),
    accent2_300: Color(0xFF475535),
    accent2_400: Color(0xFF56663F),
    accent2_600: Color(0xFF9DB07C),
    accent2_700: Color(0xFFB4C596),
    accent2_800: Color(0xFFD5E4BB),
    card: Color(0xFF3D2B1E),
    cardEnd: Color(0xFF281D15),
    cardEdge: Color(0x1FF3E9DA),
    onCard: Color(0xFFF9F4ED),
    cardAccent: Color(0xFFF6A06B),
    shadow: Color(0xFF000000),
  );

  bool get isDark => brightness == Brightness.dark;

  /// Shadows need to be much heavier to read at all on the dark background.
  List<BoxShadow> _shadow(double alpha, double dy, double blur) => [
    BoxShadow(
      color: shadow.withValues(alpha: isDark ? alpha * 2.4 : alpha),
      offset: Offset(0, dy),
      blurRadius: blur,
    ),
  ];

  List<BoxShadow> get shadowSm => _shadow(0.14, 1, 2);
  List<BoxShadow> get shadowMd => _shadow(0.16, 3, 10);
  List<BoxShadow> get shadowLg => _shadow(0.22, 12, 32);

  /// Fill for the dark "now playing" cards.
  BoxDecoration cardDecoration({double radius = 30, List<BoxShadow>? boxShadow}) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [card, cardEnd],
    ),
    border: Border.all(color: cardEdge),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: boxShadow,
  );

  @override
  OrganicColors copyWith() => this;

  /// Every colour cross-fades, so switching theme is a dissolve, not a cut.
  @override
  OrganicColors lerp(OrganicColors? other, double t) {
    if (other == null) return this;
    Color l(Color Function(OrganicColors c) pick) => Color.lerp(pick(this), pick(other), t)!;
    return OrganicColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: l((c) => c.bg),
      surface: l((c) => c.surface),
      text: l((c) => c.text),
      accent: l((c) => c.accent),
      accent2: l((c) => c.accent2),
      divider: l((c) => c.divider),
      neutral100: l((c) => c.neutral100),
      neutral200: l((c) => c.neutral200),
      neutral300: l((c) => c.neutral300),
      neutral400: l((c) => c.neutral400),
      neutral500: l((c) => c.neutral500),
      neutral600: l((c) => c.neutral600),
      neutral700: l((c) => c.neutral700),
      neutral800: l((c) => c.neutral800),
      neutral900: l((c) => c.neutral900),
      accent100: l((c) => c.accent100),
      accent200: l((c) => c.accent200),
      accent300: l((c) => c.accent300),
      accent400: l((c) => c.accent400),
      accent500: l((c) => c.accent500),
      accent600: l((c) => c.accent600),
      accent700: l((c) => c.accent700),
      accent800: l((c) => c.accent800),
      accent2_100: l((c) => c.accent2_100),
      accent2_200: l((c) => c.accent2_200),
      accent2_300: l((c) => c.accent2_300),
      accent2_400: l((c) => c.accent2_400),
      accent2_600: l((c) => c.accent2_600),
      accent2_700: l((c) => c.accent2_700),
      accent2_800: l((c) => c.accent2_800),
      card: l((c) => c.card),
      cardEnd: l((c) => c.cardEnd),
      cardEdge: l((c) => c.cardEdge),
      onCard: l((c) => c.onCard),
      cardAccent: l((c) => c.cardAccent),
      shadow: l((c) => c.shadow),
    );
  }
}

/// Status and navigation bar icons that read against [c]'s background.
SystemUiOverlayStyle organicOverlayStyle(OrganicColors c) =>
    (c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: c.bg,
      systemNavigationBarIconBrightness: c.isDark ? Brightness.light : Brightness.dark,
    );

ThemeData organicTheme([Brightness brightness = Brightness.light]) {
  final c = brightness == Brightness.dark ? OrganicColors.dark : OrganicColors.light;
  final scheme = ColorScheme.fromSeed(seedColor: c.accent, brightness: brightness).copyWith(
    primary: c.accent,
    onPrimary: c.bg,
    secondary: c.accent2,
    surface: c.bg,
    onSurface: c.text,
    onSurfaceVariant: c.neutral700,
    outline: c.divider,
    outlineVariant: c.divider,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: Organic.body);
  OutlineInputBorder pill(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(999),
    borderSide: BorderSide(color: color),
  );
  return base.copyWith(
    extensions: [c],
    scaffoldBackgroundColor: c.bg,
    splashFactory: NoSplash.splashFactory,
    textTheme: base.textTheme.apply(bodyColor: c.text, displayColor: c.text),
    iconTheme: IconThemeData(color: c.text),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.neutral900,
      contentTextStyle: TextStyle(fontFamily: Organic.body, color: c.neutral100),
      shape: const StadiumBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.bg,
        disabledBackgroundColor: c.neutral300,
        disabledForegroundColor: c.neutral600,
        textStyle: const TextStyle(fontFamily: Organic.heading, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent700,
        textStyle: const TextStyle(fontFamily: Organic.body, fontWeight: FontWeight.w600),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent300,
      selectionHandleColor: c.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      hintStyle: TextStyle(color: c.neutral600),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: pill(c.divider),
      enabledBorder: pill(c.divider),
      focusedBorder: pill(c.accent),
    ),
  );
}
