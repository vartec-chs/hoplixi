import 'package:flutter/material.dart';
import 'app_preferences.dart';
import 'preference_definition.dart';

/// Реестр всех настроек приложения
class PreferencesRegistry {
  static final AppPreferences _prefs = AppPreferences.instance;

  /// Получить все категории настроек
  static List<PreferenceCategory> getAllCategories() {
    return [
      _getGeneralCategory(),
      _getSecurityCategory(),
      _getStorageCategory(),
      _getInterfaceCategory(),
      _getPasswordGeneratorCategory(),
      _getBackupCategory(),
      _getDebugCategory(),
    ];
  }

  /// Получить все настройки в виде плоского списка
  static List<PreferenceDefinition> getAllPreferences() {
    return getAllCategories()
        .expand((category) => category.preferences)
        .toList();
  }

  /// Найти настройку по ключу
  static PreferenceDefinition? findPreferenceByKey(String key) {
    return getAllPreferences().cast<PreferenceDefinition?>().firstWhere(
      (pref) => pref?.key == key,
      orElse: () => null,
    );
  }

  /// Общие настройки
  static PreferenceCategory _getGeneralCategory() {
    return PreferenceCategory(
      name: 'general',
      title: 'Общие',
      icon: Icons.settings,
      description: 'Основные настройки приложения',
      preferences: [
        PreferenceDefinition(
          key: 'first_launch',
          title: 'Первый запуск',
          subtitle: 'Является ли это первым запуском приложения',
          type: PreferenceType.bool,
          icon: Icons.start,
          defaultValue: true,
          getter: () => _prefs.isFirstLaunch,
          setter: (value) async {
            if (value == false) {
              await _prefs.setFirstLaunchCompleted();
            }
          },
          isReadOnly: true,
        ),
        PreferenceDefinition(
          key: 'theme_mode',
          title: 'Режим темы',
          subtitle: 'Выберите тему оформления',
          type: PreferenceType.themeMode,
          icon: Icons.palette,
          defaultValue: ThemeMode.system,
          allowedValues: [ThemeMode.system, ThemeMode.light, ThemeMode.dark],
          getter: () => _prefs.themeMode,
          setter: (value) => _prefs.setThemeMode(value),
        ),
        PreferenceDefinition(
          key: 'language',
          title: 'Язык интерфейса',
          subtitle: 'Выберите язык приложения',
          type: PreferenceType.string,
          icon: Icons.language,
          defaultValue: 'system',
          allowedValues: ['system', 'ru', 'en', 'de', 'fr', 'es'],
          getter: () => _prefs.language,
          setter: (value) => _prefs.setLanguage(value),
        ),
        PreferenceDefinition(
          key: 'auto_lock_timeout',
          title: 'Таймаут автоблокировки',
          subtitle: 'Время в минутах до автоматической блокировки',
          type: PreferenceType.int,
          icon: Icons.lock_clock,
          defaultValue: 5,
          minValue: 1,
          maxValue: 120,
          allowedValues: [1, 5, 10, 15, 30, 60, 120],
          getter: () => _prefs.autoLockTimeout,
          setter: (value) => _prefs.setAutoLockTimeout(value),
        ),
      ],
    );
  }

  /// Настройки безопасности
  static PreferenceCategory _getSecurityCategory() {
    return PreferenceCategory(
      name: 'security',
      title: 'Безопасность',
      icon: Icons.security,
      description: 'Настройки защиты и аутентификации',
      preferences: [
        PreferenceDefinition(
          key: 'biometric_enabled',
          title: 'Биометрическая аутентификация',
          subtitle: 'Использовать отпечаток пальца или Face ID',
          type: PreferenceType.bool,
          icon: Icons.fingerprint,
          defaultValue: false,
          getter: () => _prefs.isBiometricEnabled,
          setter: (value) => _prefs.setBiometricEnabled(value),
        ),
        PreferenceDefinition(
          key: 'pin_enabled',
          title: 'PIN-код',
          subtitle: 'Использовать PIN-код для входа',
          type: PreferenceType.bool,
          icon: Icons.pin,
          defaultValue: false,
          getter: () => _prefs.isPinEnabled,
          setter: (value) => _prefs.setPinEnabled(value),
        ),
        PreferenceDefinition(
          key: 'auto_lock_enabled',
          title: 'Автоблокировка',
          subtitle: 'Автоматически блокировать приложение',
          type: PreferenceType.bool,
          icon: Icons.lock,
          defaultValue: true,
          getter: () => _prefs.isAutoLockEnabled,
          setter: (value) => _prefs.setAutoLockEnabled(value),
        ),
        PreferenceDefinition(
          key: 'clipboard_clear_timeout',
          title: 'Очистка буфера обмена',
          subtitle: 'Время в секундах до очистки скопированных данных',
          type: PreferenceType.int,
          icon: Icons.content_copy,
          defaultValue: 30,
          minValue: 5,
          maxValue: 300,
          allowedValues: [5, 10, 15, 30, 60, 120, 300],
          getter: () => _prefs.clipboardClearTimeout,
          setter: (value) => _prefs.setClipboardClearTimeout(value),
        ),
      ],
    );
  }

