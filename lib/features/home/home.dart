import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/app_preferences/index.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/features/global/providers/biometric_auto_open_provider.dart';
import 'package:hoplixi/features/global/providers/biometric_provider.dart';
import 'package:hoplixi/hoplixi_store/services/biometric_service.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/features/global/widgets/password_field.dart';
import 'package:hoplixi/features/global/widgets/slider_button.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'home_controller.dart';
import 'widgets/index.dart';

bool _hasShownAutoOpenDialog = false;

/// Современный главный экран с поддержкой slivers и модульной архитектуры
class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _fabAnimationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Инициализация с задержкой для плавной анимации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabAnimationController.forward();
    });
  }

  void _showAutoOpenDialog() {
    if (!mounted) return;

    final recentDatabase = ref.read(recentDatabaseProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(8),
        constraints: BoxConstraints(maxWidth: 400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text(
              'Авто открытие',
              style: TextStyle(fontWeight: FontWeight.bold),
              softWrap: true,
            ),
          ],
        ),
        // content: Text(
        //   'Найдена недавно открытая база данных "${recentDatabase?.name}" с сохраненным паролем. Открыть автоматически?',
        // ),
        content: Column(
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Недавняя база данных "${recentDatabase?.name}"',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              'Найдена база данных с сохраненным паролем. Открыть автоматически?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),

            Text(
              'Это можно отключить в настройках приложения.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(),
            label: 'Пропустить',
            icon: const Icon(Icons.close, size: 18),
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleAutoOpen();
            },
            label: 'Открыть',
            icon: const Icon(Icons.lock_open, size: 18),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer(
      builder: (context, ref, child) {
        // Проверяем возможность автооткрытия после инициализации
        ref.listen<AsyncValue<bool>>(canAutoOpenWithSettingsProvider, (
          previous,
          next,
        ) {
          next.whenOrNull(
            data: (canAutoOpen) {
              if (canAutoOpen &&
                  !_hasShownAutoOpenDialog &&
                  mounted &&
                  GoRouter.of(context).state.matchedLocation ==
                      AppRoutes.home) {
                _hasShownAutoOpenDialog = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showAutoOpenDialog();
                });
              }
            },
          );
        });

        ref.listen<HomeState>(homeControllerProvider, (previous, next) {
          if (next.error != null && next.error != previous?.error) {
            ToastHelper.error(title: 'Ошибка', description: next.error!);
          }
        });

        return Scaffold(body: SafeArea(child: _buildHomeView()));
      },
    );
  }

  /// Строит главную страницу с использованием slivers
  Widget _buildHomeView() {
    return Consumer(
      builder: (context, ref, child) {
        final widgets = ref.watch(homeWidgetsProvider);

        return CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildQuickActions(),
            ...widgets.map(_buildHomeWidget),

            // _buildErrorMessage(),
            !MainConstants.isProduction
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Для тестирования:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            spacing: 8,
                            children: [
                              FilledButton(
                                onPressed: () {
                                  context.push(AppRoutes.qrTest);
                                },
                                child: const Text('QR Scan'),
                              ),

                              FilledButton(
                                onPressed: () {
                                  context.push(AppRoutes.demoNotification);
                                },
                                child: const Text('Тест уведомлений'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                : const SliverToBoxAdapter(child: SizedBox.shrink()),
            // Добавляем отступ снизу для FAB
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ],
        );
      },
    );
  }

  /// Создает SliverAppBar с современным дизайном
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      snap: true,
      pinned: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Animate(
          effects: [
            // будем бесконечно смещать градиент
            ShimmerEffect(
              duration: 2000.ms,
              colors: [
                Theme.of(context).colorScheme.primary,
                Colors.white,
                Theme.of(context).colorScheme.primary,
              ],
              angle: -30, // угол пробегающего блика
            ),
          ],
          onComplete: (controller) =>
              controller.repeat(), // бесконечная анимация Text(
          child: Text(
            MainConstants.appName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),

        background: Container(
          decoration: BoxDecoration(
            backgroundBlendMode: BlendMode.overlay,
            color: Theme.of(context).colorScheme.surface,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withOpacity(0.1),
                Theme.of(
                  context,
                ).colorScheme.secondaryContainer.withOpacity(0.1),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Visibility(
          visible: UniversalPlatform.isMobile,
          child: const ThemeSwitcher(size: 24),
        ),

        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () {
            context.push(AppRoutes.settings);
          },
          tooltip: 'Настройки',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Создает быстрые действия
  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.file_open,
                    label: 'Открыть хранилище',
                    onTap: () => context.go(AppRoutes.openStore),
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.add_box,
                    label: 'Создать хранилище',
                    onTap: () => context.go(AppRoutes.createStore),
                    isPrimary: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.send,
                    label: 'LocalSend',
                    onTap: () => context.push(AppRoutes.localSend),
                    isPrimary: false,
                    description:
                        'Обмен файлами по локальной сети (в разработке)',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Создает карточку быстрого действия
  Widget _buildQuickActionCard({
    required IconData icon,
    String? description,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isPrimary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  )
                : null,
          ),
          child: Column(
            spacing: 8,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: isPrimary
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),

              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (description != null) ...[
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPrimary
                        ? Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.9)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Создает виджет на основе данных HomeWidgetData
  Widget _buildHomeWidget(HomeWidgetData widget) {
    switch (widget.type) {
      case HomeWidgetType.recentDatabase:
        return _buildRecentDatabaseWidget();
      case HomeWidgetType.quickActions:
        return _buildQuickActionsWidget();
      case HomeWidgetType.statistics:
        return _buildStatisticsWidget();
      case HomeWidgetType.shortcuts:
        return _buildShortcutsWidget();
      case HomeWidgetType.notifications:
        return _buildNotificationsWidget();
      case HomeWidgetType.customWidget:
        return _buildCustomWidget(widget);
    }
  }

  /// Создает виджет недавней базы данных
  Widget _buildRecentDatabaseWidget() {
    return SliverToBoxAdapter(
      child: Consumer(
        builder: (context, ref, child) {
          final homeState = ref.watch(homeControllerProvider);

          if (!homeState.hasRecentDatabase) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RecentDatabaseCard(
                  database: homeState.recentDatabase!,
                  isLoading: homeState.isLoading,
                  isAutoOpening: homeState.isAutoOpening,
                  onOpenAuto: _handleAutoOpen,
                  onOpenManual: _handleManualOpen,
                  onRemove: _handleRemove,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Создает виджет статистики
  Widget _buildStatisticsWidget() {
    return SliverToBoxAdapter(
      child: Consumer(
        builder: (context, ref, child) {
          final historyStats = ref.watch(historyStatsProvider);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статистика',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    historyStats.when(
                      data: (stats) => Column(
                        children: [
                          _buildStatItem(
                            'Всего записей',
                            stats['totalEntries'].toString(),
                          ),
                          _buildStatItem(
                            'С сохраненными паролями',
                            stats['entriesWithSavedPasswords'].toString(),
                          ),
                        ],
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text(
                        'Ошибка загрузки статистики',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickActionsWidget() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.archive,
                label: 'Экспорт хранилища',
                onTap: () => context.push(AppRoutes.exportStorage),
                isPrimary: false,
                description: 'Создать архив хранилища для резервной копии',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.download,
                label: 'Импорт хранилища',
                onTap: () => context.push(AppRoutes.importStorage),
                isPrimary: false,
                description: 'Восстановить хранилище из архива',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Заглушки для остальных виджетов
  Widget _buildShortcutsWidget() {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildNotificationsWidget() {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildCustomWidget(HomeWidgetData widget) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget buildAppBar() {
    return SliverAppBar(pinned: true, title: const Text(MainConstants.appName));
  }

  // Обработчики событий
  Future<void> _handleAutoOpen() async {
    // Проверяем настройку биометрии
    final biometricEnabled = await ref.read(biometricAutoOpenProvider.future);

    if (biometricEnabled) {
      // Проверяем статус биометрии
      final biometricService = ref.read(biometricServiceProvider);
      final statusResult = await biometricService.checkBiometricStatus();

      if (!statusResult.success || statusResult.data != BiometricStatus.ready) {
        ToastHelper.error(
          title: 'Биометрия недоступна',
          description:
              'Биометрическая аутентификация не настроена или недоступна. Отключите биометрию в настройках.',
        );
        return;
      }

      // Выполняем биометрическую аутентификацию
      final authResult = await biometricService.authenticateWithBiometrics(
        localizedReason: 'Подтвердите открытие базы данных биометрией',
      );

      if (!authResult.success ||
          authResult.data != BiometricAuthResult.authenticated) {
        ToastHelper.error(
          title: 'Аутентификация неудачна',
          description:
              'Не удалось подтвердить личность. Попробуйте еще раз или отключите биометрию в настройках. Возможно превышен лимит попыток.',
        );
        return;
      }
    }

    // Продолжаем с открытием базы данных
    final controller = ref.read(homeControllerProvider.notifier);
    final result = await controller.autoOpenRecentDatabase();
    if (result != null && context.mounted) {
      _navigateToDatabase();
    }
  }

  Future<void> _handleManualOpen() async {
    final hasRecentDatabase = ref.read(hasRecentDatabaseProvider);
    if (!hasRecentDatabase) return;

    final recentDatabase = ref.read(recentDatabaseProvider);
    final result = await DatabasePasswordDialog.show(context, recentDatabase!);

    if (result != null && context.mounted) {
      final controller = ref.read(homeControllerProvider.notifier);
      final dbResult = result.savePassword
          ? await controller.openRecentDatabaseWithPasswordAndSave(
              result.password,
            )
          : await controller.openRecentDatabaseWithPassword(result.password);

      if (dbResult != null && context.mounted) {
        _navigateToDatabase();
      }
    }
  }

  Future<void> _handleRemove() async {
    final confirmed = await _showRemoveConfirmDialog();
    if (confirmed == true) {
      final controller = ref.read(homeControllerProvider.notifier);
      await controller.removeRecentDatabase();
    }
  }

  Future<bool?> _showRemoveConfirmDialog() {
    final recentDatabase = ref.read(recentDatabaseProvider);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Удалить из истории'),
        content: Text(
          'Удалить "${recentDatabase?.name}" из истории недавно открытых баз данных?',
        ),
        actions: [
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(false),
            label: 'Отмена',
            icon: const Icon(Icons.close, size: 18),
            type: SmoothButtonType.text,
          ),
          SmoothButton(
            onPressed: () => Navigator.of(context).pop(true),
            label: 'Удалить',
            icon: const Icon(Icons.delete, size: 18),
            type: SmoothButtonType.outlined,
          ),
        ],
      ),
    );
  }

  void _navigateToDatabase() {
    context.go(AppRoutes.dashboard);
  }
}
