import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_import_state.dart';
import 'package:hoplixi/features/cloud_sync/providers/cloud_import_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/shared/widgets/button.dart';

/// Экран прогресса импорта базы данных из облака
class CloudImportProgressScreen extends ConsumerStatefulWidget {
  const CloudImportProgressScreen({super.key});

  @override
  ConsumerState<CloudImportProgressScreen> createState() =>
      _CloudImportProgressScreenState();
}

class _CloudImportProgressScreenState
    extends ConsumerState<CloudImportProgressScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final importState = ref.watch(cloudImportProvider);

    // Слушаем изменения состояния импорта
    ref.listen<AsyncValue<ImportState>>(cloudImportProvider, (previous, next) {
      if (!mounted) return;

      next.whenData((state) {
        state.maybeWhen(
          success: (fileName, importTime) {
            // Успешный импорт
            ToastHelper.success(
              title: 'Импорт завершён',
              description: 'База данных успешно импортирована: $fileName',
            );
            context.go(AppRoutes.openStore);
          },
          failure: (error) {
            // Ошибка импорта - просто показываем уведомление
            ToastHelper.error(
              title: 'Ошибка импорта',
              description: _formatImportException(error),
            );
          },
          info: (action) {
            // Информационное сообщение
            ToastHelper.info(title: 'Информация', description: action);
          },
          warning: (message) {
            // Предупреждение
            ToastHelper.warning(title: 'Предупреждение', description: message);
          },
          orElse: () {},
        );
      });
    });

    return PopScope(
      // Блокируем возврат назад во время импорта
      canPop: importState.when(
        data: (state) => state.maybeMap(
          importing: (_) => false,
          checking: (_) => false,
          orElse: () => true,
        ),
        loading: () => false,
        error: (_, __) => true,
      ),
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text('Импорт'),
          automaticallyImplyLeading: importState.when(
            data: (state) => state.maybeMap(
              importing: (_) => false,
              checking: (_) => false,
              orElse: () => true,
            ),
            loading: () => false,
            error: (_, __) => true,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: importState.when(
                  data: (state) => _buildStateWidget(context, theme, state),
                  loading: () => _buildLoadingState(theme),
                  error: (error, stack) =>
                      _buildErrorWidget(theme, error.toString()),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateWidget(
    BuildContext context,
    ThemeData theme,
    ImportState state,
  ) {
    return state.map(
      idle: (_) => _buildIdleState(theme),
      checking: (state) => _buildCheckingState(theme, state.message),
      importing: (state) => _buildImportingState(
        theme,
        state.progress,
        state.message,
        state.startedAt,
      ),
      fileProgress: (state) =>
          _buildFileProgressState(theme, state.progress, state.message),
      success: (state) =>
          _buildSuccessState(theme, state.fileName, state.importTime),
      failure: (state) => _buildFailureState(theme, state.error),
      warning: (state) => _buildWarningState(theme, state.message),
      info: (state) => _buildInfoState(theme, state.action),
      canceled: (_) => _buildCanceledState(theme),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          'Инициализация импорта...',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIdleState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_download_outlined,
          size: 80,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 24),
        Text(
          'Готов к импорту',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Ожидание запуска импорта базы данных',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCheckingState(ThemeData theme, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          'Проверка',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImportingState(
    ThemeData theme,
    double progress,
    String message,
    DateTime? startedAt,
  ) {
    final elapsed = startedAt != null
        ? DateTime.now().difference(startedAt).inSeconds
        : 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Круговой индикатор прогресса
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (startedAt != null)
                  Text(
                    '${elapsed}с',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Импорт базы данных',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          color: theme.colorScheme.primary,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildFileProgressState(
    ThemeData theme,
    String progress,
    String message,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          'Скачивание файла',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          progress,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme, String fileName, int importTime) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
        const SizedBox(height: 32),
        Text(
          'Импорт завершён!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(
                  theme,
                  Icons.storage_outlined,
                  'База данных',
                  'Импортируемая база данных',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  theme,
                  Icons.insert_drive_file_outlined,
                  'Файл',
                  fileName,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  theme,
                  Icons.timer_outlined,
                  'Время импорта',
                  '$importTime сек.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'База данных успешно импортирована и готова к использованию',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SmoothButton(
          label: 'Готово',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          icon: const Icon(Icons.check),
          type: SmoothButtonType.filled,
        ),
      ],
    );
  }

  Widget _buildFailureState(ThemeData theme, dynamic error) {
    final errorMessage = _formatImportException(error);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 100, color: theme.colorScheme.error),
        const SizedBox(height: 32),
        Text(
          'Ошибка импорта',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: SmoothButton(
                label: 'Назад',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                icon: const Icon(Icons.arrow_back),
                type: SmoothButtonType.outlined,
              ),
            ),
            const SizedBox(width: 16),
            // Expanded(
            //   child: SmoothButton(
            //     label: 'Повторить',
            //     onPressed: () {
            //       ref
            //           .read(cloudImportProvider.notifier)
            //           .import(widget.databaseMeta);
            //     },
            //     icon: const Icon(Icons.refresh),
            //     type: SmoothButtonType.filled,
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildWarningState(ThemeData theme, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.warning_amber_outlined, size: 100, color: Colors.orange),
        const SizedBox(height: 32),
        Text(
          'Предупреждение',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        SmoothButton(
          label: 'Закрыть',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          icon: const Icon(Icons.close),
          type: SmoothButtonType.filled,
        ),
      ],
    );
  }

  Widget _buildInfoState(ThemeData theme, String action) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info_outline, size: 100, color: theme.colorScheme.primary),
        const SizedBox(height: 32),
        Text(
          'Информация',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Text(
            action,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        SmoothButton(
          label: 'Понятно',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          icon: const Icon(Icons.check),
          type: SmoothButtonType.filled,
        ),
      ],
    );
  }

  Widget _buildCanceledState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cancel_outlined,
          size: 100,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(height: 32),
        Text(
          'Импорт отменён',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Операция импорта была отменена',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SmoothButton(
          label: 'Закрыть',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          icon: const Icon(Icons.close),
          type: SmoothButtonType.outlined,
        ),
      ],
    );
  }

  Widget _buildErrorWidget(ThemeData theme, String message) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 100, color: theme.colorScheme.error),
        const SizedBox(height: 32),
        Text(
          'Критическая ошибка',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 48),
        SmoothButton(
          label: 'Закрыть',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          icon: const Icon(Icons.close),
          type: SmoothButtonType.outlined,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Форматирование ошибки импорта в читаемое сообщение
  String _formatImportException(dynamic error) {
    // Временное решение до генерации freezed
    // После генерации можно использовать error.when() или error.map()
    final errorString = error.toString();

    if (errorString.contains('ImportNetworkException')) {
      return 'Сетевая ошибка при импорте';
    } else if (errorString.contains('ImportAuthException')) {
      return 'Ошибка авторизации';
    } else if (errorString.contains('ImportLockingException')) {
      return 'Ошибка блокировки хранилища';
    } else if (errorString.contains('ImportStorageException')) {
      return 'Ошибка хранилища';
    } else if (errorString.contains('ImportValidationException')) {
      return 'Ошибка валидации данных';
    } else if (errorString.contains('ImportWarningException')) {
      return 'Предупреждение при импорте';
    } else if (errorString.contains('ImportPermissionException')) {
      return 'Недостаточно прав доступа';
    } else {
      return 'Неизвестная ошибка импорта';
    }
  }
}
