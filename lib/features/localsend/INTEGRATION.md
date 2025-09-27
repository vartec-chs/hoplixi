# Интеграция LocalSend в приложение Hoplixi

## Добавление в навигацию

### 1. Обновите router/app_routes.dart

Добавьте новые маршруты для LocalSend:

```dart
// LocalSend routes
static const String localsendDiscovery = '/localsend-discovery';
static const String localsendTransceiver = '/localsend-transceiver';
```

### 2. Обновите router/app_router.dart

Добавьте маршруты в GoRouter:

```dart
// LocalSend routes
GoRoute(
  path: AppRoutes.localsendDiscovery,
  name: 'localsend-discovery',
  builder: (context, state) => const DiscoveryScreen(),
),
GoRoute(
  path: AppRoutes.localsendTransceiver,
  name: 'localsend-transceiver',
  builder: (context, state) {
    final deviceInfo = state.extra as DeviceInfo;
    return TransceiverScreen(targetDevice: deviceInfo);
  },
),
```

### 3. Добавьте в главное меню

В файле main menu screen добавьте кнопку для перехода к LocalSend:

```dart
SmoothButton(
  type: SmoothButtonType.filled,
  size: SmoothButtonSize.large,
  label: 'LocalSend',
  icon: Icons.share,
  onPressed: () => context.go(AppRoutes.localsendDiscovery),
)
```

## Регистрация провайдеров

Убедитесь, что все провайдеры LocalSend зарегистрированы в вашем основном файле providers:

```dart
// lib/providers/app_providers.dart

// LocalSend providers
export 'package:hoplixi/features/localsend/providers/discovery_provider.dart';
export 'package:hoplixi/features/localsend/providers/webrtc_provider.dart';
export 'package:hoplixi/features/localsend/providers/message_provider.dart';
```

## Разрешения

### Android (android/app/src/main/AndroidManifest.xml)

Добавьте необходимые разрешения:

```xml
<!-- Сеть и интернет -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />

<!-- Хранилище файлов -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />

<!-- Для mDNS обнаружения -->
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />

<!-- Для уведомлений -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### Windows

Убедитесь, что в windows/runner/main.cpp включена поддержка сети:

```cpp
// Для WebRTC и HTTP сервера
#pragma comment(lib, "ws2_32.lib")
#pragma comment(lib, "winmm.lib")
```

## Зависимости

Убедитесь, что все необходимые пакеты добавлены в pubspec.yaml:

```yaml
dependencies:
  flutter_webrtc: ^0.9.48
  bonsoir: ^4.1.1
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  http: ^1.1.0
  
  # Уже должны быть в проекте
  riverpod_annotation: ^2.3.3
  flutter_riverpod: ^2.4.9
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
```

## Инициализация сервисов

В main.dart убедитесь, что WebRTC инициализирован:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация WebRTC
  await WebRTC.initialize();
  
  runApp(
    ProviderScope(
      child: HoplixiApp(),
    ),
  );
}
```

## Настройки темы

LocalSend использует стандартную тему приложения, но вы можете кастомизировать цвета:

```dart
// В theme/colors.dart можете добавить специфичные цвета
static const Color successColor = Color(0xFF4CAF50);
static const Color warningColor = Color(0xFFFF9800);
static const Color errorColor = Color(0xFFE53E3E);
```

## Тестирование интеграции

### 1. Базовая функциональность

- Запустите приложение на двух устройствах в одной Wi-Fi сети
- Откройте LocalSend на обоих устройствах
- Убедитесь, что устройства видят друг друга
- Протестируйте отправку файлов и сообщений

### 2. Обработка ошибок

- Протестируйте поведение при отключении Wi-Fi
- Убедитесь, что ошибки отображаются через ToastHelper
- Проверьте корректность логирования в app_logger

### 3. UI/UX

- Проверьте адаптивность на разных размерах экранов
- Убедитесь, что анимации плавные
- Протестируйте тёмную/светлую тему

## Потенциальные проблемы

### 1. Конфликты портов

Если порт 8080 уже используется, HttpSignalingService автоматически найдёт свободный порт от 8080 до 8090.

### 2. Разрешения на файлы

На Android 11+ могут потребоваться дополнительные разрешения для доступа к файлам. Используйте permission_handler для динамических запросов.

### 3. Firewall

На Windows Defender может заблокировать HTTP сервер. Добавьте исключение или используйте другой порт.

### 4. NAT/Firewall

Для работы через сложные сети может потребоваться настройка TURN серверов в webrtc_config.dart.

## Дополнительные улучшения

1. **Сохранение истории**: Интегрируйте с SQLite для сохранения истории сообщений
2. **Уведомления**: Добавьте push-уведомления о входящих файлах
3. **Настройки**: Создайте экран настроек для конфигурации LocalSend
4. **Статистика**: Добавьте счетчики переданных файлов и сообщений

Фича готова к использованию и полностью интегрируется с архитектурой Hoplixi!