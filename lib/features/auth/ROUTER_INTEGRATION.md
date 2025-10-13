# Интеграция экранов cloud_sync в роутер# Интеграция экрана управления Credentials в роутер



## Экраны## Шаг 1: Добавить путь в routes_path.dart



1. **ManageCredentialScreen** - управление учётными данными OAuthДобавьте новый путь в класс `AppRoutes`:

2. **AuthManagerScreen** - добавление OAuth авторизаций

```dart

## Шаг 1: Добавить пути в routes_path.dartclass AppRoutes {

  // ... существующие пути

Добавьте новые пути в класс `AppRoutes`:  static const String credentialManager = '/credentials';

}

```dart```

class AppRoutes {

  // ... существующие пути## Шаг 2: Добавить импорт в routes.dart

  static const String credentialManager = '/credentials';

  static const String authManager = '/auth-manager';Добавьте импорт экрана в начало файла `routes.dart`:

}

``````dart

import 'package:hoplixi/features/auth/screens/manage_credential_screen.dart';

## Шаг 2: Добавить импорты в routes.dart```



Добавьте импорты экранов в начало файла `routes.dart`:## Шаг 3: Добавить маршрут в routes.dart



```dartДобавьте новый маршрут в список `appRoutes`:

import 'package:hoplixi/features/auth/screens/manage_credential_screen.dart';

import 'package:hoplixi/features/auth/screens/auth_manager_screen.dart';```dart

```final List<GoRoute> appRoutes = [

  // ... существующие маршруты

## Шаг 3: Добавить маршруты в routes.dart  

  GoRoute(

Добавьте новые маршруты в список `appRoutes`:    path: AppRoutes.credentialManager,

    builder: (context, state) => const ManageCredentialScreen(),

```dart  ),

final List<GoRoute> appRoutes = [  

  // ... существующие маршруты  // ... остальные маршруты

  ];

  GoRoute(```

    path: AppRoutes.credentialManager,

    builder: (context, state) => const ManageCredentialScreen(),## Шаг 4: Навигация к экрану

  ),

  Для перехода к экрану используйте:

  GoRoute(

    path: AppRoutes.authManager,```dart

    builder: (context, state) => const AuthManagerScreen(),// Вариант 1: Через GoRouter

  ),context.push(AppRoutes.credentialManager);

  

  // ... остальные маршруты// Вариант 2: Через named route

];context.pushNamed('credentialManager');

```

// Вариант 3: В кнопке

## Шаг 4: Навигация к экранамSmoothButton(

  label: 'Управление Credentials',

### Управление Credentials  onPressed: () => context.push(AppRoutes.credentialManager),

)

Для перехода к экрану управления credentials используйте:```



```dart## Полный пример интеграции

// Вариант 1: Через GoRouter

context.push(AppRoutes.credentialManager);### routes_path.dart

```dart

// Вариант 2: Через named routeclass AppRoutes {

context.pushNamed('credentialManager');  static const String splash = '/splash';

  static const String logs = '/logs';

// Вариант 3: В кнопке  // ... другие пути

SmoothButton(  static const String credentialManager = '/credentials'; // НОВЫЙ ПУТЬ

  label: 'Управление Credentials',}

  onPressed: () => context.push(AppRoutes.credentialManager),```

)

```### routes.dart

```dart

### Добавление авторизацииimport 'package:hoplixi/features/cloud_sync/screens/manage_credential_screen.dart'; // НОВЫЙ ИМПОРТ



Для перехода к экрану добавления авторизации используйте:final List<GoRoute> appRoutes = [

  GoRoute(

```dart    path: AppRoutes.splash,

// Вариант 1: Через GoRouter    builder: (context, state) => const SplashScreen(),

context.push(AppRoutes.authManager);  ),

  // ... другие маршруты

// Вариант 2: В кнопке  

SmoothButton(  // НОВЫЙ МАРШРУТ

  label: 'Добавить авторизацию',  GoRoute(

  onPressed: () => context.push(AppRoutes.authManager),    path: AppRoutes.credentialManager,

  icon: const Icon(Icons.login),    builder: (context, state) => const ManageCredentialScreen(),

)  ),