  /// Настройки хранилища
  static PreferenceCategory _getStorageCategory() {
    return PreferenceCategory(
      name: 'storage',
      title: 'Хранилища',
      icon: Icons.storage,
      description: 'Настройки управления хранилищами паролей',
      preferences: [
        PreferenceDefinition(
          key: 'default_store_path',
          title: 'Путь по умолчанию',
          subtitle: 'Путь к хранилищу по умолчанию',
          type: PreferenceType.string,
          icon: Icons.folder,
          getter: () => _prefs.defaultStorePath,
          setter: (value) => _prefs.setDefaultStorePath(value),
        ),
        PreferenceDefinition(
          key: 'last_used_store',
          title: 'Последнее хранилище',
          subtitle: 'Путь к последнему использованному хранилищу',
          type: PreferenceType.string,
          icon: Icons.history,
          getter: () => _prefs.lastUsedStore,
          setter: (value) => _prefs.setLastUsedStore(value),
        ),
        PreferenceDefinition(
          key: 'recent_stores',
          title: 'Недавние хранилища',
          subtitle: 'Список недавно использованных хранилищ',
          type: PreferenceType.stringList,
          icon: Icons.recent_actors,
          getter: () => _prefs.recentStores,
          setter: null, // Управляется через специальные методы
          isReadOnly: true,
        ),
      ],
    );
  }

  /// Настройки интерфейса
  static PreferenceCategory _getInterfaceCategory() {
    return PreferenceCategory(
      name: 'interface',
      title: 'Интерфейс',
      icon: Icons.dashboard,
      description: 'Настройки внешнего вида и поведения интерфейса',
      preferences: [
        PreferenceDefinition(
          key: 'show_password_strength',
          title: 'Индикатор силы пароля',
          subtitle: 'Показывать индикатор силы пароля',
          type: PreferenceType.bool,
          icon: Icons.security,
          defaultValue: true,
          getter: () => _prefs.showPasswordStrength,
          setter: (value) => _prefs.setShowPasswordStrength(value),
        ),
        PreferenceDefinition(
          key: 'compact_mode',
          title: 'Компактный режим',
          subtitle: 'Использовать компактное отображение',
          type: PreferenceType.bool,
          icon: Icons.view_compact,
          defaultValue: false,
          getter: () => _prefs.isCompactMode,
          setter: (value) => _prefs.setCompactMode(value),
        ),
        PreferenceDefinition(
          key: 'show_tags',
          title: 'Показывать теги',
          subtitle: 'Отображать теги записей',
          type: PreferenceType.bool,
          icon: Icons.tag,
          defaultValue: true,
          getter: () => _prefs.showTags,
          setter: (value) => _prefs.setShowTags(value),
        ),
        PreferenceDefinition(
          key: 'dark_mode_enabled',
          title: 'Темная тема (устарело)',
          subtitle: 'Использовать темную тему',
          type: PreferenceType.bool,
          icon: Icons.dark_mode,
          defaultValue: false,
          getter: () => _prefs.isDarkModeEnabled,
          setter: (value) => _prefs.setDarkModeEnabled(value),
          isDeprecated: true,
        ),
      ],
    );
  }

