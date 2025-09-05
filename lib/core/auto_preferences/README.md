# Автоматическая система настроек

Простая и мощная система для управления настройками приложения с автоматической генерацией интерфейса.

## Основные возможности

- 🎯 **Декларативное описание настроек** - настройки описываются через объекты
- 🏗️ **Автоматическая генерация UI** - интерфейс создается автоматически
- 📁 **Категории и подкатегории** - организация настроек в группы
- ✅ **Валидация** - проверка значений с кастомными валидаторами
- 🔗 **Зависимости** - настройки могут зависеть друг от друга
- 🔍 **Поиск и фильтрация** - быстрый поиск нужных настроек
- 💾 **Автоматическое сохранение** - все изменения сохраняются в SharedPreferences
- 🎨 **Кастомизация** - гибкая настройка внешнего вида

## Поддерживаемые типы настроек

### Базовые типы
- `BooleanSetting` - переключатели (true/false)
- `StringSetting` - текстовые поля
- `IntegerSetting` - числовые поля и ползунки
- `ChoiceSetting` - выбор из списка вариантов
- `ActionSetting` - кнопки-действия

### Специальные типы
- Многострочный текст
- Пароли (скрытый ввод)
- Пути к файлам и папкам
- Цвета
- Даты и время
- Списки строк

## Быстрый старт

### 1. Инициализация

```dart
// В main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализируем менеджер настроек
  await AutoPreferencesManager.init();
  
  // Регистрируем все настройки
  AppSettingsDefinition.initialize();
  
  runApp(MyApp());
}
```

### 2. Описание настроек

Настройки описываются в файле `app_settings_definition.dart`:

```dart
// Простая булева настройка
BooleanSetting(
  key: 'dark_mode_enabled',
  title: 'Темная тема',
  subtitle: 'Использовать темную тему интерфейса',
  category: 'Интерфейс',
  defaultValue: false,
),

// Настройка с ползунком
IntegerSetting(
  key: 'auto_lock_timeout',
  title: 'Время автоблокировки',
  subtitle: 'Автоматическая блокировка через указанное время',
  category: 'Безопасность',
  defaultValue: 5,
  min: 1,
  max: 60,
  unit: 'мин',
  isSlider: true,
),

// Выбор из списка
ChoiceSetting(
  key: 'theme_mode',
  title: 'Режим темы',
  category: 'Интерфейс',
  defaultValue: 'system',
  options: {
    'system': 'Системная',
    'light': 'Светлая',
    'dark': 'Темная',
  },
),

// Действие (кнопка)
ActionSetting(
  key: 'clear_cache',
  title: 'Очистить кеш',
  subtitle: 'Удалить временные файлы',
  category: 'Система',
  buttonText: 'Очистить',
  confirmationMessage: 'Удалить все временные файлы?',
  action: () async {
    // Логика очистки кеша
  },
),
```

### 3. Использование в коде

```dart
final manager = AutoPreferencesManager.instance;

// Получение значения
bool isDarkMode = manager.getValue<bool>('dark_mode_enabled');

// Установка значения
await manager.setValue('dark_mode_enabled', true);

// Слушатель изменений
manager.addListener('dark_mode_enabled', (value) {
  print('Тема изменена: $value');
});
```

### 4. Отображение экрана настроек

```dart
// Простое отображение
Navigator.push(context, MaterialPageRoute(
  builder: (context) => const AutoSettingsScreen(),
));

// Или как часть навигации
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AutoSettingsScreen();
  }
}
```

## Продвинутые возможности

### Категории и подкатегории

```dart
BooleanSetting(
  key: 'biometric_enabled',
  title: 'Биометрическая аутентификация',
  category: 'Безопасность',           // Основная категория
  subcategory: 'Аутентификация',      // Подкатегория
  defaultValue: false,
),
```

### Валидация

```dart
StringSetting(
  key: 'server_url',
  title: 'URL сервера',
  category: 'Сеть',
  defaultValue: '',
  validator: (value) {
    if (value.isEmpty) return 'URL не может быть пустым';
    if (!value.startsWith('https://')) return 'URL должен начинаться с https://';
    return null;
  },
),
```