```];

```

## Полный пример интеграции

## Пример использования в Settings или Dashboard

### routes_path.dart

```dartДобавьте пункт меню для перехода к управлению credentials:

class AppRoutes {

  static const String splash = '/splash';```dart

  static const String logs = '/logs';ListTile(

  // ... другие пути  leading: const Icon(Icons.cloud_sync),

  static const String credentialManager = '/credentials'; // НОВЫЙ ПУТЬ  title: const Text('Управление учётными данными'),

  static const String authManager = '/auth-manager'; // НОВЫЙ ПУТЬ  subtitle: const Text('OAuth приложения для синхронизации'),

}  trailing: const Icon(Icons.arrow_forward_ios, size: 16),

```  onTap: () => context.push(AppRoutes.credentialManager),

)

### routes.dart```

```dart

import 'package:hoplixi/features/auth/screens/manage_credential_screen.dart'; // НОВЫЙ ИМПОРТИли как кнопку:

import 'package:hoplixi/features/auth/screens/auth_manager_screen.dart'; // НОВЫЙ ИМПОРТ

```dart

final List<GoRoute> appRoutes = [SmoothButton(

  GoRoute(  label: 'Настроить синхронизацию',

    path: AppRoutes.splash,  icon: const Icon(Icons.cloud),

    builder: (context, state) => const SplashScreen(),  onPressed: () => context.push(AppRoutes.credentialManager),

  ),  type: SmoothButtonType.outlined,

  // ... другие маршруты)

  ```

  // НОВЫЕ МАРШРУТЫ
  GoRoute(
    path: AppRoutes.credentialManager,
    builder: (context, state) => const ManageCredentialScreen(),
  ),
  
  GoRoute(
    path: AppRoutes.authManager,
    builder: (context, state) => const AuthManagerScreen(),
  ),
];
```

## Пример использования в Settings или Dashboard

### Пункт меню для управления credentials

```dart
ListTile(
  leading: const Icon(Icons.cloud_sync),
  title: const Text('Управление учётными данными'),
  subtitle: const Text('OAuth приложения для синхронизации'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => context.push(AppRoutes.credentialManager),
)
```

### Пункт меню для добавления авторизации

```dart
ListTile(
  leading: const Icon(Icons.login),
  title: const Text('Добавить авторизацию'),
  subtitle: const Text('Авторизация облачного хранилища'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
  onTap: () => context.push(AppRoutes.authManager),
)
```

### Кнопки в интерфейсе

```dart
// Кнопка управления credentials
SmoothButton(
  label: 'Настроить синхронизацию',
  icon: const Icon(Icons.cloud),
  onPressed: () => context.push(AppRoutes.credentialManager),
  type: SmoothButtonType.outlined,
)

// Кнопка добавления авторизации
SmoothButton(
  label: 'Добавить авторизацию',
  icon: const Icon(Icons.login),
  onPressed: () => context.push(AppRoutes.authManager),
  type: SmoothButtonType.filled,
)
```

## Рекомендуемый workflow

1. Сначала пользователь переходит в **ManageCredentialScreen** для добавления OAuth credentials (Client ID, Client Secret)
2. После добавления credentials, пользователь переходит в **AuthManagerScreen** для выполнения OAuth авторизации
3. На экране AuthManagerScreen пользователь выбирает credential и выполняет авторизацию
4. После успешной авторизации токены сохраняются и становятся доступны для синхронизации

### Пример интеграции в Settings

```dart
// В разделе "Облачная синхронизация"
ExpansionTile(
  leading: const Icon(Icons.cloud),
  title: const Text('Облачная синхронизация'),
  children: [
    ListTile(
      leading: const Icon(Icons.vpn_key),
      title: const Text('Учётные данные OAuth'),
      subtitle: const Text('Управление Client ID и Secret'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => context.push(AppRoutes.credentialManager),
    ),
    ListTile(
      leading: const Icon(Icons.login),
      title: const Text('Авторизации'),
      subtitle: const Text('Добавить или удалить авторизации'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () => context.push(AppRoutes.authManager),
    ),
  ],
),
```
