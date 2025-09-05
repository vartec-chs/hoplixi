import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Singleton класс для управления всеми настройками приложения
/// через SharedPreferences
class AppPreferences {
  static AppPreferences? _instance;
  static SharedPreferences? _prefs;

  // Приватный конструктор для Singleton
  AppPreferences._();

  /// Получение единственного экземпляра класса
  static AppPreferences get instance {
    _instance ??= AppPreferences._();
    return _instance!;
  }

  /// Инициализация SharedPreferences
  /// Должна быть вызвана перед использованием любых методов
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Проверка инициализации
  void _ensureInitialized() {
    if (_prefs == null) {
      throw Exception(
        'AppPreferences не инициализирован. Вызовите AppPreferences.init() перед использованием.',
      );
    }
  }

  // ====== КЛЮЧИ ДЛЯ НАСТРОЕК ======

  // Общие настройки
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyAutoLockTimeout = 'auto_lock_timeout';

  // Настройки безопасности
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyPinEnabled = 'pin_enabled';
  static const String _keyAutoLockEnabled = 'auto_lock_enabled';
  static const String _keyClipboardClearTimeout = 'clipboard_clear_timeout';

  // Настройки хранилища
  static const String _keyDefaultStorePath = 'default_store_path';
  static const String _keyLastUsedStore = 'last_used_store';
  static const String _keyRecentStores = 'recent_stores';

  // Настройки интерфейса
  static const String _keyShowPasswordStrength = 'show_password_strength';
  static const String _keyDarkModeEnabled = 'dark_mode_enabled';
  static const String _keyCompactMode = 'compact_mode';
  static const String _keyShowTags = 'show_tags';

  // Настройки генератора паролей
  static const String _keyPasswordLength = 'password_length';
  static const String _keyIncludeUppercase = 'include_uppercase';
  static const String _keyIncludeLowercase = 'include_lowercase';
  static const String _keyIncludeNumbers = 'include_numbers';
  static const String _keyIncludeSymbols = 'include_symbols';
  static const String _keyExcludeSimilar = 'exclude_similar';

  // Настройки резервного копирования
  static const String _keyAutoBackupEnabled = 'auto_backup_enabled';
  static const String _keyBackupFrequency = 'backup_frequency';
  static const String _keyBackupPath = 'backup_path';
  static const String _keyLastBackupDate = 'last_backup_date';

  // ====== ОБЩИЕ НАСТРОЙКИ ======

  /// Проверяет, является ли это первым запуском приложения
  bool get isFirstLaunch {
    _ensureInitialized();
    return _prefs!.getBool(_keyFirstLaunch) ?? true;
  }

  /// Отмечает, что первый запуск завершен
  Future<void> setFirstLaunchCompleted() async {
    _ensureInitialized();
    await _prefs!.setBool(_keyFirstLaunch, false);
  }

  /// Получает режим темы
  ThemeMode get themeMode {
    _ensureInitialized();
    final mode = _prefs!.getString(_keyThemeMode) ?? 'system';
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Устанавливает режим темы
  Future<void> setThemeMode(ThemeMode mode) async {
    _ensureInitialized();
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    await _prefs!.setString(_keyThemeMode, modeString);
  }

  /// Получает язык приложения
  String get language {
    _ensureInitialized();
    return _prefs!.getString(_keyLanguage) ?? 'system';
  }

  /// Устанавливает язык приложения
  Future<void> setLanguage(String languageCode) async {
    _ensureInitialized();
    await _prefs!.setString(_keyLanguage, languageCode);
  }

  /// Получает таймаут автоблокировки (в минутах)
  int get autoLockTimeout {
    _ensureInitialized();
    return _prefs!.getInt(_keyAutoLockTimeout) ?? 5;
  }

  /// Устанавливает таймаут автоблокировки (в минутах)
  Future<void> setAutoLockTimeout(int minutes) async {
    _ensureInitialized();
    await _prefs!.setInt(_keyAutoLockTimeout, minutes);
  }

  // ====== НАСТРОЙКИ БЕЗОПАСНОСТИ ======

  /// Проверяет, включена ли биометрическая аутентификация
  bool get isBiometricEnabled {
    _ensureInitialized();
    return _prefs!.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Включает/выключает биометрическую аутентификацию
  Future<void> setBiometricEnabled(bool enabled) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyBiometricEnabled, enabled);
  }

  /// Проверяет, включен ли PIN-код
  bool get isPinEnabled {
    _ensureInitialized();
    return _prefs!.getBool(_keyPinEnabled) ?? false;
  }

