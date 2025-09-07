/// Автоматическая система настроек приложения
///
/// Эта система позволяет:
/// - Описывать настройки через объекты
/// - Автоматически генерировать интерфейс
/// - Организовывать настройки по категориям и подкатегориям
/// - Валидировать значения
/// - Управлять зависимостями между настройками
///
/// Использование:
/// ```dart
/// // В main.dart
/// await AutoPreferencesManager.init();
/// AppSettingsDefinition.initialize();
///
/// // Получение значения
/// final themeMode = AutoPreferencesManager.instance.getValue<String>('theme_mode');
///
/// // Установка значения
/// await AutoPreferencesManager.instance.setValue('theme_mode', 'dark');
///
/// // Отображение экрана настроек
/// Navigator.push(context, MaterialPageRoute(
///   builder: (context) => const AutoSettingsScreen(),
/// ));
/// ```

library;

// Экспорт основных классов
export 'setting_types.dart';
export 'auto_preferences_manager.dart';
export 'app_settings_definition.dart';
export 'setting_widgets.dart';
export 'auto_settings_screen.dart';

// Экспорт типов для удобства
export 'setting_types.dart'
    show
        SettingType,
        SettingDefinition,
        BooleanSetting,
        StringSetting,
        IntegerSetting,
        ChoiceSetting,
        ActionSetting;
