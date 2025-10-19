import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/models/cloud_sync_state.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/cloud_import_provider.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/active_client_key_provider.dart';
import 'package:intl/intl.dart';

/// Полноэкранный экран прогресса импорта из облака
class CloudImportProgressScreen extends ConsumerWidget {
  const CloudImportProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(cloudImportProvider);

    return PopScope(
      // Блокируем навигацию назад во время загрузки/распаковки
      canPop: importState.maybeMap(
        downloading: (_) => false,
        extracting: (_) => false,
        orElse: () => true,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Импорт из облака'),
          leading: importState.maybeMap(
            downloading: (_) => null,
            extracting: (_) => null,
            orElse: () => BackButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.dashboard);
                }
              },
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: importState.map(
              idle: (_) => _buildIdleWidget(context),
              checking: (_) => _buildCheckingWidget(context),
              newVersionAvailable: (state) =>
                  _buildNewVersionWidget(context, ref, state.versionInfo),
              noNewVersion: (_) => _buildNoNewVersionWidget(context),
              downloading: (state) => _buildDownloadingWidget(
                context,
                state.progress,
                state.message,
              ),
              extracting: (state) => _buildExtractingWidget(
                context,
                state.progress,
                state.message,
              ),
              success: (state) =>
                  _buildSuccessWidget(context, state.importedFolderPath),
              failure: (state) => _buildErrorWidget(context, state.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_download_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Готов к импорту',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Нажмите кнопку для проверки новой версии',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckingWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Проверка новой версии...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Подключаемся к облаку',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewVersionWidget(
    BuildContext context,
    WidgetRef ref,
    versionInfo,
  ) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final sizeInMb = versionInfo.fileSize != null
        ? (versionInfo.fileSize! / (1024 * 1024)).toStringAsFixed(2)
        : 'неизвестно';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.update,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Доступна новая версия!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    icon: Icons.file_present,
                    label: 'Файл',
                    value: versionInfo.fileName,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.access_time,
                    label: 'Дата',
                    value: dateFormat.format(versionInfo.timestamp),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.storage,
                    label: 'Размер',
                    value: '$sizeInMb МБ',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              // Получаем активный clientKey для текущей БД
              final clientKey = await ref.read(activeClientKeyProvider.future);

              if (clientKey != null) {
                ref
                    .read(cloudImportProvider.notifier)
                    .downloadAndReplace(
                      clientKey: clientKey,
                      versionInfo: versionInfo,
                    );
              } else {
                // Если clientKey не найден, показываем ошибку
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Не удалось получить ключ авторизации. Настройте облачную синхронизацию.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Скачать и установить'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ref.read(cloudImportProvider.notifier).reset();
            },
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoNewVersionWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Всё актуально',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'У вас установлена последняя версия',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.dashboard);
              }
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Назад'),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadingWidget(
    BuildContext context,
    double progress,
    String message,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_download,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text('Загрузка...', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 32),
          SizedBox(
            width: 300,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Не закрывайте это окно',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtractingWidget(
    BuildContext context,
    double progress,
    String message,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_zip,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text('Распаковка...', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 32),
          SizedBox(
            width: 300,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'База данных будет заменена',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget(BuildContext context, String importedPath) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Импорт завершён!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'База данных успешно обновлена',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              // После успешного импорта необходимо переоткрыть БД
              context.go(AppRoutes.home);
            },
            icon: const Icon(Icons.home),
            label: const Text('На главную'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Consumer(
      builder: (context, ref, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Ошибка импорта',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    error,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.dashboard);
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Назад'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () {
                      // Повторяем последнюю операцию загрузки
                      ref
                          .read(cloudImportProvider.notifier)
                          .retryDownloadAndReplace();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Вспомогательный виджет для отображения информации
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
