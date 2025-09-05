import 'package:shared_preferences/shared_preferences.dart';
import 'setting_types.dart';

/// Менеджер автоматических настроек
class AutoPreferencesManager {
  static AutoPreferencesManager? _instance;
  static SharedPreferences? _prefs;

  /// Реестр всех настроек
  final Map<String, SettingDefinition> _settings = {};

  /// Кеш значений
  final Map<String, dynamic> _cache = {};

  /// Слушатели изменений
  final Map<String, List<void Function(dynamic)>> _listeners = {};

  AutoPreferencesManager._();

  /// Получение единственного экземпляра
  static AutoPreferencesManager get instance {
    _instance ??= AutoPreferencesManager._();
    return _instance!;
  }

  /// Инициализация
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Проверка инициализации
  void _ensureInitialized() {
    if (_prefs == null) {
      throw Exception(
        'AutoPreferencesManager не инициализирован. Вызовите AutoPreferencesManager.init() перед использованием.',
      );
    }
  }

  /// Регистрация настройки
  void registerSetting(SettingDefinition setting) {
    _settings[setting.key] = setting;
  }

  /// Регистрация списка настроек
  void registerSettings(List<SettingDefinition> settings) {
    for (final setting in settings) {
      registerSetting(setting);
    }
  }

  /// Получение настройки по ключу
  SettingDefinition? getSetting(String key) {
    return _settings[key];
  }

  /// Получение всех настроек
  List<SettingDefinition> getAllSettings() {
    return _settings.values.toList();
  }

