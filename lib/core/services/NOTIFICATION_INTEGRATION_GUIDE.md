# Интеграция flutter_local_notifications в Hoplixi

Система уведомлений полностью интегрирована в архитектуру проекта Hoplixi и готова к использованию.

## Структура интеграции

### 1. Основные файлы

- `lib/core/services/notification_service.dart` - Основной сервис для работы с уведомлениями
- `lib/core/services/notification_helpers.dart` - Вспомогательные методы для удобного использования
- `lib/core/providers/notification_providers.dart` - Riverpod провайдеры для управления состоянием
- `lib/features/settings/widgets/notification_settings_widget.dart` - Виджет настроек уведомлений

### 2. Зависимости в pubspec.yaml

```yaml
dependencies:
  flutter_local_notifications: ^19.4.2
  timezone: ^0.9.4
  flutter_timezone: ^2.1.0
```

## Использование

### Инициализация

Система уведомлений автоматически инициализируется в `main.dart`:

```dart
// Инициализация происходит автоматически при запуске приложения
await NotificationHelpers.initializeWithPermissions();
```

### Основные типы уведомлений

#### 1. Уведомления безопасности

```dart
// Неуспешная попытка входа
await NotificationHelpers.showFailedLoginAttempt(
  deviceInfo: 'Windows PC (192.168.1.100)',
  attemptTime: DateTime.now(),
);

// Вход с нового устройства
await NotificationHelpers.showNewDeviceLogin(
  deviceInfo: 'iPhone 14 Pro',
);

// Общее уведомление безопасности
await NotificationHelpers.showSecurityAlert(
  title: 'Важное уведомление',
  message: 'Обнаружена подозрительная активность',
);
```

#### 2. Уведомления о действиях пользователя

```dart
// Копирование пароля
await NotificationHelpers.showPasswordCopied(siteName: 'google.com');

// Копирование TOTP кода
await NotificationHelpers.showTotpCodeCopied(
  issuer: 'Google',
  accountName: 'user@example.com',
);
```

#### 3. Уведомления о паролях

```dart
// Истечение срока действия пароля
await NotificationHelpers.showPasswordExpiring(
  siteName: 'github.com',
  daysLeft: 5,
);

// Планирование напоминания
await NotificationHelpers.schedulePasswordChangeReminder(
  siteName: 'facebook.com',
  reminderTime: DateTime.now().add(Duration(days: 30)),
);
```

#### 4. Уведомления о резервном копировании

```dart
// Успешное создание резервной копии
await NotificationHelpers.showBackupCompleted(
  backupPath: 'Documents/Hoplixi/backup_2024.json',
  passwordCount: 150,
);

// Ошибка резервного копирования
await NotificationHelpers.showBackupFailed(
  error: 'Недостаточно места на диске',
);
```

### Использование с Riverpod

#### В виджетах

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Использование через провайдер
        await ref.read(notificationProvider.notifier).showPasswordCopied('example.com');
      },
      child: Text('Скопировать пароль'),
    );
  }
}
```

#### Проверка статуса уведомлений

```dart
class NotificationStatusWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initStatus = ref.watch(notificationInitializationProvider);
    final permissions = ref.watch(notificationPermissionsProvider);
    
    return initStatus.when(
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка: $error'),
      data: (initialized) {
        if (!initialized) {
          return Text('Уведомления не инициализированы');
        }
        
        return permissions.when(
          loading: () => Text('Проверка разрешений...'),
          error: (error, stack) => Text('Ошибка разрешений: $error'),
          data: (granted) => Text(
            granted ? 'Уведомления включены' : 'Уведомления отключены'
          ),
        );
      },
    );
  }
}
```

### Каналы уведомлений

Система использует три канала уведомлений:

1. **General** (`hoplixi_default`) - Общие уведомления
2. **Security** (`hoplixi_important`) - Уведомления безопасности (высокий приоритет)
3. **TOTP** (`hoplixi_totp`) - Уведомления о TOTP кодах (низкий приоритет, без звука)

### Уровни важности

- **Low** - Тихие уведомления без вибрации
- **Normal** - Стандартные уведомления
- **High** - Важные уведомления с вибрацией и светом
- **Urgent** - Критически важные уведомления (максимальный приоритет)

## Настройки и конфигурация

### Виджет настроек

Добавьте `NotificationSettingsWidget` в настройки приложения:

```dart
import 'package:hoplixi/features/settings/widgets/notification_settings_widget.dart';

