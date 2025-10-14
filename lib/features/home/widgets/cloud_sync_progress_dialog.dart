import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/models/cloud_sync_state.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/cloud_sync_provider.dart';

/// Модальное окно для отображения прогресса синхронизации с облаком
///
/// Показывает прогресс экспорта/импорта и предупреждает пользователя
/// о необходимости не закрывать приложение во время синхронизации
class CloudSyncProgressDialog extends ConsumerWidget {
  const CloudSyncProgressDialog({super.key});

  /// Показывает диалог прогресса синхронизации
  ///
  /// Возвращает Future<void>, который завершается при закрытии диалога
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Запрещаем закрытие по клику вне диалога
      builder: (context) => const CloudSyncProgressDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(cloudSyncProvider);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false, // Запрещаем закрытие по кнопке "Назад"
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: syncState.when(
            idle: () => _buildIdleState(context, theme),
            exporting: (progress) => _buildProgressState(
              context,
              theme,
              progress,
              'Экспорт в облако',
              Icons.cloud_upload,
            ),
            importing: (progress) => _buildProgressState(
              context,
              theme,
              progress,
              'Импорт из облака',
              Icons.cloud_download,
            ),
            success: (message) => _buildSuccessState(context, theme, message),
            error: (message) => _buildErrorState(context, theme, message),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState(BuildContext context, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_sync,
          size: 64,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'Ожидание синхронизации...',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressState(
    BuildContext context,
    ThemeData theme,
    CloudSyncProgress progress,
    String title,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Заголовок с иконкой
        Row(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Анимированная иконка
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Opacity(
                opacity: 0.5 + (value * 0.5),
                child: Icon(icon, size: 80, color: theme.colorScheme.primary),
              ),
            );
          },
          onEnd: () {},
        ),
        const SizedBox(height: 32),

        // Прогресс-бар
        Column(
          children: [
            LinearProgressIndicator(
              value: progress.progress > 0 ? progress.progress : null,
              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(
                0.3,
              ),
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
            const SizedBox(height: 12),

            // Процент выполнения
            if (progress.progress > 0)
              Text(
                '${(progress.progress * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Сообщение о статусе
        Text(
          progress.message,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),

        // Дополнительная информация о файле (если есть)
        if (progress.fileProgress.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              progress.fileProgress,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Предупреждение
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.error.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Не закрывайте приложение до завершения синхронизации!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(
    BuildContext context,
    ThemeData theme,
    String message,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 80, color: theme.colorScheme.primary),
        const SizedBox(height: 24),
        Text(
          'Успешно завершено',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Закрыть'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    String message,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, size: 80, color: theme.colorScheme.error),
        const SizedBox(height: 24),
        Text(
          'Ошибка синхронизации',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ],
    );
  }
}