  /// Получение настроек по категории
  List<SettingDefinition> getSettingsByCategory(String category) {
    return _settings.values
        .where((setting) => setting.category == category)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Получение настроек по подкатегории
  List<SettingDefinition> getSettingsBySubcategory(
    String category,
    String subcategory,
  ) {
    return _settings.values
        .where(
          (setting) =>
              setting.category == category &&
              setting.subcategory == subcategory,
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Получение всех категорий
  List<String> getCategories() {
    final categories = _settings.values
        .where((setting) => setting.category != null)
        .map((setting) => setting.category!)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  /// Получение подкатегорий для категории
  List<String> getSubcategories(String category) {
    final subcategories = _settings.values
        .where(
          (setting) =>
              setting.category == category && setting.subcategory != null,
        )
        .map((setting) => setting.subcategory!)
        .toSet()
        .toList();
    subcategories.sort();
    return subcategories;
  }

  /// Получение значения настройки
  T getValue<T>(String key, {T? defaultValue}) {
    _ensureInitialized();

    final setting = _settings[key];
    if (setting == null) {
      throw ArgumentError('Настройка с ключом "$key" не найдена');
    }

    // Проверяем кеш
    if (_cache.containsKey(key)) {
      return _cache[key] as T;
    }

    // Получаем из SharedPreferences
    dynamic value;
    switch (setting.type) {
      case SettingType.boolean:
        value = _prefs!.getBool(key) ?? setting.defaultValue;
        break;
      case SettingType.string:
      case SettingType.stringChoice:
      case SettingType.filePath:
      case SettingType.directoryPath:
      case SettingType.multilineText:
      case SettingType.password:
      case SettingType.themeMode:
      case SettingType.language:
        value = _prefs!.getString(key) ?? setting.defaultValue;
        break;
      case SettingType.integer:
      case SettingType.integerChoice:
      case SettingType.integerRange:
        value = _prefs!.getInt(key) ?? setting.defaultValue;
        break;
      case SettingType.double:
      case SettingType.doubleRange:
        value = _prefs!.getDouble(key) ?? setting.defaultValue;
        break;
      case SettingType.stringList:
        value = _prefs!.getStringList(key) ?? setting.defaultValue;
        break;
      case SettingType.color:
        final intValue = _prefs!.getInt(key);
        value = intValue ?? setting.defaultValue;
        break;
      case SettingType.date:
      case SettingType.time:
      case SettingType.dateTime:
        final milliseconds = _prefs!.getInt(key);
        value = milliseconds != null
            ? DateTime.fromMillisecondsSinceEpoch(milliseconds)
            : setting.defaultValue;
        break;
      case SettingType.action:
        value = null;
        break;
    }

    _cache[key] = value;
    return value as T;
  }

  /// Установка значения настройки
  Future<void> setValue(String key, dynamic value) async {
    _ensureInitialized();

    final setting = _settings[key];
    if (setting == null) {
      throw ArgumentError('Настройка с ключом "$key" не найдена');
    }

    if (setting.isReadOnly) {
      throw ArgumentError('Настройка "$key" доступна только для чтения');
    }

    // Валидация
    final error = setting.validate(value);
    if (error != null) {
      throw ArgumentError('Ошибка валидации для "$key": $error');
    }

    // Сохранение в SharedPreferences
    switch (setting.type) {
      case SettingType.boolean:
        await _prefs!.setBool(key, value as bool);
        break;
      case SettingType.string:
      case SettingType.stringChoice:
      case SettingType.filePath:
      case SettingType.directoryPath:
      case SettingType.multilineText:
      case SettingType.password:
      case SettingType.themeMode:
      case SettingType.language:
        await _prefs!.setString(key, value as String);
        break;
      case SettingType.integer:
      case SettingType.integerChoice:
      case SettingType.integerRange:
        await _prefs!.setInt(key, value as int);
        break;
      case SettingType.double:
      case SettingType.doubleRange:
        await _prefs!.setDouble(key, value as double);
        break;
      case SettingType.stringList:
        await _prefs!.setStringList(key, value as List<String>);
        break;
      case SettingType.color:
        await _prefs!.setInt(key, value as int);
        break;
      case SettingType.date:
      case SettingType.time:
      case SettingType.dateTime:
        await _prefs!.setInt(key, (value as DateTime).millisecondsSinceEpoch);
        break;
      case SettingType.action:
        // Действия не сохраняются
        break;
    }

    // Обновляем кеш
    _cache[key] = value;

    // Уведомляем слушателей
    _notifyListeners(key, value);

    // Вызываем колбек настройки
    setting.onChanged?.call(value);
  }

  /// Сброс настройки к значению по умолчанию
  Future<void> resetSetting(String key) async {
    final setting = _settings[key];
    if (setting == null) {
      throw ArgumentError('Настройка с ключом "$key" не найдена');
    }

    await setValue(key, setting.defaultValue);
  }

  /// Сброс всех настроек к значениям по умолчанию
  Future<void> resetAllSettings() async {
    for (final setting in _settings.values) {
      if (!setting.isReadOnly) {
        await resetSetting(setting.key);
      }
    }
  }

  /// Сброс настроек категории
  Future<void> resetCategorySettings(String category) async {
    final categorySettings = getSettingsByCategory(category);
    for (final setting in categorySettings) {
      if (!setting.isReadOnly) {
        await resetSetting(setting.key);
      }
    }
  }

  /// Добавить слушатель изменений
  void addListener(String key, void Function(dynamic) listener) {
    _listeners.putIfAbsent(key, () => []).add(listener);
  }

  /// Удалить слушатель изменений
  void removeListener(String key, void Function(dynamic) listener) {
    _listeners[key]?.remove(listener);
    if (_listeners[key]?.isEmpty == true) {
      _listeners.remove(key);
    }
  }

  /// Уведомить слушателей об изменении
  void _notifyListeners(String key, dynamic value) {
    final listeners = _listeners[key];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(value);
        } catch (e) {
          // Игнорируем ошибки в слушателях
        }
      }
    }
  }

  /// Очистить кеш
  void clearCache() {
    _cache.clear();
  }

  /// Проверить зависимости настройки
  bool checkSettingDependencies(String key) {
    final setting = _settings[key];
    if (setting == null) return true;

    for (final dependency in setting.dependencies) {
      final depSetting = _settings[dependency];
      if (depSetting == null) continue;

      // Простая проверка: зависимость должна быть true для boolean настроек
      if (depSetting.type == SettingType.boolean) {
        final depValue = getValue<bool>(dependency);
        if (!depValue) return false;
      }
    }

    return true;
  }

  /// Получить все настройки в виде Map
  Map<String, dynamic> exportSettings() {
    _ensureInitialized();

    final export = <String, dynamic>{};
    for (final setting in _settings.values) {
      try {
        export[setting.key] = getValue(setting.key);
      } catch (e) {
        // Игнорируем ошибки при экспорте
      }
    }
    return export;
  }

  /// Импортировать настройки из Map
  Future<void> importSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      if (_settings.containsKey(entry.key)) {
        try {
          await setValue(entry.key, entry.value);
        } catch (e) {
          // Игнорируем ошибки при импорте
        }
      }
    }
  }

  /// Получить информацию о настройках для отладки
  Map<String, dynamic> getDebugInfo() {
    return {
      'total_settings': _settings.length,
      'categories': getCategories().length,
      'cached_values': _cache.length,
      'listeners': _listeners.length,
      'boolean_settings': _settings.values
          .where((s) => s.type == SettingType.boolean)
          .length,
      'string_settings': _settings.values
          .where((s) => s.type == SettingType.string)
          .length,
      'integer_settings': _settings.values
          .where((s) => s.type == SettingType.integer)
          .length,
      'choice_settings': _settings.values
          .where((s) => s.type == SettingType.stringChoice)
          .length,
      'readonly_settings': _settings.values.where((s) => s.isReadOnly).length,
    };
  }
}
