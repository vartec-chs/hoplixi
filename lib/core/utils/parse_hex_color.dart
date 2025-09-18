import 'package:flutter/material.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

Color parseHexColor(String? hexColor, Color fallbackColor) {
  if (hexColor == null || hexColor.trim().isEmpty) return fallbackColor;

  try {
    var clean = hexColor.trim().replaceAll('#', '').replaceAll('0x', '');
    logDebug('Парсинг hex цвета', data: {'hex': clean});

    // Если передан RRGGBB — добавляем альфу FF
    if (clean.length == 6) clean = 'FF$clean';

    if (clean.length != 8) {
      logError('Неподдерживаемая длина hex строки', data: {'hex': clean});
      return fallbackColor;
    }

    final value = int.tryParse(clean, radix: 16);
    if (value == null) throw FormatException('Не шестнадцатеричный формат');

    return Color(value);
  } catch (e, s) {
    logError('Не удалось распарсить hex цвет', error: e, stackTrace: s);
    return fallbackColor;
  }
}
