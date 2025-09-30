import 'notification_service.dart';
import '../logger/app_logger.dart';
import '../utils/toastification.dart';

/// Хелперы для удобной работы с уведомлениями
class NotificationHelpers {
  NotificationHelpers._();

  /// Показать уведомление о безопасности
  static Future<void> showSecurityAlert({
    required String title,
    required String message,
    String? payload,
  }) async {
    await NotificationService.instance.showNotification(
      title: title,
      body: message,
      channel: NotificationChannel.security,
      importance: NotificationImportance.urgent,
      payload: payload,
    );

    logInfo(
      'Отправлено уведомление безопасности: $title',
      tag: 'NotificationHelpers',
    );
  }

  /// Показать уведомление о неуспешной попытке входа
  static Future<void> showFailedLoginAttempt({
    String? deviceInfo,
    DateTime? attemptTime,
  }) async {
    final String body = deviceInfo != null
        ? 'Неуспешная попытка входа с устройства: $deviceInfo'
        : 'Обнаружена неуспешная попытка входа в систему';

    await showSecurityAlert(
      title: 'Предупреждение безопасности',
      message: body,
      payload:
          'failed_login_${attemptTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Показать уведомление об успешном входе с нового устройства
  static Future<void> showNewDeviceLogin({required String deviceInfo}) async {
    await showSecurityAlert(
      title: 'Вход с нового устройства',
      message:
          'Выполнен вход с устройства: $deviceInfo. Если это были не вы, немедленно смените мастер-пароль.',
      payload: 'new_device_login_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Показать уведомление о копировании TOTP кода
  static Future<void> showTotpCodeCopied({
    required String issuer,
    required String accountName,
  }) async {
    await NotificationService.instance.showNotification(
      title: 'TOTP код скопирован',
      body: '$issuer ($accountName)',
      channel: NotificationChannel.totp,
      importance: NotificationImportance.low,
      payload: 'totp_copied_${issuer}_$accountName',
    );
  }

  /// Показать уведомление о копировании пароля
  static Future<void> showPasswordCopied({required String siteName}) async {
    await NotificationService.instance.showNotification(
      title: 'Пароль скопирован',
      body: 'Пароль для $siteName скопирован в буфер обмена',
      channel: NotificationChannel.general,
      importance: NotificationImportance.low,
      payload: 'password_copied_$siteName',
    );
  }

  /// Показать уведомление об истечении срока действия пароля
  static Future<void> showPasswordExpiring({
    required String siteName,
    required int daysLeft,
  }) async {
    final String body = daysLeft == 0
        ? 'Пароль для $siteName истек сегодня'
        : 'Пароль для $siteName истекает через $daysLeft дн.';

    await NotificationService.instance.showNotificationWithActions(
      title: 'Требуется смена пароля',
      body: body,
      actions: [
        const NotificationAction(
          id: 'change_password',
          title: 'Сменить пароль',
          showsUserInterface: true,
        ),
        const NotificationAction(id: 'remind_later', title: 'Напомнить позже'),
      ],
      channel: NotificationChannel.security,
      importance: daysLeft == 0
          ? NotificationImportance.urgent
          : NotificationImportance.high,
      payload: 'password_expiring_$siteName',
    );
  }

  /// Показать уведомление о резервном копировании
  static Future<void> showBackupCompleted({
    required String backupPath,
    required int passwordCount,
  }) async {
    await NotificationService.instance.showNotification(
      title: 'Резервная копия создана',
      body: 'Сохранено $passwordCount паролей в $backupPath',
      channel: NotificationChannel.general,
      importance: NotificationImportance.normal,
      payload: 'backup_completed_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Показать уведомление об ошибке резервного копирования
  static Future<void> showBackupFailed({required String error}) async {
    await NotificationService.instance.showNotificationWithActions(
      title: 'Ошибка резервного копирования',
      body: 'Не удалось создать резервную копию: $error',
      actions: [
        const NotificationAction(
          id: 'retry_backup',
          title: 'Повторить',
          showsUserInterface: true,
        ),
        const NotificationAction(
          id: 'view_error',
          title: 'Подробности',
          showsUserInterface: true,
        ),
      ],
      channel: NotificationChannel.security,
      importance: NotificationImportance.high,
      payload: 'backup_failed_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Запланировать напоминание о смене пароля
  static Future<void> schedulePasswordChangeReminder({
    required String siteName,
    required DateTime reminderTime,
  }) async {
    await NotificationService.instance.scheduleNotification(
      title: 'Напоминание о смене пароля',
      body: 'Пора сменить пароль для $siteName',
      scheduledTime: reminderTime,
      channel: NotificationChannel.security,
      importance: NotificationImportance.normal,
      payload: 'password_reminder_$siteName',
    );

    logInfo(
      'Запланировано напоминание о смене пароля для $siteName на ${reminderTime.toIso8601String()}',
      tag: 'NotificationHelpers',
    );
  }

  /// Запланировать напоминание о резервном копировании
  static Future<void> scheduleBackupReminder({
    required DateTime reminderTime,
  }) async {
    await NotificationService.instance.scheduleNotification(
      title: 'Время создать резервную копию',
      body: 'Рекомендуется регулярно создавать резервные копии ваших паролей',
      scheduledTime: reminderTime,
      channel: NotificationChannel.general,
      importance: NotificationImportance.normal,
      payload: 'backup_reminder_${reminderTime.millisecondsSinceEpoch}',
    );

    logInfo(
      'Запланировано напоминание о резервном копировании на ${reminderTime.toIso8601String()}',
      tag: 'NotificationHelpers',
    );
  }

  /// Инициализация сервиса уведомлений с проверкой разрешений
  static Future<bool> initializeWithPermissions() async {
    try {
      // Инициализируем сервис
      final bool initialized = await NotificationService.instance.initialize();
      if (!initialized) {
        logError(
          'Не удалось инициализировать сервис уведомлений',
          tag: 'NotificationHelpers',
        );
        return false;
      }

      // Запрашиваем разрешения
      final bool permissionsGranted = await NotificationService.instance
          .requestPermissions();
      if (!permissionsGranted) {
        logWarning(
          'Разрешения на уведомления не предоставлены',
          tag: 'NotificationHelpers',
        );
        ToastHelper.warning(
          title: 'Уведомления отключены',
          description:
              'Для получения важных уведомлений безопасности включите разрешения в настройках',
        );
        return false;
      }

      // Проверяем статус уведомлений
      final bool enabled = await NotificationService.instance
          .areNotificationsEnabled();
      if (!enabled) {
        logWarning(
          'Уведомления отключены в системе',
          tag: 'NotificationHelpers',
        );
        ToastHelper.info(
          title: 'Уведомления отключены',
          description:
              'Включите уведомления в настройках устройства для получения важных уведомлений',
        );
      }

      logInfo(
        'Сервис уведомлений успешно инициализирован',
        tag: 'NotificationHelpers',
      );
      return true;
    } catch (e, stackTrace) {
      logError(
        'Ошибка инициализации сервиса уведомлений: $e',
        tag: 'NotificationHelpers',
        stackTrace: stackTrace,
      );
      ToastHelper.error(
        title: 'Ошибка уведомлений',
        description: 'Не удалось инициализировать систему уведомлений',
      );
      return false;
    }
  }

  /// Показать тестовое уведомление
  static Future<void> showTestNotification() async {
    await NotificationService.instance.showNotification(
      title: 'Тестовое уведомление',
      body: 'Система уведомлений Hoplixi работает корректно',
      channel: NotificationChannel.general,
      importance: NotificationImportance.normal,
      payload: 'test_notification',
    );
  }
}
