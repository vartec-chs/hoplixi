import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_export_state.dart';
import 'package:hoplixi/features/cloud_sync/providers/cloud_export_provider.dart';
import 'package:hoplixi/shared/widgets/button.dart';

/// Модальное окно для отображения прогресса экспорта в облако
class ExportProgressDialog extends ConsumerWidget {
  final VoidCallback? onClose;

  const ExportProgressDialog({super.key, this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportState = ref.watch(cloudExportProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxWidth: 500, minHeight: 200),
        child: exportState.when(
          data: (state) => state.when(
            idle: () => _buildIdleState(context),
            checking: (message) => _buildCheckingState(message),
            exporting: (progress, message, startedAt) =>
                _buildExportingState(context, progress, message, startedAt),
            fileProgress: (progress, message) =>
                _buildFileProgressState(progress, message, context),
            success: (fileName, exportTime) =>
                _buildSuccessState(context, fileName, exportTime),
            failure: (error) => _buildFailureState(context, error.toString()),
            warning: (message) => _buildWarningState(context, message),
            info: (action) => _buildInfoState(action, context),
            canceled: () => _buildCanceledState(context),
          ),
          loading: () => _buildLoadingState(),
          error: (error, stack) =>
              _buildFailureState(context, error.toString()),
        ),
      ),
    );
  }

  Widget _buildIdleState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'Готов к экспорту',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        SmoothButton(
          label: 'Закрыть',
          onPressed: () {
            onClose?.call();
            if (onClose == null) {
              Navigator.of(context).pop();
            }
          },
          type: SmoothButtonType.text,
        ),
      ],
    );
  }

  Widget _buildCheckingState(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildExportingState(
    BuildContext context,
    double progress,
    String message,
    DateTime? startedAt,
  ) {
    final elapsed = startedAt != null
        ? DateTime.now().difference(startedAt).inSeconds
        : 0;

    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_upload, size: 48, color: theme.primaryColor),
        const SizedBox(height: 16),
        const Text(
          'Экспорт в облако',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 8),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        if (startedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            'Прошло: $elapsed сек',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildFileProgressState(
    String progress,
    String message,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.upload_file, size: 48, color: theme.primaryColor),
        const SizedBox(height: 16),
        const Text(
          'Загрузка файла',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        CircularProgressIndicator(
          value: double.tryParse(progress) != null
              ? double.parse(progress) / 100
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          '$progress%',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSuccessState(
    BuildContext context,
    String fileName,
    int exportTime,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 48, color: Colors.greenAccent),
        const SizedBox(height: 16),
        const Text(
          'Экспорт завершён',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Файл: $fileName',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 24),
        SmoothButton(
          label: 'Закрыть',
          onPressed: () {
            onClose?.call();
            if (onClose == null) {
              Navigator.of(context).pop();
            }
          },
          type: SmoothButtonType.filled,
        ),
      ],
    );
  }

  Widget _buildFailureState(BuildContext context, String error) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error, size: 48, color: Colors.redAccent),
        const SizedBox(height: 16),
        const Text(
          'Ошибка экспорта',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
        ),
        const SizedBox(height: 24),
        SmoothButton(
          label: 'Закрыть',
          onPressed: () {
            onClose?.call();
            if (onClose == null) {
              Navigator.of(context).pop();
            }
          },
          type: SmoothButtonType.text,
        ),
      ],
    );
  }

  Widget _buildWarningState(BuildContext context, String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning, size: 48, color: Colors.amber),
        const SizedBox(height: 16),
        const Text(
          'Предупреждение',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 24),
        SmoothButton(
          label: 'Закрыть',
          onPressed: () {
            onClose?.call();
            if (onClose == null) {
              Navigator.of(context).pop();
            }
          },
          type: SmoothButtonType.text,
        ),
      ],
    );
  }

  Widget _buildInfoState(String action, BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.info, size: 48, color: theme.primaryColor),
        const SizedBox(height: 16),
        Text(
          action,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildCanceledState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cancel, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'Экспорт отменён',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        SmoothButton(
          label: 'Закрыть',
          onPressed: () {
            onClose?.call();
            if (onClose == null) {
              Navigator.of(context).pop();
            }
          },
          type: SmoothButtonType.text,
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Загрузка...', style: TextStyle(fontSize: 16)),
      ],
    );
  }

  /// Показывает модальное окно прогресса экспорта
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ExportProgressDialog(),
    );
  }
}