// В экране настроек
Column(
  children: [
    NotificationSettingsWidget(),
    NotificationExampleWidget(), // Для демонстрации
  ],
)
```

### Проверка разрешений

```dart
// Проверка состояния разрешений
final service = NotificationService.instance;
final enabled = await service.areNotificationsEnabled();

if (!enabled) {
  // Запрос разрешений
  final granted = await service.requestPermissions();
}
```

## Интеграция в существующие сервисы

### В сервисе паролей

```dart
// В password_service.dart
class PasswordService {
  Future<ServiceResult<String>> copyPassword(String passwordId) async {
    try {
      // Логика копирования пароля
      final password = await _getPassword(passwordId);
      await Clipboard.setData(ClipboardData(text: password.decryptedPassword));
      
      // Уведомление о копировании
      await NotificationHelpers.showPasswordCopied(siteName: password.title);
      
      return ServiceResult.success(data: passwordId);
    } catch (e) {
      return ServiceResult.error('Ошибка копирования пароля');
    }
  }
}
```

### В сервисе TOTP

```dart
// В totp_service.dart
class TOTPService {
  Future<ServiceResult<String>> copyTotpCode(String totpId) async {
    try {
      // Логика генерации и копирования TOTP
      final totp = await _getTotpById(totpId);
      final code = _generateCode(totp);
      await Clipboard.setData(ClipboardData(text: code));
      
      // Уведомление о копировании
      await NotificationHelpers.showTotpCodeCopied(
        issuer: totp.issuer,
        accountName: totp.accountName,
      );
      
      return ServiceResult.success(data: code);
    } catch (e) {
      return ServiceResult.error('Ошибка генерации TOTP кода');
    }
  }
}
```

## Планирование уведомлений

### Напоминания о смене паролей

```dart
// Планирование напоминания через 30 дней
final reminderTime = DateTime.now().add(Duration(days: 30));
await NotificationHelpers.schedulePasswordChangeReminder(
  siteName: 'example.com',
  reminderTime: reminderTime,
);
```

### Регулярные напоминания о резервном копировании

```dart
// Еженедельные напоминания
final nextBackup = DateTime.now().add(Duration(days: 7));
await NotificationHelpers.scheduleBackupReminder(reminderTime: nextBackup);
```

## Отладка и тестирование

### Тестовое уведомление

```dart
// Отправка тестового уведомления
await NotificationHelpers.showTestNotification();
```

### Отмена всех уведомлений

```dart
// Отмена всех запланированных уведомлений
final service = NotificationService.instance;
await service.cancelAllNotifications();
```

### Получение списка запланированных уведомлений

```dart
final service = NotificationService.instance;
final pending = await service.getPendingNotifications();
print('Запланировано уведомлений: ${pending.length}');
```

## Поддерживаемые платформы

- ✅ **Android** - Полная поддержка с каналами уведомлений
- ✅ **iOS/macOS** - Поддержка с категориями действий
- ✅ **Windows** - Поддержка через WinRT
- ✅ **Linux** - Поддержка через D-Bus
- ❌ **Web** - Отключена в проекте

## Логирование

Все операции с уведомлениями логируются через `AppLogger`:

```dart
logInfo('Отправлено уведомление: $title', tag: 'NotificationService');
logWarning('Разрешения на уведомления отклонены', tag: 'NotificationService');
logError('Ошибка отправки уведомления: $e', tag: 'NotificationService');
```

## Обработка ошибок

Система уведомлений следует архитектуре Hoplixi и не выбрасывает исключения наружу. Все ошибки логируются и обрабатываются корректно:

```dart
try {
  await NotificationHelpers.showSecurityAlert(title: 'Test', message: 'Test');
} catch (e) {
  // Этот блок не будет выполнен - ошибки обрабатываются внутри
}
```

## Производительность

- Минимальное потребление ресурсов
- Асинхронная обработка всех операций
- Кэширование статуса разрешений
- Автоматическая очистка устаревших уведомлений

Система уведомлений готова к использованию и полностью интегрирована в архитектуру Hoplixi!