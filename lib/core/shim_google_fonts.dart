import 'package:flutter/material.dart';

class GoogleFonts {
  static TextStyle outfit({
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
  }) {
    return TextStyle(
      fontFamily: '-apple-system',
      fontFamilyFallback: const [
        'Noto Sans SC',
        'PingFang SC',
        'Heiti SC',
        'Microsoft YaHei',
        'sans-serif',
      ],
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
    ).merge(textStyle);
  }

  static TextStyle ibmPlexMono({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    return TextStyle(
      fontFamily: 'monospace',
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    ).merge(textStyle);
  }

  static TextTheme outfitTextTheme([TextTheme? textTheme]) {
    textTheme ??= ThemeData.light().textTheme;
    return textTheme.apply(
      fontFamily: '-apple-system',
      fontFamilyFallback: const [
        'PingFang SC',
        'Heiti SC',
        'Microsoft YaHei',
        'sans-serif',
      ],
    );
  }
}
