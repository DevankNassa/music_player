import 'package:flutter/material.dart';

/// Tokens from the "Organic" design system (claude.ai/design project
/// Insta-Playlist Mocks, `_ds/organic-*/styles.css`). Screens use these
/// directly rather than going through ColorScheme roles, since the mocks
/// pick specific ramp steps (e.g. accent-700 for the active tab label).
abstract final class Organic {
  static const bg = Color(0xFFF5EAD8);
  static const surface = Color(0xFFEBDDC5);
  static const text = Color(0xFF201E1D);
  static const accent = Color(0xFFC67139);
  static const accent2 = Color(0xFF7A8A5E);
  static const divider = Color(0x29201E1D); // text @ 16%

  static const neutral100 = Color(0xFFF9F4ED);
  static const neutral200 = Color(0xFFEEE7DB);
  static const neutral300 = Color(0xFFDCD3C4);
  static const neutral400 = Color(0xFFC0B6A5);
  static const neutral500 = Color(0xFFA19786);
  static const neutral600 = Color(0xFF82796A);
  static const neutral700 = Color(0xFF645C50);
  static const neutral800 = Color(0xFF474238);
  static const neutral900 = Color(0xFF2E2B25);

  static const accent100 = Color(0xFFFFF2EB);
  static const accent200 = Color(0xFFFFE1D0);
  static const accent300 = Color(0xFFFFC6A5);
  static const accent400 = Color(0xFFF6A06B);
  static const accent500 = Color(0xFFD67F48);
  static const accent600 = Color(0xFFB2622D);
  static const accent700 = Color(0xFF8C491A);
  static const accent800 = Color(0xFF643312);

  static const accent2_200 = Color(0xFFE1EECC);
  static const accent2_300 = Color(0xFFCCDBB2);
  static const accent2_400 = Color(0xFFAEBF92);
  static const accent2_600 = Color(0xFF728157);
  static const accent2_700 = Color(0xFF56633F);
  static const accent2_800 = Color(0xFF3D472B);

  static const heading = 'Caprasimo';
  static const body = 'Figtree';

  static const shadowSm = [
    BoxShadow(color: Color(0x242E2B25), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x292E2B25), offset: Offset(0, 3), blurRadius: 10),
  ];
  static const shadowLg = [
    BoxShadow(color: Color(0x382E2B25), offset: Offset(0, 12), blurRadius: 32),
  ];

  /// Caprasimo only ships one weight; size and colour carry the hierarchy.
  static TextStyle headingStyle(double size, {Color? color, double? height}) => TextStyle(
    fontFamily: heading,
    fontSize: size,
    height: height ?? 1.12,
    letterSpacing: -0.015 * size,
    color: color ?? text,
  );
}

ThemeData organicTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Organic.accent, brightness: Brightness.light)
      .copyWith(
        primary: Organic.accent,
        onPrimary: Organic.bg,
        secondary: Organic.accent2,
        surface: Organic.bg,
        onSurface: Organic.text,
        onSurfaceVariant: Organic.neutral700,
        outline: Organic.divider,
        outlineVariant: Organic.divider,
      );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: Organic.body);
  return base.copyWith(
    scaffoldBackgroundColor: Organic.bg,
    textTheme: base.textTheme.apply(bodyColor: Organic.text, displayColor: Organic.text),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Organic.neutral900,
      contentTextStyle: TextStyle(fontFamily: Organic.body, color: Organic.neutral100),
      shape: StadiumBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Organic.accent,
        foregroundColor: Organic.bg,
        textStyle: const TextStyle(fontFamily: Organic.heading, fontSize: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        shape: const StadiumBorder(),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Organic.accent),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Organic.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Organic.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Organic.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: Organic.accent),
      ),
    ),
  );
}
