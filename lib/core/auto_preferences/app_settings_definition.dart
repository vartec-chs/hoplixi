import 'setting_types.dart';
import 'auto_preferences_manager.dart';

/// Конфигурация всех настроек приложения
class AppSettingsDefinition {
  static final AutoPreferencesManager _manager =
      AutoPreferencesManager.instance;

  /// Инициализация всех настроек
  static void initialize() {
    _manager.registerSettings(_getAllSettings());
  }

  /// Получение всех настроек
  static List<SettingDefinition> _getAllSettings() {
    return [
      // ====== ОБЩИЕ НАСТРОЙКИ ======
      ..._getGeneralSettings(),

      // ====== НАСТРОЙКИ БЕЗОПАСНОСТИ ======
      ..._getSecuritySettings(),

      // ====== НАСТРОЙКИ ИНТЕРФЕЙСА ======
      ..._getInterfaceSettings(),

      // ====== НАСТРОЙКИ ГЕНЕРАТОРА ПАРОЛЕЙ ======
      ..._getPasswordGeneratorSettings(),

      // ====== НАСТРОЙКИ ХРАНИЛИЩА ======
      ..._getStorageSettings(),

      // ====== НАСТРОЙКИ РЕЗЕРВНОГО КОПИРОВАНИЯ ======
      ..._getBackupSettings(),

      // ====== НАСТРОЙКИ РАЗРАБОТЧИКА ======
      ..._getDeveloperSettings(),
    ];
  }

  /// Общие настройки
  static List<SettingDefinition> _getGeneralSettings() {
    return [
      ChoiceSetting(
        key: 'theme_mode',
        title: 'Режим темы',
        subtitle: 'Выберите тему приложения',
        category: 'Общие',
        icon: 'brightness_6',
        order: 10,
        defaultValue: 'system',
        options: {'system': 'Системная', 'light': 'Светлая', 'dark': 'Темная'},
        onChanged: (value) {
          // Логика изменения темы
        },
      ),

      ChoiceSetting(
        key: 'language',
        title: 'Язык приложения',
        subtitle: 'Выберите язык интерфейса',
        category: 'Общие',
        icon: 'language',
        order: 20,
        defaultValue: 'system',
        options: {
          'system': 'Системный',
          'ru': 'Русский',
          'en': 'English',
          'uk': 'Українська',
        },
      ),

      IntegerSetting(
        key: 'auto_lock_timeout',
        title: 'Время автоблокировки',
        subtitle: 'Автоматическая блокировка через указанное время',
        category: 'Общие',
        subcategory: 'Безопасность',
        icon: 'timer',
        order: 30,
        defaultValue: 5,
        min: 1,
        max: 60,
        unit: 'мин',
        isSlider: true,
      ),

      BooleanSetting(
        key: 'auto_lock_enabled',
        title: 'Автоблокировка',
        subtitle: 'Автоматически блокировать приложение при бездействии',
        category: 'Общие',
        subcategory: 'Безопасность',
        icon: 'lock_clock',
        order: 25,
        defaultValue: true,
      ),
    ];
  }

