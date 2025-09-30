import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../global/widgets/button.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/services/notification_helpers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/providers/notification_providers.dart';

/// Демо-экран для тестирования системы уведомлений
class NotificationDemoScreen extends ConsumerWidget {
  const NotificationDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final notificationNotifier = ref.read(notificationProvider.notifier);
    final initializationAsync = ref.watch(notificationInitializationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Демо уведомлений'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Статус инициализации
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус системы уведомлений',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    initializationAsync.when(
                      data: (isInitialized) => Row(
                        children: [
                          Icon(
                            isInitialized ? Icons.check_circle : Icons.error,
                            color: isInitialized ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isInitialized
                                ? 'Инициализировано'
                                : 'Не инициализировано',
                          ),
                        ],
                      ),
                      loading: () => const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Инициализация...'),
                        ],
                      ),
                      error: (error, _) => Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ошибка: $error',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (notificationState.lastNotificationTime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Последнее уведомление: ${notificationState.lastNotificationTime!.toLocal()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Кнопки для тестирования основных функций
            Text(
              'Основные уведомления',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Простое уведомление',
              onPressed: () => _showSimpleNotification(),
              type: SmoothButtonType.filled,
              size: SmoothButtonSize.medium,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Важное уведомление',
              onPressed: () => _showImportantNotification(),
              type: SmoothButtonType.outlined,
              size: SmoothButtonSize.medium,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Уведомление с действиями',
              onPressed: () => _showNotificationWithActions(),
              type: SmoothButtonType.tonal,
              size: SmoothButtonSize.medium,
            ),
            const SizedBox(height: 16),

            // Кнопки для тестирования помощников
            Text(
              'Специализированные уведомления',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Уведомление безопасности',
              onPressed: () => _showSecurityAlert(),
              type: SmoothButtonType.filled,
              size: SmoothButtonSize.medium,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Пароль скопирован',
              onPressed: () => _showPasswordCopied(),
              type: SmoothButtonType.outlined,
              size: SmoothButtonSize.medium,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'TOTP код скопирован',
              onPressed: () => _showTotpCopied(),
              type: SmoothButtonType.tonal,
              size: SmoothButtonSize.medium,
            ),
            const SizedBox(height: 16),

            // Планируемые уведомления
            Text(
              'Планируемые уведомления',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Уведомление через 5 секунд',
              onPressed: () => _scheduleNotification(),
              type: SmoothButtonType.filled,
              size: SmoothButtonSize.medium,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Напоминание о смене пароля',
              onPressed: () => _schedulePasswordReminder(),
              type: SmoothButtonType.outlined,
              size: SmoothButtonSize.medium,
            ),
            const SizedBox(height: 16),

            // Управление уведомлениями
            Text('Управление', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Запросить разрешения',
              onPressed: () => _requestPermissions(),
              type: SmoothButtonType.tonal,
              size: SmoothButtonSize.medium,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              label: 'Отменить все уведомления',
              onPressed: () => _cancelAllNotifications(),
              type: SmoothButtonType.outlined,
              size: SmoothButtonSize.medium,
            ),
          ],
        ),
      ),
    );
  }

  void _showSimpleNotification() {
    NotificationService.instance.showNotification(
      title: 'Простое уведомление',
      body: 'Это обычное уведомление для тестирования',
      payload: 'simple_notification',
    );
    logInfo('Отправлено простое уведомление', tag: 'NotificationDemo');
  }

  void _showImportantNotification() {
    NotificationService.instance.showNotification(
      title: 'Важное уведомление!',
      body: 'Это важное уведомление с высоким приоритетом',
      channel: NotificationChannel.security,
      importance: NotificationImportance.high,
      payload: 'important_notification',
    );
    logInfo('Отправлено важное уведомление', tag: 'NotificationDemo');
  }

  void _showNotificationWithActions() {
    NotificationService.instance.showNotificationWithActions(
      title: 'Уведомление с действиями',
      body: 'Нажмите на одну из кнопок ниже',
      actions: [
        const NotificationAction(id: 'action_1', title: 'Действие 1'),
        const NotificationAction(
          id: 'action_2',
          title: 'Действие 2',
          showsUserInterface: true,
        ),
      ],
      payload: 'notification_with_actions',
    );
    logInfo('Отправлено уведомление с действиями', tag: 'NotificationDemo');
  }

  void _showSecurityAlert() {
    NotificationHelpers.showSecurityAlert(
      title: 'Подозрительная активность',
      message:
          'Обнаружена попытка несанкционированного доступа к вашему хранилищу паролей',
    );
    logInfo('Отправлено уведомление безопасности', tag: 'NotificationDemo');
  }

  void _showPasswordCopied() {
    NotificationHelpers.showPasswordCopied(siteName: 'github.com');
    logInfo(
      'Отправлено уведомление о копировании пароля',
      tag: 'NotificationDemo',
    );
  }

  void _showTotpCopied() {
    NotificationHelpers.showTotpCodeCopied(
      issuer: 'Google',
      accountName: 'testuser@example.com',
    );
    logInfo(
      'Отправлено уведомление о копировании TOTP кода',
      tag: 'NotificationDemo',
    );
  }

  void _scheduleNotification() {
    final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
    NotificationService.instance.scheduleNotification(
      title: 'Запланированное уведомление',
      body: 'Это уведомление было запланировано на ${scheduledTime.toLocal()}',
      scheduledTime: scheduledTime,
      payload: 'scheduled_notification',
    );
    logInfo(
      'Запланировано уведомление на $scheduledTime',
      tag: 'NotificationDemo',
    );
  }

  void _schedulePasswordReminder() {
    final reminderTime = DateTime.now().add(const Duration(seconds: 10));
    NotificationHelpers.schedulePasswordChangeReminder(
      siteName: 'example.com',
      reminderTime: reminderTime,
    );
    logInfo(
      'Запланировано напоминание о смене пароля на $reminderTime',
      tag: 'NotificationDemo',
    );
  }

  void _requestPermissions() async {
    final granted = await NotificationService.instance.requestPermissions();
    logInfo('Результат запроса разрешений: $granted', tag: 'NotificationDemo');

    if (granted) {
      NotificationService.instance.showNotification(
        title: 'Разрешения получены',
        body: 'Уведомления теперь доступны!',
        importance: NotificationImportance.normal,
      );
    }
  }

  void _cancelAllNotifications() {
    NotificationService.instance.cancelAllNotifications();
    logInfo('Все уведомления отменены', tag: 'NotificationDemo');
  }
}
