import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single source of truth for app-wide typography.
///
/// To change the font for the entire app, update [_textTheme] and [_style] only.
abstract final class AppTypography {
  AppTypography._();

  /// Brand ink — primary text and cursor.
  static const Color brandInk = Color(0xFF111111);

  /// Brand gold — accents, selection handles, chips.
  static const Color brandGold = Color(0xFFC3B649);

  static TextTheme textTheme([TextTheme? base]) => _textTheme(base);

  static TextStyle style({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) =>
      _style(
        textStyle: textStyle,
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      );

  static ThemeData applyTo(ThemeData theme) {
    final themedText = textTheme(theme.textTheme);
    return theme.copyWith(
      textTheme: themedText,
      primaryTextTheme: themedText,
      colorScheme: theme.colorScheme.copyWith(
        primary: brandInk,
        secondary: brandGold,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: brandInk,
        selectionColor: brandGold.withValues(alpha: 0.35),
        selectionHandleColor: brandGold,
      ),
    );
  }

  static final TextTheme Function([TextTheme?]) _textTheme =
      GoogleFonts.poppinsTextTheme;

  static final TextStyle Function({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
  }) _style = GoogleFonts.poppins;
}
