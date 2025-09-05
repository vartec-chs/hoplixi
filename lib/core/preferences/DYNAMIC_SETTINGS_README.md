# AppPreferences - Динамическая система управления настройками

Полноценная система управления настройками приложения Hoplixi с динамическим UI и автоматическим обнаружением новых настроек.

## Основные возможности

- ✅ **Singleton паттерн** - один экземпляр на всё приложение
- ✅ **Типобезопасная работа** с настройками
- ✅ **Автоматическая инициализация** SharedPreferences
- ✅ **Динамический UI** - новые настройки автоматически появляются в интерфейсе
- ✅ **Категоризация настроек** - группировка по функциональному назначению
- ✅ **Поиск и фильтрация** настроек
- ✅ **Riverpod провайдеры** для реактивного UI
- ✅ **Экспорт/импорт** настроек
- ✅ **Отладочная информация** и статистика

## Архитектура системы

### Компоненты

1. **AppPreferences** - основной singleton класс для работы с SharedPreferences
2. **PreferenceDefinition** - описание структуры настройки
3. **PreferencesRegistry** - реестр всех настроек приложения
4. **PreferenceEditors** - виджеты для редактирования разных типов настроек
5. **DynamicSettingsScreen** - основной экран настроек с поиском и фильтрацией
6. **Провайдеры** - Riverpod провайдеры для реактивного UI

### Поддерживаемые типы настроек

- `bool` - переключатели
- `int` - слайдеры или выпадающие списки
- `double` - слайдеры
- `string` - текстовые поля или выпадающие списки
- `stringList` - списки строк
- `themeMode` - режим темы
- `dateTime` - дата и время

## Быстрый старт

### 1. Инициализация

```dart
// В main.dart перед runApp()
WidgetsFlutterBinding.ensureInitialized();
await AppPreferences.init();
```

### 2. Основное использование

```dart
final prefs = AppPreferences.instance;

// Проверка первого запуска
if (prefs.isFirstLaunch) {
  await prefs.setFirstLaunchCompleted();
}

// Работа с настройками
await prefs.setThemeMode(ThemeMode.dark);
final theme = prefs.themeMode;
```

### 3. Открытие экрана настроек

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const DynamicSettingsScreen(),
  ),
);
```

## Добавление новых настроек

### Шаг 1: Добавить в AppPreferences

```dart
// Добавить ключ
static const String _keyMyNewSetting = 'my_new_setting';

// Добавить getter
bool get myNewSetting {
  _ensureInitialized();
  return _prefs!.getBool(_keyMyNewSetting) ?? false;
}

// Добавить setter
Future<void> setMyNewSetting(bool value) async {
  _ensureInitialized();
  await _prefs!.setBool(_keyMyNewSetting, value);
}
```

### Шаг 2: Добавить в PreferencesRegistry

```dart
PreferenceDefinition(
  key: 'my_new_setting',
  title: 'Моя новая настройка',
  subtitle: 'Описание того, что делает настройка',
  type: PreferenceType.bool,
  icon: Icons.new_releases,
  defaultValue: false,
  getter: () => _prefs.myNewSetting,
  setter: (value) => _prefs.setMyNewSetting(value),
),
```

### Шаг 3: Готово! 

Настройка автоматически появится в динамическом UI экрана настроек.

## Категории настроек

### Общие (`general`)
- Первый запуск
- Режим темы
- Язык интерфейса
- Таймаут автоблокировки

### Безопасность (`security`)
- Биометрическая аутентификация
- PIN-код
- Автоблокировка
- Очистка буфера обмена

### Хранилища (`storage`)
- Путь по умолчанию
- Последнее хранилище
- Недавние хранилища

### Интерфейс (`interface`)
- Индикатор силы пароля
- Компактный режим
- Показ тегов

### Генератор паролей (`password_generator`)
- Длина пароля
- Включение символов разных типов
- Исключение похожих символов

### Резервное копирование (`backup`)
- Автоматическое резервное копирование
- Частота создания копий
- Путь для резервных копий

### Отладка (`debug`)
- Количество настроек
- Другая отладочная информация

## Использование с Riverpod

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final securitySettings = ref.watch(securitySettingsProvider);
    
    return MaterialApp(
      themeMode: themeMode,
      // ...
    );
  }
}

// Изменение настроек
ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
ref.read(securitySettingsProvider.notifier).setBiometricEnabled(true);
```

## Особенности экрана настроек

### Поиск и фильтрация
- Поиск по названию, ключу и описанию
- Фильтр устаревших настроек
- Фильтр настроек только для чтения

### Категоризация
- Настройки разбиты по функциональным категориям
- Отдельная вкладка для каждой категории
- Универсальная вкладка поиска

### Дополнительные функции
- Просмотр всех настроек в raw виде
- Экспорт настроек в JSON
- Сброс настроек с подтверждением
- Отладочная информация

## Примеры использования

### Простое демо-приложение

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppPreferences.init();
  runApp(const PreferencesDemo());
}
```

### Интеграция в существующее приложение

```dart
// В основном экране добавить кнопку настроек
IconButton(
  icon: const Icon(Icons.settings),
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DynamicSettingsScreen(),
      ),
    );
  },
)
```

## Файлы модуля

- `app_preferences.dart` - основной singleton класс
- `preference_definition.dart` - определение структуры настройки
- `preferences_registry.dart` - реестр всех настроек
- `preference_editors.dart` - виджеты для редактирования
- `dynamic_settings_screen.dart` - основной экран настроек
- `app_preferences_providers.dart` - Riverpod провайдеры
- `settings_demo.dart` - старый экран настроек для сравнения
- `preferences_demo_app.dart` - демо-приложение
- `index.dart` - экспорты модуля

## Безопасность

Модуль использует SharedPreferences для хранения настроек в открытом виде.
Для конфиденциальных данных используйте модуль `secure_storage`.

## Производительность

- Lazy loading настроек
- Кэширование в памяти
- Минимальные перерисовки UI через правильное использование State
- Эффективная фильтрация и поиск

## Расширяемость

Система спроектирована для легкого добавления новых типов настроек:

1. Добавить новый `PreferenceType`
2. Создать соответствующий `PreferenceEditor`
3. Обновить `PreferenceEditor.create()`
4. Добавить настройки в реестр

Система автоматически подхватит новые настройки в UI.
