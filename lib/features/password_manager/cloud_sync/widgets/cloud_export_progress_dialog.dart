import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/models/cloud_sync_state.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/cloud_export_provider.dart';

/// Модальное окно прогресса экспорта
/// Показывается поверх всего интерфейса и блокирует навигацию во время экспорта
class CloudExportProgressDialog extends ConsumerWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onError;

  const CloudExportProgressDialog({super.key, this.onComplete, this.onError});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(cloudExportProvider);

    // Автоматически вызываем колбэки при завершении
    ref.listen<ExportState>(cloudExportProvider, (previous, next) {
      next.maybeMap(
        success: (_) {
          onComplete?.call();
          Navigator.of(context, rootNavigator: true).pop();
        },
        failure: (_) {
          onError?.call();
        },
        orElse: () {},
      );
    });

    return PopScope(
      canPop: exportState.maybeMap(
        inProgress: (_) => false,
        orElse: () => true,
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: exportState.map(
            idle: (_) => _buildIdleWidget(context),
            inProgress: (state) =>
                _buildProgressWidget(context, state.progress, state.message),
            success: (state) =>
                _buildSuccessWidget(context, state.fileName, state.exportTime),
            failure: (state) => _buildErrorWidget(context, ref, state.error),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 64,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 16),
        Text(
          'Подготовка к экспорту',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  Widget _buildProgressWidget(
    BuildContext context,
    double progress,
    String message,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_upload,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text('Экспорт в облако', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 24),
        SizedBox(
          width: 280,
          child: Column(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Пожалуйста, подождите...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessWidget(
    BuildContext context,
    String fileName,
    int exportTime,
  ) {
    final duration = Duration(milliseconds: exportTime);
    final seconds = duration.inSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Экспорт завершён!',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          fileName,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Время: $seconds сек',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
          icon: const Icon(Icons.check),
          label: const Text('Готово'),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, String error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Ошибка экспорта',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            error,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                ref.read(cloudExportProvider.notifier).reset();
                Navigator.of(context, rootNavigator: true).pop();
              },
              child: const Text('Отмена'),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () {
                // Повторяем последнюю операцию экспорта
                ref.read(cloudExportProvider.notifier).retry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ],
    );
  }

  /// Показать диалог экспорта
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onComplete,
    VoidCallback? onError,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) =>
          CloudExportProgressDialog(onComplete: onComplete, onError: onError),
    );
  }
}
