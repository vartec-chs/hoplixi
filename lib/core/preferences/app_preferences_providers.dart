import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'app_preferences.dart';

/// Провайдер для AppPreferences
final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences.instance;
});

/// Провайдер для режима темы
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(ref.read(appPreferencesProvider));
});

/// Нотификатор для режима темы
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final AppPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_prefs.themeMode);

  /// Изменить режим темы
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setThemeMode(mode);
    state = mode;
  }
}

/// Провайдер для настроек безопасности
final securitySettingsProvider =
    StateNotifierProvider<SecuritySettingsNotifier, SecuritySettings>((ref) {
      return SecuritySettingsNotifier(ref.read(appPreferencesProvider));
    });

/// Модель настроек безопасности
class SecuritySettings {
  final bool isBiometricEnabled;
  final bool isPinEnabled;
  final bool isAutoLockEnabled;
  final int autoLockTimeout;
  final int clipboardClearTimeout;

  const SecuritySettings({
    required this.isBiometricEnabled,
    required this.isPinEnabled,
    required this.isAutoLockEnabled,
    required this.autoLockTimeout,
    required this.clipboardClearTimeout,
  });

  SecuritySettings copyWith({
    bool? isBiometricEnabled,
    bool? isPinEnabled,
    bool? isAutoLockEnabled,
    int? autoLockTimeout,
    int? clipboardClearTimeout,
  }) {
    return SecuritySettings(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      isAutoLockEnabled: isAutoLockEnabled ?? this.isAutoLockEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      clipboardClearTimeout:
          clipboardClearTimeout ?? this.clipboardClearTimeout,
    );
  }
}

/// Нотификатор для настроек безопасности
class SecuritySettingsNotifier extends StateNotifier<SecuritySettings> {
  final AppPreferences _prefs;

  SecuritySettingsNotifier(this._prefs) : super(_loadSettings(_prefs));

  static SecuritySettings _loadSettings(AppPreferences prefs) {
    return SecuritySettings(
      isBiometricEnabled: prefs.isBiometricEnabled,
      isPinEnabled: prefs.isPinEnabled,
      isAutoLockEnabled: prefs.isAutoLockEnabled,
      autoLockTimeout: prefs.autoLockTimeout,
      clipboardClearTimeout: prefs.clipboardClearTimeout,
    );
  }

  /// Изменить настройку биометрии
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBiometricEnabled(enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  /// Изменить настройку PIN-кода
  Future<void> setPinEnabled(bool enabled) async {
    await _prefs.setPinEnabled(enabled);
    state = state.copyWith(isPinEnabled: enabled);
  }

  /// Изменить настройку автоблокировки
  Future<void> setAutoLockEnabled(bool enabled) async {
    await _prefs.setAutoLockEnabled(enabled);
    state = state.copyWith(isAutoLockEnabled: enabled);
  }

  /// Изменить таймаут автоблокировки
  Future<void> setAutoLockTimeout(int timeout) async {
    await _prefs.setAutoLockTimeout(timeout);
    state = state.copyWith(autoLockTimeout: timeout);
  }

  /// Изменить таймаут очистки буфера
  Future<void> setClipboardClearTimeout(int timeout) async {
    await _prefs.setClipboardClearTimeout(timeout);
    state = state.copyWith(clipboardClearTimeout: timeout);
  }
}

/// Провайдер для настроек генератора паролей
final passwordGeneratorSettingsProvider =
    StateNotifierProvider<
      PasswordGeneratorSettingsNotifier,
      PasswordGeneratorSettings
    >((ref) {
      return PasswordGeneratorSettingsNotifier(
        ref.read(appPreferencesProvider),
      );
    });

/// Модель настроек генератора паролей
class PasswordGeneratorSettings {
  final int passwordLength;
  final bool includeUppercase;
  final bool includeLowercase;
  final bool includeNumbers;
  final bool includeSymbols;
  final bool excludeSimilar;