  /// Настройки безопасности
  static List<SettingDefinition> _getSecuritySettings() {
    return [
      BooleanSetting(
        key: 'biometric_enabled',
        title: 'Биометрическая аутентификация',
        subtitle: 'Использовать отпечаток пальца или Face ID',
        category: 'Безопасность',
        icon: 'fingerprint',
        order: 10,
        defaultValue: false,
      ),

      BooleanSetting(
        key: 'pin_enabled',
        title: 'PIN-код',
        subtitle: 'Использовать PIN-код для входа',
        category: 'Безопасность',
        icon: 'pin',
        order: 20,
        defaultValue: false,
      ),

      IntegerSetting(
        key: 'clipboard_clear_timeout',
        title: 'Очистка буфера обмена',
        subtitle: 'Автоматическая очистка скопированных паролей',
        category: 'Безопасность',
        subcategory: 'Конфиденциальность',
        icon: 'content_paste_off',
        order: 30,
        defaultValue: 30,
        min: 5,
        max: 300,
        unit: 'сек',
        isSlider: true,
      ),

      BooleanSetting(
        key: 'screen_recording_protection',
        title: 'Защита от записи экрана',
        subtitle: 'Блокировать запись экрана и скриншоты',
        category: 'Безопасность',
        subcategory: 'Конфиденциальность',
        icon: 'screen_lock_portrait',
        order: 40,
        defaultValue: true,
      ),

      BooleanSetting(
        key: 'auto_logout_on_app_switch',
        title: 'Выход при переключении приложений',
        subtitle:
            'Автоматически блокировать при переключении на другое приложение',
        category: 'Безопасность',
        subcategory: 'Конфиденциальность',
        icon: 'app_blocking',
        order: 50,
        defaultValue: false,
      ),
    ];
  }

  /// Настройки интерфейса
  static List<SettingDefinition> _getInterfaceSettings() {
    return [
      BooleanSetting(
        key: 'compact_mode',
        title: 'Компактный режим',
        subtitle: 'Уменьшенные отступы и размеры элементов',
        category: 'Интерфейс',
        subcategory: 'Внешний вид',
        icon: 'view_compact',
        order: 10,
        defaultValue: false,
      ),

      BooleanSetting(
        key: 'show_password_strength',
        title: 'Индикатор силы пароля',
        subtitle: 'Показывать оценку надежности паролей',
        category: 'Интерфейс',
        subcategory: 'Пароли',
        icon: 'security',
        order: 20,
        defaultValue: true,
      ),

      BooleanSetting(
        key: 'show_tags',
        title: 'Отображение тегов',
        subtitle: 'Показывать теги записей в списке',
        category: 'Интерфейс',
        subcategory: 'Списки',
        icon: 'label',
        order: 30,
        defaultValue: true,
      ),

      BooleanSetting(
        key: 'show_search_history',
        title: 'История поиска',
        subtitle: 'Сохранять и показывать историю поисковых запросов',
        category: 'Интерфейс',
        subcategory: 'Поиск',
        icon: 'history',
        order: 40,
        defaultValue: true,
      ),

      IntegerSetting(
        key: 'list_page_size',
        title: 'Количество записей на странице',
        subtitle: 'Максимальное количество записей в списке',
        category: 'Интерфейс',
        subcategory: 'Списки',
        icon: 'format_list_numbered',
        order: 50,
        defaultValue: 50,
        min: 10,
        max: 200,
        isSlider: true,
      ),

      ChoiceSetting(
        key: 'list_sort_order',
        title: 'Сортировка списка',
        subtitle: 'Порядок сортировки записей по умолчанию',
        category: 'Интерфейс',
        subcategory: 'Списки',
        icon: 'sort',
        order: 60,
        defaultValue: 'name_asc',
        options: {
          'name_asc': 'По названию (А-Я)',
          'name_desc': 'По названию (Я-А)',
          'created_asc': 'По дате создания (старые)',
          'created_desc': 'По дате создания (новые)',
          'modified_asc': 'По дате изменения (старые)',
          'modified_desc': 'По дате изменения (новые)',
        },
      ),
    ];
  }

