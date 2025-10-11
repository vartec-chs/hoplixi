# Интеграция экрана управления Credentials в роутер

## Шаг 1: Добавить путь в routes_path.dart

Добавьте новый путь в класс `AppRoutes`:

```dart
class AppRoutes {
  // ... существующие пути
  static const String credentialManager = '/credentials';
}
```

## Шаг 2: Добавить импорт в routes.dart

Добавьте импорт экрана в начало файла `routes.dart`:

```dart
import 'package:hoplixi/features/cloud_sync/screens/manage_credential_screen.dart';
```

## Шаг 3: Добавить маршрут в routes.dart

Добавьте новый маршрут в список `appRoutes`:

```dart
final List<GoRoute> appRoutes = [
  // ... существующие маршруты
  
  GoRoute(
    path: AppRoutes.credentialManager,
    builder: (context, state) => const ManageCredentialScreen(),
  ),
  
  // ... остальные маршруты
];
```

## Шаг 4: Навигация к экрану

Для перехода к экрану используйте:

```dart
// Вариант 1: Через GoRouter
context.push(AppRoutes.credentialManager);

// Вариант 2: Через named route
context.pushNamed('credentialManager');

// Вариант 3: В кнопке
SmoothButton(
  label: 'Управление Credentials',
  onPressed: () => context.push(AppRoutes.credentialManager),
)
```

## Полный пример интеграции

### routes_path.dart
```dart
class AppRoutes {
  static const String splash = '/splash';
  static const String logs = '/logs';
  // ... другие пути
  static const String credentialManager = '/credentials'; // НОВЫЙ ПУТЬ
}
```

### routes.dart
```dart
import 'package:hoplixi/features/cloud_sync/screens/manage_credential_screen.dart'; // НОВЫЙ ИМПОРТ

final List<GoRoute> appRoutes = [
  GoRoute(
    path: AppRoutes.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  // ... другие маршруты
  
  // НОВЫЙ МАРШРУТ
  GoRoute(
    path: AppRoutes.credentialManager,
    builder: (context, state) => const ManageCredentialScreen(),
  ),
];
```

## Пример использования в Settings или Dashboard

Добавьте пункт меню для перехода к управлению credentials:

```dart
ListTile(
  leading: const Icon(Icons.cloud_sync),
  title: const Text('Управление учётными данными'),
  subtitle: const Text('OAuth приложения для синхронизации'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => context.push(AppRoutes.credentialManager),
)
```

Или как кнопку:

```dart
SmoothButton(
  label: 'Настроить синхронизацию',
  icon: const Icon(Icons.cloud),
  onPressed: () => context.push(AppRoutes.credentialManager),
  type: SmoothButtonType.outlined,
)
```