  const PasswordGeneratorSettings({
    required this.passwordLength,
    required this.includeUppercase,
    required this.includeLowercase,
    required this.includeNumbers,
    required this.includeSymbols,
    required this.excludeSimilar,
  });

  PasswordGeneratorSettings copyWith({
    int? passwordLength,
    bool? includeUppercase,
    bool? includeLowercase,
    bool? includeNumbers,
    bool? includeSymbols,
    bool? excludeSimilar,
  }) {
    return PasswordGeneratorSettings(
      passwordLength: passwordLength ?? this.passwordLength,
      includeUppercase: includeUppercase ?? this.includeUppercase,
      includeLowercase: includeLowercase ?? this.includeLowercase,
      includeNumbers: includeNumbers ?? this.includeNumbers,
      includeSymbols: includeSymbols ?? this.includeSymbols,
      excludeSimilar: excludeSimilar ?? this.excludeSimilar,
    );
  }
}

/// Нотификатор для настроек генератора паролей
class PasswordGeneratorSettingsNotifier
    extends StateNotifier<PasswordGeneratorSettings> {
  final AppPreferences _prefs;

  PasswordGeneratorSettingsNotifier(this._prefs) : super(_loadSettings(_prefs));

  static PasswordGeneratorSettings _loadSettings(AppPreferences prefs) {
    return PasswordGeneratorSettings(
      passwordLength: prefs.passwordLength,
      includeUppercase: prefs.includeUppercase,
      includeLowercase: prefs.includeLowercase,
      includeNumbers: prefs.includeNumbers,
      includeSymbols: prefs.includeSymbols,
      excludeSimilar: prefs.excludeSimilar,
    );
  }

  /// Изменить длину пароля
  Future<void> setPasswordLength(int length) async {
    await _prefs.setPasswordLength(length);
    state = state.copyWith(passwordLength: length);
  }

  /// Изменить использование заглавных букв
  Future<void> setIncludeUppercase(bool include) async {
    await _prefs.setIncludeUppercase(include);
    state = state.copyWith(includeUppercase: include);
  }

  /// Изменить использование строчных букв
  Future<void> setIncludeLowercase(bool include) async {
    await _prefs.setIncludeLowercase(include);
    state = state.copyWith(includeLowercase: include);
  }

  /// Изменить использование цифр
  Future<void> setIncludeNumbers(bool include) async {
    await _prefs.setIncludeNumbers(include);
    state = state.copyWith(includeNumbers: include);
  }

  /// Изменить использование символов
  Future<void> setIncludeSymbols(bool include) async {
    await _prefs.setIncludeSymbols(include);
    state = state.copyWith(includeSymbols: include);
  }

  /// Изменить исключение похожих символов
  Future<void> setExcludeSimilar(bool exclude) async {
    await _prefs.setExcludeSimilar(exclude);
    state = state.copyWith(excludeSimilar: exclude);
  }
}

/// Провайдер для списка недавних хранилищ
final recentStoresProvider =
    StateNotifierProvider<RecentStoresNotifier, List<String>>((ref) {
      return RecentStoresNotifier(ref.read(appPreferencesProvider));
    });

/// Нотификатор для списка недавних хранилищ
class RecentStoresNotifier extends StateNotifier<List<String>> {
  final AppPreferences _prefs;

  RecentStoresNotifier(this._prefs) : super(_prefs.recentStores);

  /// Добавить хранилище в недавние
  Future<void> addRecentStore(String path) async {
    await _prefs.addRecentStore(path);
    state = _prefs.recentStores;
  }

  /// Удалить хранилище из недавних
  Future<void> removeRecentStore(String path) async {
    await _prefs.removeRecentStore(path);
    state = _prefs.recentStores;
  }

  /// Очистить список недавних хранилищ
  Future<void> clearRecentStores() async {
    await _prefs.clearRecentStores();
    state = [];
  }
}