  /// Настройки генератора паролей
  static List<SettingDefinition> _getPasswordGeneratorSettings() {
    return [
      IntegerSetting(
        key: 'password_length',
        title: 'Длина пароля',
        subtitle: 'Количество символов в генерируемом пароле',
        category: 'Генератор паролей',
        icon: 'straighten',
        order: 10,
        defaultValue: 16,
        min: 4,
        max: 128,
        isSlider: true,
      ),

      BooleanSetting(
        key: 'include_uppercase',
        title: 'Заглавные буквы',
        subtitle: 'Включать заглавные буквы (A-Z)',
        category: 'Генератор паролей',
        subcategory: 'Символы',
        icon: 'text_fields',
        order: 20,
        defaultValue: true,
      ),

      BooleanSetting(
        key: 'include_lowercase',
        title: 'Строчные буквы',
        subtitle: 'Включать строчные буквы (a-z)',
        category: 'Генератор паролей',
        subcategory: 'Символы',
        icon: 'text_fields',
        order: 30,
        defaultValue: true,
      ),

      BooleanSetting(
        key: 'include_numbers',
        title: 'Цифры',
        subtitle: 'Включать цифры (0-9)',
        category: 'Генератор паролей',
        subcategory: 'Символы',
        icon: 'pin',
        order: 40,
        defaultValue: true,
      ),

      BooleanSetting(
        key: 'include_symbols',
        title: 'Специальные символы',
        subtitle: 'Включать символы (!@#\$%^&*)',
        category: 'Генератор паролей',
        subcategory: 'Символы',
        icon: 'tag',
        order: 50,
        defaultValue: false,
      ),

      BooleanSetting(
        key: 'exclude_similar',
        title: 'Исключить похожие символы',
        subtitle: 'Исключить символы 0, O, l, I, 1',
        category: 'Генератор паролей',
        subcategory: 'Символы',
        icon: 'visibility_off',
        order: 60,
        defaultValue: true,
      ),

      StringSetting(
        key: 'custom_symbols',
        title: 'Пользовательские символы',
        subtitle: 'Дополнительные символы для генерации',
        category: 'Генератор паролей',
        subcategory: 'Дополнительно',
        icon: 'keyboard',
        order: 70,
        defaultValue: '',
        maxLength: 50,
        placeholder: 'Введите символы...',
      ),

      BooleanSetting(
        key: 'pronounceable_passwords',
        title: 'Произносимые пароли',
        subtitle: 'Генерировать пароли, легкие для произношения',
        category: 'Генератор паролей',
        subcategory: 'Дополнительно',
        icon: 'record_voice_over',
        order: 80,
        defaultValue: false,
      ),
    ];
  }

  /// Настройки хранилища
  static List<SettingDefinition> _getStorageSettings() {
    return [
      StringSetting(
        key: 'default_store_path',
        title: 'Путь к хранилищу по умолчанию',
        subtitle: 'Расположение файла базы данных',
        category: 'Хранилище',
        icon: 'folder',
        order: 10,
        defaultValue: '',
        placeholder: 'Выберите папку...',
        isReadOnly: true,
      ),

      IntegerSetting(
        key: 'recent_stores_limit',
        title: 'Количество недавних хранилищ',
        subtitle: 'Максимальное количество недавно открытых баз',
        category: 'Хранилище',
        subcategory: 'История',
        icon: 'history',
        order: 20,
        defaultValue: 10,
        min: 3,
        max: 20,
      ),

      BooleanSetting(
        key: 'auto_save_enabled',
        title: 'Автосохранение',
        subtitle: 'Автоматически сохранять изменения',
        category: 'Хранилище',
        icon: 'save',
        order: 30,
        defaultValue: true,
      ),

      IntegerSetting(
        key: 'auto_save_interval',
        title: 'Интервал автосохранения',
        subtitle: 'Частота автоматического сохранения',
        category: 'Хранилище',
        subcategory: 'Автосохранение',
        icon: 'timer',
        order: 40,
        defaultValue: 30,
        min: 5,
        max: 300,
        unit: 'сек',
        dependencies: ['auto_save_enabled'],
        isSlider: true,
      ),

      BooleanSetting(
        key: 'compress_database',
        title: 'Сжатие базы данных',
        subtitle: 'Использовать сжатие для экономии места',
        category: 'Хранилище',
        subcategory: 'Оптимизация',
        icon: 'compress',
        order: 50,
        defaultValue: true,
      ),
    ];
  }

