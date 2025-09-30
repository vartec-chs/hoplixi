import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../global/widgets/button.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/utils/toastification.dart';
import '../../../core/logger/app_logger.dart';

/// Виджет настроек уведомлений
class NotificationSettingsWidget extends ConsumerStatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  ConsumerState<NotificationSettingsWidget> createState() =>
      _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState
    extends ConsumerState<NotificationSettingsWidget> {
  @override
  Widget build(BuildContext context) {
    final notificationInit = ref.watch(notificationInitializationProvider);
    final notificationPermissions = ref.watch(notificationPermissionsProvider);
    final notificationState = ref.watch(notificationProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Настройки уведомлений',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Статус инициализации
            _buildInitializationStatus(notificationInit),
            const SizedBox(height: 12),

            // Статус разрешений
            _buildPermissionsStatus(notificationPermissions),
            const SizedBox(height: 16),

            // Статистика уведомлений
            _buildNotificationStats(notificationState),
            const SizedBox(height: 16),

            // Кнопки управления
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitializationStatus(AsyncValue<bool> notificationInit) {
    return Row(
      children: [
        Icon(
          notificationInit.when(
            data: (initialized) =>
                initialized ? Icons.check_circle : Icons.error,
            loading: () => Icons.hourglass_empty,
            error: (_, __) => Icons.error,
          ),
          color: notificationInit.when(
            data: (initialized) => initialized ? Colors.green : Colors.red,
            loading: () => Colors.orange,
            error: (_, __) => Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          notificationInit.when(
            data: (initialized) => initialized
                ? 'Система уведомлений инициализирована'
                : 'Система уведомлений не инициализирована',
            loading: () => 'Инициализация системы уведомлений...',
            error: (error, _) => 'Ошибка инициализации: $error',
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsStatus(AsyncValue<bool> notificationPermissions) {
    return Row(
      children: [
        Icon(
          notificationPermissions.when(
            data: (granted) =>
                granted ? Icons.notifications_active : Icons.notifications_off,
            loading: () => Icons.hourglass_empty,
            error: (_, __) => Icons.error,
          ),
          color: notificationPermissions.when(
            data: (granted) => granted ? Colors.green : Colors.orange,
            loading: () => Colors.grey,
            error: (_, __) => Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          notificationPermissions.when(
            data: (granted) =>
                granted ? 'Уведомления разрешены' : 'Уведомления отключены',
            loading: () => 'Проверка разрешений...',
            error: (error, _) => 'Ошибка проверки разрешений: $error',
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationStats(NotificationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статистика уведомлений',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (state.lastNotificationTime != null)
          Text(
            'Последнее уведомление: ${_formatDateTime(state.lastNotificationTime!)}',
          ),
        if (state.lastCopiedPassword != null)
          Text('Последний скопированный пароль: ${state.lastCopiedPassword}'),
        if (state.lastCopiedTotp != null)
          Text('Последний скопированный TOTP: ${state.lastCopiedTotp}'),
        Text('Запланированных напоминаний: ${state.scheduledRemindersCount}'),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SmoothButton(
          label: 'Тестовое уведомление',
          type: SmoothButtonType.filled,
          size: SmoothButtonSize.medium,
          onPressed: _showTestNotification,
        ),
        SmoothButton(
          label: 'Запросить разрешения',
          type: SmoothButtonType.tonal,
          size: SmoothButtonSize.medium,
          onPressed: _requestPermissions,
        ),
        SmoothButton(
          label: 'Отменить все',
          type: SmoothButtonType.outlined,
          size: SmoothButtonSize.medium,
          onPressed: _cancelAllNotifications,
        ),
        SmoothButton(
          label: 'Обновить статус',
          type: SmoothButtonType.text,
          size: SmoothButtonSize.medium,
          onPressed: _refreshStatus,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showTestNotification() async {
    try {
      await ref.read(notificationProvider.notifier).showTestNotification();
      ToastHelper.success(
        title: 'Тестовое уведомление отправлено',
        description: 'Проверьте панель уведомлений устройства',
      );
    } catch (e) {
      logError(
        'Ошибка отправки тестового уведомления: $e',
        tag: 'NotificationSettings',
      );
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось отправить тестовое уведомление',
      );
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final service = ref.read(notificationServiceProvider);
      final granted = await service.requestPermissions();

      if (granted) {
        ToastHelper.success(
          title: 'Разрешения получены',
          description: 'Уведомления теперь доступны',
        );
      } else {
        ToastHelper.warning(
          title: 'Разрешения отклонены',
          description: 'Включите уведомления в настройках устройства',
        );
      }

      // Обновляем статус разрешений
      ref.invalidate(notificationPermissionsProvider);
    } catch (e) {
      logError('Ошибка запроса разрешений: $e', tag: 'NotificationSettings');
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось запросить разрешения',
      );
    }
  }

  Future<void> _cancelAllNotifications() async {
    try {
      await ref.read(notificationProvider.notifier).cancelAllNotifications();
      ToastHelper.success(
        title: 'Уведомления отменены',
        description: 'Все запланированные уведомления отменены',
      );
    } catch (e) {
      logError('Ошибка отмены уведомлений: $e', tag: 'NotificationSettings');
      ToastHelper.error(
        title: 'Ошибка',
        description: 'Не удалось отменить уведомления',
      );
    }
  }

  void _refreshStatus() {
    ref.invalidate(notificationInitializationProvider);
    ref.invalidate(notificationPermissionsProvider);
    ToastHelper.info(
      title: 'Статус обновлен',
      description: 'Информация о состоянии уведомлений обновлена',
    );
  }
}

/// Пример использования уведомлений в других частях приложения
class NotificationExampleWidget extends ConsumerWidget {
  const NotificationExampleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Примеры уведомлений',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SmoothButton(
                  label: 'Уведомление безопасности',
                  type: SmoothButtonType.filled,
                  size: SmoothButtonSize.medium,
                  onPressed: () => _showSecurityAlert(ref),
                ),
                SmoothButton(
                  label: 'Пароль скопирован',
                  type: SmoothButtonType.tonal,
                  size: SmoothButtonSize.medium,
                  onPressed: () => _showPasswordCopied(ref),
                ),
                SmoothButton(
                  label: 'TOTP скопирован',
                  type: SmoothButtonType.tonal,
                  size: SmoothButtonSize.medium,
                  onPressed: () => _showTotpCopied(ref),
                ),
                SmoothButton(
                  label: 'Напоминание через 10 сек',
                  type: SmoothButtonType.outlined,
                  size: SmoothButtonSize.medium,
                  onPressed: () => _scheduleReminder(ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSecurityAlert(WidgetRef ref) async {
    await ref
        .read(notificationProvider.notifier)
        .showSecurityAlert(
          'Предупреждение безопасности',
          'Обнаружена подозрительная активность в вашем аккаунте',
        );
  }

  Future<void> _showPasswordCopied(WidgetRef ref) async {
    await ref
        .read(notificationProvider.notifier)
        .showPasswordCopied('example.com');
  }

  Future<void> _showTotpCopied(WidgetRef ref) async {
    await ref
        .read(notificationProvider.notifier)
        .showTotpCodeCopied('Google', 'user@example.com');
  }

  Future<void> _scheduleReminder(WidgetRef ref) async {
    final reminderTime = DateTime.now().add(const Duration(seconds: 10));
    await ref
        .read(notificationProvider.notifier)
        .schedulePasswordReminder('example.com', reminderTime);
  }
}
