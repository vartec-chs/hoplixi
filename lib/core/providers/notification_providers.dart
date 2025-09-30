import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../services/notification_helpers.dart';
import '../logger/app_logger.dart';

/// Провайдер для сервиса уведомлений
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

/// Провайдер для состояния инициализации уведомлений
final notificationInitializationProvider = FutureProvider<bool>((ref) async {
  try {
    logInfo('Инициализация системы уведомлений', tag: 'NotificationProvider');
    return await NotificationHelpers.initializeWithPermissions();
  } catch (e, stackTrace) {
    logError(
      'Ошибка инициализации уведомлений: $e',
      tag: 'NotificationProvider',
      stackTrace: stackTrace,
    );
    return false;
  }
});

/// Провайдер для проверки статуса разрешений уведомлений
final notificationPermissionsProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(notificationServiceProvider);
  try {
    return await service.areNotificationsEnabled();
  } catch (e, stackTrace) {
    logError(
      'Ошибка проверки разрешений уведомлений: $e',
      tag: 'NotificationProvider',
      stackTrace: stackTrace,
    );
    return false;
  }
});

/// Провайдер для управления уведомлениями
class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    return const NotificationState();
  }

  /// Показать уведомление о безопасности
  Future<void> showSecurityAlert(String title, String message) async {
    try {
      await NotificationHelpers.showSecurityAlert(
        title: title,
        message: message,
      );
      state = state.copyWith(lastNotificationTime: DateTime.now());
    } catch (e, stackTrace) {
      logError(
        'Ошибка отправки уведомления безопасности: $e',
        tag: 'NotificationNotifier',
        stackTrace: stackTrace,
      );
    }
  }

  /// Показать уведомление о копировании пароля
  Future<void> showPasswordCopied(String siteName) async {
    try {
      await NotificationHelpers.showPasswordCopied(siteName: siteName);
      state = state.copyWith(
        lastNotificationTime: DateTime.now(),
        lastCopiedPassword: siteName,
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка уведомления о копировании пароля: $e',
        tag: 'NotificationNotifier',
        stackTrace: stackTrace,
      );
    }
  }

  /// Показать уведомление о копировании TOTP кода
  Future<void> showTotpCodeCopied(String issuer, String accountName) async {
    try {
      await NotificationHelpers.showTotpCodeCopied(
        issuer: issuer,
        accountName: accountName,
      );
      state = state.copyWith(
        lastNotificationTime: DateTime.now(),
        lastCopiedTotp: '$issuer ($accountName)',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка уведомления о копировании TOTP: $e',
        tag: 'NotificationNotifier',
        stackTrace: stackTrace,
      );
    }
  }

  /// Запланировать напоминание о смене пароля
  Future<void> schedulePasswordReminder(
    String siteName,
    DateTime reminderTime,
  ) async {
    try {
      await NotificationHelpers.schedulePasswordChangeReminder(
        siteName: siteName,
        reminderTime: reminderTime,
      );
      state = state.copyWith(
        scheduledRemindersCount: state.scheduledRemindersCount + 1,
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка планирования напоминания: $e',
        tag: 'NotificationNotifier',
        stackTrace: stackTrace,
      );
    }
  }

  /// Показать тестовое уведомление
  Future<void> showTestNotification() async {
    try {
      await NotificationHelpers.showTestNotification();
      state = state.copyWith(lastNotificationTime: DateTime.now());
    } catch (e, stackTrace) {
      logError(
        'Ошибка тестового уведомления: $e',
        tag: 'NotificationNotifier',
        stackTrace: stackTrace,
      );
    }
  }

  /// Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    try {
      final service = ref.read(notificationServiceProvider);
      await service.cancelAllNotifications();
      state = state.copyWith(scheduledRemindersCount: 0);
      logInfo('Все уведомления отменены', tag: 'NotificationNotifier');
    } catch (e, stackTrace) {
      logError(
        'Ошибка отмены уведомлений: $e',
        tag: 'NotificationNotifier',
        stackTrace: stackTrace,
      );
    }
  }
}

/// Провайдер для нотифаера управления уведомлениями
final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(() {
      return NotificationNotifier();
    });

/// Состояние системы уведомлений
class NotificationState {
  final DateTime? lastNotificationTime;
  final String? lastCopiedPassword;
  final String? lastCopiedTotp;
  final int scheduledRemindersCount;

  const NotificationState({
    this.lastNotificationTime,
    this.lastCopiedPassword,
    this.lastCopiedTotp,
    this.scheduledRemindersCount = 0,
  });

  NotificationState copyWith({
    DateTime? lastNotificationTime,
    String? lastCopiedPassword,
    String? lastCopiedTotp,
    int? scheduledRemindersCount,
  }) {
    return NotificationState(
      lastNotificationTime: lastNotificationTime ?? this.lastNotificationTime,
      lastCopiedPassword: lastCopiedPassword ?? this.lastCopiedPassword,
      lastCopiedTotp: lastCopiedTotp ?? this.lastCopiedTotp,
      scheduledRemindersCount:
          scheduledRemindersCount ?? this.scheduledRemindersCount,
    );
  }
}
