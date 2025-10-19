import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/app/router/router_provider.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:hoplixi/features/auth/models/auth_state.dart';
import 'package:hoplixi/features/auth/models/models.dart';
import 'package:hoplixi/features/auth/providers/authorization_notifier_provider.dart';
import 'package:hoplixi/features/auth/widgets/auth_modal.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_sync_setup_state.dart';
import 'package:hoplixi/features/cloud_sync/models/local_meta.dart';
import 'package:hoplixi/features/cloud_sync/providers/cloud_sync_setup_provider.dart';

class CloudSyncSetupScreen extends ConsumerStatefulWidget {
  const CloudSyncSetupScreen({super.key});

  @override
  ConsumerState<CloudSyncSetupScreen> createState() =>
      _CloudSyncSetupScreenState();
}

class _CloudSyncSetupScreenState extends ConsumerState<CloudSyncSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(cloudSyncSetupProvider);

    // Слушаем результат авторизации
    ref.listen<AuthState>(authorizationProvider, (previous, next) {
      next.maybeMap(
        success: (state) {
          // Проверяем, что returnPath соответствует нашему экрану
          if (state.returnPath == AppRoutes.cloudSyncSetup) {
            // Завершаем отложенную настройку с полученным ключом
            ref
                .read(cloudSyncSetupProvider.notifier)
                .checkAndCompletePendingSetup(state.clientKey);
          }
        },
        cancelled: (state) {
          // Пользователь отменил авторизацию
          if (state.returnPath == AppRoutes.cloudSyncSetup) {
            ref
                .read(cloudSyncSetupProvider.notifier)
                .checkAndCompletePendingSetup(null);
          }
        },
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка облачной синхронизации'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
        actions: [
          // Кнопка обновления
          if (setupState.hasValue &&
              !setupState.value!.maybeMap(
                loading: (_) => true,
                setupInProgress: (_) => true,
                orElse: () => false,
              ))
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(cloudSyncSetupProvider.notifier).refresh();
              },
              tooltip: 'Обновить',
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: setupState.when(
            data: (state) => _buildStateWidget(context, state),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                _buildErrorWidget(context, error.toString()),
          ),
        ),
      ),
    );
  }

  Widget _buildStateWidget(BuildContext context, CloudSyncSetupState state) {
    return state.map(
      loading: (_) => const Center(child: CircularProgressIndicator()),
      notConfigured: (state) => _buildNotConfiguredWidget(context, state),
      alreadyConfigured: (state) =>
          _buildAlreadyConfiguredWidget(context, state),
      setupInProgress: (_) => _buildSetupInProgressWidget(context),
      setupCompleted: (state) => _buildSetupCompletedWidget(context, state),
      error: (state) => _buildErrorWidget(context, state.message),
    );
  }

  /// Виджет: синхронизация не настроена - призыв к действию
  Widget _buildNotConfiguredWidget(
    BuildContext context,
    CloudSyncSetupState state,
  ) {
    // Извлекаем данные из состояния
    final dbId = (state as dynamic).dbId as String;
    final dbName = (state as dynamic).dbName as String;

    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 120,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 32),
            Text(
              'Облачная синхронизация не настроена',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'База данных: $dbName',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Настройте синхронизацию с облаком, чтобы безопасно хранить резервные копии вашей базы данных и получать доступ к ней с других устройств.',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => _handleStartSetup(context, dbId, dbName),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: const Text('Начать настройку'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => navigateBack(context),
              child: const Text('Позже'),
            ),
          ],
        ),
      ),
    );
  }

  /// Виджет: синхронизация уже настроена
  Widget _buildAlreadyConfiguredWidget(
    BuildContext context,
    CloudSyncSetupState state,
  ) {
    final theme = Theme.of(context);
    final meta = (state as dynamic).meta as LocalMeta;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_done_outlined,
              size: 120,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Синхронизация настроена',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      Icons.storage_outlined,
                      'База данных',
                      meta.dbName,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.cloud_outlined,
                      'Провайдер',
                      meta.providerType.name,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      Icons.devices_outlined,
                      'Устройство',
                      _truncateDeviceId(meta.deviceId),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context,
                      meta.enabled ? Icons.check_circle : Icons.cancel,
                      'Статус',
                      meta.enabled ? 'Включена' : 'Отключена',
                      valueColor: meta.enabled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    if (meta.lastExportAt != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        Icons.upload_outlined,
                        'Последний экспорт',
                        _formatDateTime(meta.lastExportAt!),
                      ),
                    ],
                    if (meta.lastImportedAt != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        Icons.download_outlined,
                        'Последний импорт',
                        _formatDateTime(meta.lastImportedAt!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.check),
              label: const Text('Готово'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Виджет: процесс настройки
  Widget _buildSetupInProgressWidget(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 32),
          Text(
            'Настройка синхронизации...',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Пожалуйста, подождите',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Виджет: настройка завершена - поздравление
  Widget _buildSetupCompletedWidget(
    BuildContext context,
    CloudSyncSetupState state,
  ) {
    final theme = Theme.of(context);
    final providerType = (state as dynamic).providerType as ProviderType;
    final dbName = (state as dynamic).dbName as String;

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 120,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 32),
            Text(
              'Поздравляем!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Облачная синхронизация успешно настроена',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_done,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      dbName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'синхронизируется через ${providerType.name}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Теперь ваши данные будут автоматически синхронизироваться с облаком. Вы можете получить к ним доступ с других устройств.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => navigateBack(context),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Отлично!'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Виджет: ошибка
  Widget _buildErrorWidget(BuildContext context, String message) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 120,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 32),
            Text(
              'Ошибка',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () {
                ref.read(cloudSyncSetupProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => navigateBack(context),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  /// Вспомогательный виджет для отображения строки информации
  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

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
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Обработчик начала настройки
  Future<void> _handleStartSetup(
    BuildContext context,
    String dbId,
    String dbName,
  ) async {
    // Сохраняем данные для настройки в провайдере
    ref
        .read(cloudSyncSetupProvider.notifier)
        .startSetup(dbId: dbId, dbName: dbName);

    // Показываем модальное окно авторизации
    // Результат обработается через listener в initState
    await showNewAuthModal(context, returnPath: AppRoutes.cloudSyncSetup);
  }

  /// Форматирование deviceId
  String _truncateDeviceId(String deviceId) {
    if (deviceId.length <= 12) return deviceId;
    return '${deviceId.substring(0, 8)}...${deviceId.substring(deviceId.length - 4)}';
  }

  /// Форматирование даты и времени
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${dateTime.day}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
    }
  }
}