### Зависимости

```dart
IntegerSetting(
  key: 'backup_frequency',
  title: 'Частота резервного копирования',
  category: 'Резервное копирование',
  defaultValue: 7,
  dependencies: ['auto_backup_enabled'], // Зависит от включения автобэкапа
),
```

### Колбеки изменений

```dart
BooleanSetting(
  key: 'push_notifications',
  title: 'Push-уведомления',
  category: 'Уведомления',
  defaultValue: true,
  onChanged: (value) {
    // Настроить push-уведомления
    NotificationService.setEnabled(value);
  },
),
```

## Структура проекта

```
lib/core/auto_preferences/
├── index.dart                    # Главный экспорт
├── setting_types.dart           # Типы настроек
├── auto_preferences_manager.dart # Менеджер настроек
├── app_settings_definition.dart # Определения всех настроек
├── setting_widgets.dart         # Виджеты для отображения
├── auto_settings_screen.dart    # Главный экран настроек
└── README.md                    # Этот файл
```

## Кастомизация интерфейса

### Иконки категорий

Система автоматически подбирает иконки для категорий, но их можно переопределить:

```dart
// В auto_settings_screen.dart
Icon _getCategoryIcon(String category) {
  const categoryIcons = {
    'Мои настройки': Icons.person,
    'Кастомная категория': Icons.extension,
  };
  return Icon(categoryIcons[category] ?? Icons.category);
}
```

### Темизация

Интерфейс автоматически адаптируется к теме приложения. Для кастомизации используйте стандартные механизмы Flutter Theme.

## Миграция с существующей системы

Если у вас уже есть настройки через SharedPreferences:

1. Создайте описания настроек в `app_settings_definition.dart`
2. Используйте те же ключи, что и в старой системе
3. Постепенно заменяйте прямые обращения к SharedPreferences на AutoPreferencesManager

## Лучшие практики

1. **Группировка** - используйте категории и подкатегории для организации
2. **Валидация** - всегда валидируйте пользовательский ввод
3. **Значения по умолчанию** - устанавливайте разумные значения по умолчанию
4. **Описания** - добавляйте понятные описания к настройкам
5. **Зависимости** - используйте зависимости для связанных настроек

## Примеры использования

### Настройки темы

```dart
ChoiceSetting(
  key: 'app_theme',
  title: 'Тема приложения',
  subtitle: 'Выберите цветовую схему',
  category: 'Внешний вид',
  icon: 'palette',
  defaultValue: 'blue',
  options: {
    'blue': 'Синяя',
    'green': 'Зеленая',
    'purple': 'Фиолетовая',
    'orange': 'Оранжевая',
  },
  onChanged: (theme) {
    ThemeService.setTheme(theme);
  },
),
```

### Настройки безопасности

```dart
BooleanSetting(
  key: 'require_auth',
  title: 'Требовать аутентификацию',
  subtitle: 'Запрашивать пароль при входе',
  category: 'Безопасность',
  icon: 'lock',
  defaultValue: true,
),

IntegerSetting(
  key: 'auth_timeout',
  title: 'Таймаут аутентификации',
  subtitle: 'Время до повторного запроса пароля',
  category: 'Безопасность',
  subcategory: 'Аутентификация',
  defaultValue: 15,
  min: 5,
  max: 60,
  unit: 'мин',
  dependencies: ['require_auth'],
  isSlider: true,
),
```

### Экспериментальные функции

```dart
BooleanSetting(
  key: 'experimental_features',
  title: 'Экспериментальные функции',
  subtitle: 'Включить функции в разработке',
  category: 'Разработчик',
  icon: 'science',
  defaultValue: false,
),

ActionSetting(
  key: 'reset_experimental',
  title: 'Сбросить экспериментальные настройки',
  category: 'Разработчик',
  dependencies: ['experimental_features'],
  isDestructive: true,
  confirmationMessage: 'Сбросить все экспериментальные настройки?',
  action: () async {
    // Логика сброса
  },
),
```
