import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/button.dart';
import '../../core/providers/notification_providers.dart';

/// Простой пример использования системы уведомлений Hoplixi
class NotificationDemoScreen extends ConsumerWidget {
  const NotificationDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final initStatus = ref.watch(notificationInitializationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Демо уведомлений')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Статус системы
            _buildStatusCard(initStatus),
            const SizedBox(height: 16),

            // Статистика
            _buildStatsCard(notificationState),
            const SizedBox(height: 16),

            // Кнопки демонстрации
            const Text(
              'Примеры уведомлений:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SmoothButton(
                  label: 'Пароль скопирован',
                  type: SmoothButtonType.filled,
                  onPressed: () => _showPasswordCopied(ref),
                ),
                SmoothButton(
                  label: 'TOTP скопирован',
                  type: SmoothButtonType.tonal,
                  onPressed: () => _showTotpCopied(ref),
                ),
                SmoothButton(
                  label: 'Предупреждение безопасности',
                  type: SmoothButtonType.filled,
                  onPressed: () => _showSecurityAlert(ref),
                ),
                SmoothButton(
                  label: 'Планировать напоминание',
                  type: SmoothButtonType.outlined,
                  onPressed: () => _scheduleReminder(ref),
                ),
                SmoothButton(
                  label: 'Тест уведомлений',
                  type: SmoothButtonType.text,
                  onPressed: () => _showTestNotification(ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AsyncValue<bool> initStatus) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              initStatus.when(
                data: (initialized) =>
                    initialized ? Icons.check_circle : Icons.error,
                loading: () => Icons.hourglass_empty,
                error: (_, __) => Icons.error,
              ),
              color: initStatus.when(
                data: (initialized) => initialized ? Colors.green : Colors.red,
                loading: () => Colors.orange,
                error: (_, __) => Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                initStatus.when(
                  data: (initialized) => initialized
                      ? 'Система уведомлений активна'
                      : 'Система уведомлений недоступна',
                  loading: () => 'Инициализация...',
                  error: (error, _) => 'Ошибка: $error',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(NotificationState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (state.lastNotificationTime != null)
              Text('Последнее: ${_formatTime(state.lastNotificationTime!)}'),
            if (state.lastCopiedPassword != null)
              Text('Последний пароль: ${state.lastCopiedPassword}'),
            if (state.lastCopiedTotp != null)
              Text('Последний TOTP: ${state.lastCopiedTotp}'),
            Text('Запланировано: ${state.scheduledRemindersCount}'),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Примеры использования
  Future<void> _showPasswordCopied(WidgetRef ref) async {
    await ref
        .read(notificationProvider.notifier)
        .showPasswordCopied('google.com');
  }

  Future<void> _showTotpCopied(WidgetRef ref) async {
    await ref
        .read(notificationProvider.notifier)
        .showTotpCodeCopied('Google', 'user@example.com');
  }

  Future<void> _showSecurityAlert(WidgetRef ref) async {
    await ref
        .read(notificationProvider.notifier)
        .showSecurityAlert(
          'Предупреждение безопасности',
          'Обнаружена подозрительная активность в вашем аккаунте',
        );
  }

  Future<void> _scheduleReminder(WidgetRef ref) async {
    final reminderTime = DateTime.now().add(const Duration(seconds: 10));
    await ref
        .read(notificationProvider.notifier)
        .schedulePasswordReminder('example.com', reminderTime);
  }

  Future<void> _showTestNotification(WidgetRef ref) async {
    await ref.read(notificationProvider.notifier).showTestNotification();
  }
}

/// Простой пример интеграции в существующие сервисы
class ExamplePasswordService {
  /// Пример копирования пароля с уведомлением
  static Future<void> copyPasswordWithNotification({
    required String siteName,
    required String password,
    required WidgetRef ref,
  }) async {
    try {
      // Копируем пароль в буфер обмена
      // await Clipboard.setData(ClipboardData(text: password));

      // Отправляем уведомление
      await ref
          .read(notificationProvider.notifier)
          .showPasswordCopied(siteName);

      print('Пароль для $siteName скопирован и уведомление отправлено');
    } catch (e) {
      print('Ошибка копирования пароля: $e');
    }
  }
}

/// Пример интеграции с TOTP сервисом
class ExampleTotpService {
  /// Пример генерации TOTP кода с уведомлением
  static Future<String?> generateTotpWithNotification({
    required String issuer,
    required String accountName,
    required WidgetRef ref,
  }) async {
    try {
      // Генерируем TOTP код (здесь должна быть реальная логика)
      final String totpCode = '123456'; // Заглушка

      // Копируем в буфер обмена
      // await Clipboard.setData(ClipboardData(text: totpCode));

      // Отправляем уведомление
      await ref
          .read(notificationProvider.notifier)
          .showTotpCodeCopied(issuer, accountName);

      print('TOTP код для $issuer ($accountName) сгенерирован и скопирован');
      return totpCode;
    } catch (e) {
      print('Ошибка генерации TOTP: $e');
      return null;
    }
  }
}
