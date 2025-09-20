# Setup Feature Documentation

## Обзор

Модуль setup обеспечивает первоначальную настройку приложения Hoplixi через серию интерактивных экранов с современными анимациями.

## Структура

```
lib/features/setup/
├── setup.dart                        # Главный экран с PageView и навигацией
├── index.dart                        # Экспорт всех компонентов
├── providers/
│   └── setup_provider.dart          # Riverpod провайдеры для состояния
└── widgets/
    ├── welcome_screen.dart           # Экран приветствия с анимациями
    ├── theme_selection_screen.dart   # Выбор темы приложения
    └── permissions_screen.dart       # Запрос разрешений

```

## Основные компоненты

### SetupScreen
Главный экран, содержащий:
- PageView для перелистывания между экранами
- SmoothPageIndicator для отображения прогресса
- Кнопки навигации "Назад"/"Далее"
- Автоматическое управление состоянием

### SetupProvider
Riverpod 3 провайдер для управления:
- Текущим индексом экрана
- Списком доступных экранов
- Статусом завершения каждого экрана
- Навигацией между экранами

### Экраны

#### WelcomeScreen
- Анимированный логотип с масштабированием и поворотом
- Плавное появление текста снизу
- Анимированные иконки особенностей приложения
- Градиентный фон

#### ThemeSelectionScreen
- Интерактивные карточки для выбора темы
- Поддержка светлой, тёмной и системной темы
- Анимированное появление элементов
- Интеграция с существующим ThemeProvider

#### PermissionsScreen
- Динамический список разрешений
- Поддержка обязательных и дополнительных разрешений
- Автоматическое определение статуса разрешений
- Переход в настройки при отклонении разрешений

## Использование

### Базовое использование

```dart
import 'package:hoplixi/features/setup/index.dart';

// В роутере
GoRoute(
  path: '/setup',
  builder: (context, state) => const SetupScreen(),
),
```

### Расширение экранов

```dart
// Добавление нового экрана
enum SetupScreenType {
  welcome,
  themeSelection,
  permissions,
  newScreen, // новый экран
}

// В SetupScreen._buildPages()
case SetupScreenType.newScreen:
  return const NewScreen();
```

### Кастомизация разрешений

```dart
// В PermissionsScreen
static const List<PermissionItem> _permissions = [
  PermissionItem(
    permission: Permission.storage,
    title: 'Доступ к файлам',
    description: 'Для сохранения данных',
    icon: Icons.folder_rounded,
    isRequired: true,
  ),
  // Добавить новые разрешения
];
```

## Возможности

### Анимации
- Плавные переходы между экранами
- Эластичные анимации логотипа
- Скольжение и появление текста
- Анимированные списки элементов

### Управление состоянием
- Riverpod 3 Notifier API
- Автоматическая синхронизация PageController
- Отслеживание завершения экранов
- Расширяемая архитектура

### Адаптивность
- Поддержка разных размеров экранов
- Тёмная и светлая темы
- Локализация (готовность)

## Зависимости

```yaml
dependencies:
  smooth_page_indicator: ^1.2.1
  permission_handler: ^12.0.1
  flutter_riverpod: ^3.0.0
```

## Примеры кастомизации

### Добавление нового экрана

1. Создать enum значение в `SetupScreenType`
2. Добавить виджет экрана в `widgets/`
3. Обновить `_buildPages()` в `SetupScreen`
4. При необходимости обновить логику навигации

### Изменение анимаций

```dart
// В любом экране
void _initializeAnimations() {
  _controller = AnimationController(
    duration: const Duration(milliseconds: 1200), // изменить длительность
    vsync: this,
  );
  
  _animation = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: Curves.bounceOut, // изменить кривую
  ));
}
```

### Кастомные разрешения

```dart
// Создать кастомный список разрешений
class CustomPermissionsScreen extends PermissionsScreen {
  static const List<PermissionItem> customPermissions = [
    PermissionItem(
      permission: Permission.bluetooth,
      title: 'Bluetooth',
      description: 'Для синхронизации с устройствами',
      icon: Icons.bluetooth,
      isRequired: false,
    ),
  ];
}
```

## Интеграция

После завершения setup процесса:
1. Отмечаются все экраны как завершенные
2. Вызывается переход к основному экрану
3. Сохраняется статус первого запуска
4. Применяются выбранные настройки

Модуль полностью интегрирован с существующей архитектурой Hoplixi и следует установленным паттернам проекта.