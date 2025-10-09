import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// Цветовые схемы приложения
abstract final class AppColors {
  /// Светлая цветовая схема
  static const FlexSchemeColor lightColors = FlexSchemeColor(
    primary: Color(0xFF005BFF),
    primaryContainer: Color(0xFF005BFF),
    secondary: Color(0xFFEDEDED),
    secondaryContainer: Color(0xFFEDEDED),
    tertiary: Color(0xFFEDEDED),
    tertiaryContainer: Color(0xFFEDEDED),
    appBarColor: Color(0xFFEDEDED),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),
  );

  /// Тёмная цветовая схема
  static const FlexSchemeColor darkColors = FlexSchemeColor(
    primary: Color(0xFF005BFF),
    primaryContainer: Color(0xFF005BFF),
    primaryLightRef: Color(0xFF005BFF), // The color of light mode primary
    secondary: Color(0xFF333333),
    secondaryContainer: Color(0xFF393939),
    secondaryLightRef: Color(0xFFEDEDED), // The color of light mode secondary
    tertiary: Color(0xFF393939),
    tertiaryContainer: Color(0xFF393939),
    tertiaryLightRef: Color(0xFFEDEDED), // The color of light mode tertiary
    appBarColor: Color(0xFFEDEDED),
    error: Color(0xFFFBA49A),
    errorContainer: Color(0xFFC20A17),
  );

  /// Цвет поверхности для тёмной темы
  static const Color darkSurfaceTint = Color(0xFF005BFF);

  //primary: Color(0xFF005BFF),

  static const Color primary = Color(0xFF005BFF);
}
