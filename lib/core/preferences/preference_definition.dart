import 'package:flutter/material.dart';

/// Тип настройки
enum PreferenceType {
  bool,
  int,
  double,
  string,
  stringList,
  themeMode,
  dateTime,
}

/// Определение настройки
class PreferenceDefinition {
  final String key;
  final String title;
  final String? subtitle;
  final String? description;
  final PreferenceType type;
  final IconData? icon;
  final String? category;
  final dynamic defaultValue;
  final List<dynamic>? allowedValues;
  final dynamic Function()? getter;
  final Future<void> Function(dynamic value)? setter;
  final int? minValue;
  final int? maxValue;
  final bool isDeprecated;
  final bool isReadOnly;

  const PreferenceDefinition({
    required this.key,
    required this.title,
    this.subtitle,
    this.description,
    required this.type,
    this.icon,
    this.category,
    this.defaultValue,
    this.allowedValues,
    this.getter,
    this.setter,
    this.minValue,
    this.maxValue,
    this.isDeprecated = false,
    this.isReadOnly = false,
  });

  /// Получить текущее значение настройки
  dynamic getCurrentValue() {
    try {
      return getter?.call() ?? defaultValue;
    } catch (e) {
      // В случае ошибки возвращаем значение по умолчанию
      return defaultValue;
    }
  }

  /// Установить значение настройки
  Future<void> setValue(dynamic value) async {
    if (!isReadOnly && setter != null) {
      try {
        await setter!(value);
      } catch (e) {
        // Логируем ошибку, но не прерываем выполнение
        print('Ошибка при установке значения для $key: $e');
      }
    }
  }

  /// Проверить, является ли значение валидным
  bool isValidValue(dynamic value) {
    if (allowedValues != null) {
      return allowedValues!.contains(value);
    }

    switch (type) {
      case PreferenceType.int:
        if (value is! int) return false;
        if (minValue != null && value < minValue!) return false;
        if (maxValue != null && value > maxValue!) return false;
        return true;
      case PreferenceType.double:
        if (value is! double) return false;
        return true;
      case PreferenceType.string:
        return value is String;
      case PreferenceType.bool:
        return value is bool;
      case PreferenceType.stringList:
        return value is List<String>;
      case PreferenceType.themeMode:
        return value is ThemeMode;
      case PreferenceType.dateTime:
        return value is DateTime?;
    }
  }

  /// Получить отображаемое значение для UI
  String getDisplayValue() {
    try {
      final value = getCurrentValue();
      if (value == null) return 'Не установлено';

      switch (type) {
        case PreferenceType.bool:
          return (value as bool) ? 'Включено' : 'Выключено';
        case PreferenceType.int:
        case PreferenceType.double:
          return value.toString();
        case PreferenceType.string:
          final stringValue = value.toString();
          return stringValue.isEmpty ? 'Не установлено' : stringValue;
        case PreferenceType.stringList:
          final list = value as List<String>;
          return list.isEmpty ? 'Пусто' : '${list.length} элементов';
        case PreferenceType.themeMode:
          final mode = value as ThemeMode;
          switch (mode) {
            case ThemeMode.system:
              return 'Системная';
            case ThemeMode.light:
              return 'Светлая';
            case ThemeMode.dark:
              return 'Темная';
          }
        case PreferenceType.dateTime:
          final date = value as DateTime?;
          if (date == null) return 'Не установлено';
          return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'Ошибка: $e';
    }
  }

  /// Безопасно получить значение как bool
  bool getBoolValue([bool defaultValue = false]) {
    try {
      final value = getCurrentValue();
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Безопасно получить значение как int
  int getIntValue([int defaultValue = 0]) {
    try {
      final value = getCurrentValue();
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Безопасно получить значение как double
  double getDoubleValue([double defaultValue = 0.0]) {
    try {
      final value = getCurrentValue();
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  /// Безопасно получить значение как String
  String getStringValue([String defaultValue = '']) {
    try {
      final value = getCurrentValue();
      if (value == null) return defaultValue;
      return value.toString();
    } catch (e) {
      return defaultValue;
    }
  }

  /// Безопасно получить значение как List<String>
  List<String> getStringListValue([List<String>? defaultValue]) {
    try {
      final value = getCurrentValue();
      if (value is List<String>) return value;
      if (value is List) return value.map((e) => e.toString()).toList();
      return defaultValue ?? [];
    } catch (e) {
      return defaultValue ?? [];
    }
  }
}

/// Категория настроек
class PreferenceCategory {
  final String name;
  final String title;
  final IconData? icon;
  final String? description;
  final List<PreferenceDefinition> preferences;

  const PreferenceCategory({
    required this.name,
    required this.title,
    this.icon,
    this.description,
    required this.preferences,
  });
}