  /// Настройки резервного копирования
  static List<SettingDefinition> _getBackupSettings() {
    return [
      BooleanSetting(
        key: 'auto_backup_enabled',
        title: 'Автоматическое резервное копирование',
        subtitle: 'Создавать резервные копии автоматически',
        category: 'Резервное копирование',
        icon: 'backup',
        order: 10,
        defaultValue: false,
      ),

      IntegerSetting(
        key: 'backup_frequency',
        title: 'Частота резервного копирования',
        subtitle: 'Как часто создавать резервные копии',
        category: 'Резервное копирование',
        icon: 'schedule',
        order: 20,
        defaultValue: 7,
        min: 1,
        max: 30,
        unit: 'дней',
        dependencies: ['auto_backup_enabled'],
        isSlider: true,
      ),

      StringSetting(
        key: 'backup_path',
        title: 'Путь для резервных копий',
        subtitle: 'Папка для сохранения резервных копий',
        category: 'Резервное копирование',
        icon: 'folder_special',
        order: 30,
        defaultValue: '',
        placeholder: 'Выберите папку...',
        dependencies: ['auto_backup_enabled'],
        isReadOnly: true,
      ),

      IntegerSetting(
        key: 'backup_retention_days',
        title: 'Хранение резервных копий',
        subtitle: 'Количество дней хранения старых копий',
        category: 'Резервное копирование',
        subcategory: 'Очистка',
        icon: 'delete_sweep',
        order: 40,
        defaultValue: 30,
        min: 7,
        max: 365,
        unit: 'дней',
        dependencies: ['auto_backup_enabled'],
        isSlider: true,
      ),

      BooleanSetting(
        key: 'backup_encryption',
        title: 'Шифрование резервных копий',
        subtitle: 'Шифровать резервные копии',
        category: 'Резервное копирование',
        subcategory: 'Безопасность',
        icon: 'enhanced_encryption',
        order: 50,
        defaultValue: true,
        dependencies: ['auto_backup_enabled'],
      ),
    ];
  }

  /// Настройки разработчика
  static List<SettingDefinition> _getDeveloperSettings() {
    return [
      BooleanSetting(
        key: 'debug_mode',
        title: 'Режим отладки',
        subtitle: 'Включить дополнительную информацию для отладки',
        category: 'Разработчик',
        icon: 'bug_report',
        order: 10,
        defaultValue: false,
      ),

      BooleanSetting(
        key: 'verbose_logging',
        title: 'Подробное логирование',
        subtitle: 'Записывать детальные логи операций',
        category: 'Разработчик',
        icon: 'article',
        order: 20,
        defaultValue: false,
        dependencies: ['debug_mode'],
      ),

      ActionSetting(
        key: 'clear_logs',
        title: 'Очистить логи',
        subtitle: 'Удалить все файлы логов',
        category: 'Разработчик',
        icon: 'clear_all',
        order: 30,
        buttonText: 'Очистить',
        confirmationMessage: 'Вы действительно хотите удалить все логи?',
        action: () async {
          // Логика очистки логов
        },
      ),

      ActionSetting(
        key: 'export_debug_info',
        title: 'Экспорт отладочной информации',
        subtitle: 'Создать файл с информацией для разработчиков',
        category: 'Разработчик',
        icon: 'file_download',
        order: 40,
        buttonText: 'Экспорт',
        action: () async {
          // Логика экспорта отладочной информации
        },
      ),

      ActionSetting(
        key: 'reset_all_settings',
        title: 'Сбросить все настройки',
        subtitle: 'Вернуть все настройки к значениям по умолчанию',
        category: 'Разработчик',
        icon: 'restart_alt',
        order: 50,
        buttonText: 'Сбросить',
        confirmationMessage: 'Это действие нельзя отменить. Продолжить?',
        isDestructive: true,
        action: () async {
          await _manager.resetAllSettings();
        },
      ),
    ];
  }
}