  /// Настройки генератора паролей
  static PreferenceCategory _getPasswordGeneratorCategory() {
    return PreferenceCategory(
      name: 'password_generator',
      title: 'Генератор паролей',
      icon: Icons.vpn_key,
      description: 'Настройки генерации паролей',
      preferences: [
        PreferenceDefinition(
          key: 'password_length',
          title: 'Длина пароля',
          subtitle: 'Количество символов в генерируемом пароле',
          type: PreferenceType.int,
          icon: Icons.straighten,
          defaultValue: 16,
          minValue: 4,
          maxValue: 128,
          getter: () => _prefs.passwordLength,
          setter: (value) => _prefs.setPasswordLength(value),
        ),
        PreferenceDefinition(
          key: 'include_uppercase',
          title: 'Заглавные буквы',
          subtitle: 'Включать заглавные буквы (A-Z)',
          type: PreferenceType.bool,
          icon: Icons.format_size,
          defaultValue: true,
          getter: () => _prefs.includeUppercase,
          setter: (value) => _prefs.setIncludeUppercase(value),
        ),
        PreferenceDefinition(
          key: 'include_lowercase',
          title: 'Строчные буквы',
          subtitle: 'Включать строчные буквы (a-z)',
          type: PreferenceType.bool,
          icon: Icons.text_fields,
          defaultValue: true,
          getter: () => _prefs.includeLowercase,
          setter: (value) => _prefs.setIncludeLowercase(value),
        ),
        PreferenceDefinition(
          key: 'include_numbers',
          title: 'Цифры',
          subtitle: 'Включать цифры (0-9)',
          type: PreferenceType.bool,
          icon: Icons.numbers,
          defaultValue: true,
          getter: () => _prefs.includeNumbers,
          setter: (value) => _prefs.setIncludeNumbers(value),
        ),
        PreferenceDefinition(
          key: 'include_symbols',
          title: 'Специальные символы',
          subtitle: 'Включать символы (!@#\$%^&*)',
          type: PreferenceType.bool,
          icon: Icons.star,
          defaultValue: false,
          getter: () => _prefs.includeSymbols,
          setter: (value) => _prefs.setIncludeSymbols(value),
        ),
        PreferenceDefinition(
          key: 'exclude_similar',
          title: 'Исключить похожие',
          subtitle: 'Исключить похожие символы (0/O, 1/l/I)',
          type: PreferenceType.bool,
          icon: Icons.visibility_off,
          defaultValue: true,
          getter: () => _prefs.excludeSimilar,
          setter: (value) => _prefs.setExcludeSimilar(value),
        ),
      ],
    );
  }

  /// Настройки резервного копирования
  static PreferenceCategory _getBackupCategory() {
    return PreferenceCategory(
      name: 'backup',
      title: 'Резервное копирование',
      icon: Icons.backup,
      description: 'Настройки автоматического резервного копирования',
      preferences: [
        PreferenceDefinition(
          key: 'auto_backup_enabled',
          title: 'Автоматическое резервное копирование',
          subtitle: 'Включить автоматическое создание резервных копий',
          type: PreferenceType.bool,
          icon: Icons.backup,
          defaultValue: false,
          getter: () => _prefs.isAutoBackupEnabled,
          setter: (value) => _prefs.setAutoBackupEnabled(value),
        ),
        PreferenceDefinition(
          key: 'backup_frequency',
          title: 'Частота резервного копирования',
          subtitle: 'Интервал создания резервных копий в днях',
          type: PreferenceType.int,
          icon: Icons.schedule,
          defaultValue: 7,
          minValue: 1,
          maxValue: 30,
          allowedValues: [1, 3, 7, 14, 30],
          getter: () => _prefs.backupFrequency,
          setter: (value) => _prefs.setBackupFrequency(value),
        ),
        PreferenceDefinition(
          key: 'backup_path',
          title: 'Путь для резервных копий',
          subtitle: 'Папка для сохранения резервных копий',
          type: PreferenceType.string,
          icon: Icons.folder_special,
          getter: () => _prefs.backupPath,
          setter: (value) => _prefs.setBackupPath(value),
        ),
        PreferenceDefinition(
          key: 'last_backup_date',
          title: 'Последняя резервная копия',
          subtitle: 'Дата создания последней резервной копии',
          type: PreferenceType.dateTime,
          icon: Icons.access_time,
          getter: () => _prefs.lastBackupDate,
          setter: (value) => _prefs.setLastBackupDate(value),
          isReadOnly: true,
        ),
      ],
    );
  }

  /// Настройки отладки
  static PreferenceCategory _getDebugCategory() {
    return PreferenceCategory(
      name: 'debug',
      title: 'Отладка',
      icon: Icons.bug_report,
      description: 'Настройки для разработчиков и отладки',
      preferences: [
        PreferenceDefinition(
          key: 'all_settings_count',
          title: 'Количество настроек',
          subtitle: 'Общее количество сохраненных настроек',
          type: PreferenceType.int,
          icon: Icons.numbers,
          getter: () => _prefs.getAllSettings().length,
          setter: null,
          isReadOnly: true,
        ),
      ],
    );
  }
}