  /// Включает/выключает PIN-код
  Future<void> setPinEnabled(bool enabled) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyPinEnabled, enabled);
  }

  /// Проверяет, включена ли автоблокировка
  bool get isAutoLockEnabled {
    _ensureInitialized();
    return _prefs!.getBool(_keyAutoLockEnabled) ?? true;
  }

  /// Включает/выключает автоблокировку
  Future<void> setAutoLockEnabled(bool enabled) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyAutoLockEnabled, enabled);
  }

  /// Получает таймаут очистки буфера обмена (в секундах)
  int get clipboardClearTimeout {
    _ensureInitialized();
    return _prefs!.getInt(_keyClipboardClearTimeout) ?? 30;
  }

  /// Устанавливает таймаут очистки буфера обмена (в секундах)
  Future<void> setClipboardClearTimeout(int seconds) async {
    _ensureInitialized();
    await _prefs!.setInt(_keyClipboardClearTimeout, seconds);
  }

  // ====== НАСТРОЙКИ ХРАНИЛИЩА ======

  /// Получает путь к хранилищу по умолчанию
  String? get defaultStorePath {
    _ensureInitialized();
    return _prefs!.getString(_keyDefaultStorePath);
  }

  /// Устанавливает путь к хранилищу по умолчанию
  Future<void> setDefaultStorePath(String? path) async {
    _ensureInitialized();
    if (path != null) {
      await _prefs!.setString(_keyDefaultStorePath, path);
    } else {
      await _prefs!.remove(_keyDefaultStorePath);
    }
  }

  /// Получает путь к последнему использованному хранилищу
  String? get lastUsedStore {
    _ensureInitialized();
    return _prefs!.getString(_keyLastUsedStore);
  }

  /// Устанавливает путь к последнему использованному хранилищу
  Future<void> setLastUsedStore(String? path) async {
    _ensureInitialized();
    if (path != null) {
      await _prefs!.setString(_keyLastUsedStore, path);
    } else {
      await _prefs!.remove(_keyLastUsedStore);
    }
  }

  /// Получает список недавно использованных хранилищ
  List<String> get recentStores {
    _ensureInitialized();
    return _prefs!.getStringList(_keyRecentStores) ?? [];
  }

  /// Добавляет хранилище в список недавно использованных
  Future<void> addRecentStore(String path) async {
    _ensureInitialized();
    final recent = recentStores;
    recent.remove(path); // Удаляем если уже есть
    recent.insert(0, path); // Добавляем в начало

    // Ограничиваем количество недавних хранилищ
    if (recent.length > 10) {
      recent.removeRange(10, recent.length);
    }

    await _prefs!.setStringList(_keyRecentStores, recent);
  }

  /// Удаляет хранилище из списка недавно использованных
  Future<void> removeRecentStore(String path) async {
    _ensureInitialized();
    final recent = recentStores;
    recent.remove(path);
    await _prefs!.setStringList(_keyRecentStores, recent);
  }

  /// Очищает список недавно использованных хранилищ
  Future<void> clearRecentStores() async {
    _ensureInitialized();
    await _prefs!.remove(_keyRecentStores);
  }

  // ====== НАСТРОЙКИ ИНТЕРФЕЙСА ======

  /// Проверяет, показывать ли индикатор силы пароля
  bool get showPasswordStrength {
    _ensureInitialized();
    return _prefs!.getBool(_keyShowPasswordStrength) ?? true;
  }

  /// Включает/выключает показ индикатора силы пароля
  Future<void> setShowPasswordStrength(bool show) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyShowPasswordStrength, show);
  }

  /// Проверяет, включена ли темная тема (deprecated, используйте themeMode)
  @Deprecated('Используйте themeMode вместо этого')
  bool get isDarkModeEnabled {
    _ensureInitialized();
    return _prefs!.getBool(_keyDarkModeEnabled) ?? false;
  }

  /// Включает/выключает темную тему (deprecated, используйте setThemeMode)
  @Deprecated('Используйте setThemeMode вместо этого')
  Future<void> setDarkModeEnabled(bool enabled) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyDarkModeEnabled, enabled);
  }

  /// Проверяет, включен ли компактный режим
  bool get isCompactMode {
    _ensureInitialized();
    return _prefs!.getBool(_keyCompactMode) ?? false;
  }

  /// Включает/выключает компактный режим
  Future<void> setCompactMode(bool enabled) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyCompactMode, enabled);
  }

  /// Проверяет, показывать ли теги
  bool get showTags {
    _ensureInitialized();
    return _prefs!.getBool(_keyShowTags) ?? true;
  }

  /// Включает/выключает показ тегов
  Future<void> setShowTags(bool show) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyShowTags, show);
  }

  // ====== НАСТРОЙКИ ГЕНЕРАТОРА ПАРОЛЕЙ ======

  /// Получает длину генерируемого пароля
  int get passwordLength {
    _ensureInitialized();
    return _prefs!.getInt(_keyPasswordLength) ?? 16;
  }

  /// Устанавливает длину генерируемого пароля
  Future<void> setPasswordLength(int length) async {
    _ensureInitialized();
    await _prefs!.setInt(_keyPasswordLength, length);
  }

  /// Проверяет, включать ли заглавные буквы в пароль
  bool get includeUppercase {
    _ensureInitialized();
    return _prefs!.getBool(_keyIncludeUppercase) ?? true;
  }

  /// Включает/выключает заглавные буквы в пароле
  Future<void> setIncludeUppercase(bool include) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyIncludeUppercase, include);
  }

  /// Проверяет, включать ли строчные буквы в пароль
  bool get includeLowercase {
    _ensureInitialized();
    return _prefs!.getBool(_keyIncludeLowercase) ?? true;
  }

  /// Включает/выключает строчные буквы в пароле
  Future<void> setIncludeLowercase(bool include) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyIncludeLowercase, include);
  }

  /// Проверяет, включать ли цифры в пароль
  bool get includeNumbers {
    _ensureInitialized();
    return _prefs!.getBool(_keyIncludeNumbers) ?? true;
  }

  /// Включает/выключает цифры в пароле
  Future<void> setIncludeNumbers(bool include) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyIncludeNumbers, include);
  }

  /// Проверяет, включать ли символы в пароль
  bool get includeSymbols {
    _ensureInitialized();
    return _prefs!.getBool(_keyIncludeSymbols) ?? false;
  }

  /// Включает/выключает символы в пароле
  Future<void> setIncludeSymbols(bool include) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyIncludeSymbols, include);
  }

  /// Проверяет, исключать ли похожие символы из пароля
  bool get excludeSimilar {
    _ensureInitialized();
    return _prefs!.getBool(_keyExcludeSimilar) ?? true;
  }

  /// Включает/выключает исключение похожих символов из пароля
  Future<void> setExcludeSimilar(bool exclude) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyExcludeSimilar, exclude);
  }

  // ====== НАСТРОЙКИ РЕЗЕРВНОГО КОПИРОВАНИЯ ======

  /// Проверяет, включено ли автоматическое резервное копирование
  bool get isAutoBackupEnabled {
    _ensureInitialized();
    return _prefs!.getBool(_keyAutoBackupEnabled) ?? false;
  }

  /// Включает/выключает автоматическое резервное копирование
  Future<void> setAutoBackupEnabled(bool enabled) async {
    _ensureInitialized();
    await _prefs!.setBool(_keyAutoBackupEnabled, enabled);
  }

  /// Получает частоту резервного копирования (в днях)
  int get backupFrequency {
    _ensureInitialized();
    return _prefs!.getInt(_keyBackupFrequency) ?? 7;
  }

  /// Устанавливает частоту резервного копирования (в днях)
  Future<void> setBackupFrequency(int days) async {
    _ensureInitialized();
    await _prefs!.setInt(_keyBackupFrequency, days);
  }

  /// Получает путь для резервных копий
  String? get backupPath {
    _ensureInitialized();
    return _prefs!.getString(_keyBackupPath);
  }

  /// Устанавливает путь для резервных копий
  Future<void> setBackupPath(String? path) async {
    _ensureInitialized();
    if (path != null) {
      await _prefs!.setString(_keyBackupPath, path);
    } else {
      await _prefs!.remove(_keyBackupPath);
    }
  }

  /// Получает дату последнего резервного копирования
  DateTime? get lastBackupDate {
    _ensureInitialized();
    final timestamp = _prefs!.getInt(_keyLastBackupDate);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Устанавливает дату последнего резервного копирования
  Future<void> setLastBackupDate(DateTime? date) async {
    _ensureInitialized();
    if (date != null) {
      await _prefs!.setInt(_keyLastBackupDate, date.millisecondsSinceEpoch);
    } else {
      await _prefs!.remove(_keyLastBackupDate);
    }
  }

  // ====== ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ ======

  /// Очищает все настройки
  Future<void> clearAll() async {
    _ensureInitialized();
    await _prefs!.clear();
  }

  /// Очищает только пользовательские настройки (сохраняет системные)
  Future<void> clearUserSettings() async {
    _ensureInitialized();
    final keysToKeep = [_keyFirstLaunch, _keyLanguage];

    final allKeys = _prefs!.getKeys();
    for (final key in allKeys) {
      if (!keysToKeep.contains(key)) {
        await _prefs!.remove(key);
      }
    }
  }

  /// Получает все настройки в виде Map для отладки
  Map<String, dynamic> getAllSettings() {
    _ensureInitialized();
    final Map<String, dynamic> settings = {};
    for (final key in _prefs!.getKeys()) {
      settings[key] = _prefs!.get(key);
    }
    return settings;
  }

  /// Проверяет, существует ли настройка с указанным ключом
  bool hasKey(String key) {
    _ensureInitialized();
    return _prefs!.containsKey(key);
  }

  /// Удаляет настройку по ключу
  Future<void> removeKey(String key) async {
    _ensureInitialized();
    await _prefs!.remove(key);
  }
}
