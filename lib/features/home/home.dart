import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';

import 'package:hoplixi/core/theme/index.dart';

import 'package:universal_platform/universal_platform.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'home_controller.dart';
import 'widgets/index.dart';

/// Современный главный экран с поддержкой slivers и модульной архитектуры
class ModernHomeScreen extends ConsumerStatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  ConsumerState<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends ConsumerState<ModernHomeScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  late AnimationController _fabAnimationController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Инициализация с задержкой для плавной анимации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fabAnimationController.forward();
      // Убираем инициализацию контроллера отсюда, чтобы избежать циклической зависимости
    });
  }

  void _showAutoOpenDialog() {
    if (!mounted) return;

    final recentDatabase = ref.read(recentDatabaseProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog.adaptive(
        constraints: BoxConstraints(maxWidth: 600),
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
        content: Text(
          'Найдена недавно открытая база данных "${recentDatabase?.name}" с сохраненным паролем. Открыть автоматически?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Пропустить'),
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
    _pageController.dispose();
    _fabAnimationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer(
      builder: (context, ref, child) {
        final selectedIndex = ref.watch(selectedBottomNavIndexProvider);

        // Проверяем возможность автооткрытия после инициализации
        ref.listen<AsyncValue<bool>>(canAutoOpenWithSettingsProvider, (
          previous,
          next,
        ) {
          next.whenOrNull(
            data: (canAutoOpen) {
              if (canAutoOpen && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showAutoOpenDialog();
                });
              }
            },
          );
        });

        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              ref
                  .read(homeControllerProvider.notifier)
                  .setBottomNavIndex(index);
            },
            children: [
              _buildHomeView(),
              _buildSearchView(),
              _buildFavoritesView(),
              _buildSettingsView(),
            ],
          ),
          // bottomNavigationBar: _buildModernBottomNav(selectedIndex),
          // floatingActionButton: _buildFloatingActionButton(),
        );
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
            _buildErrorMessage(),
            // Добавляем отступ снизу для FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  /// Создает представление поиска (заглушка)
  Widget _buildSearchView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Поиск', style: TextStyle(fontSize: 24, color: Colors.grey)),
          SizedBox(height: 8),
          Text(
            'Функция будет добавлена в будущих версиях',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Создает представление избранного (заглушка)
  Widget _buildFavoritesView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Избранное', style: TextStyle(fontSize: 24, color: Colors.grey)),
          SizedBox(height: 8),
          Text(
            'Функция будет добавлена в будущих версиях',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Создает представление настроек (заглушка)
  Widget _buildSettingsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Настройки', style: TextStyle(fontSize: 24, color: Colors.grey)),
          SizedBox(height: 8),
          Text(
            'Функция будет добавлена в будущих версиях',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Создает современную нижнюю навигацию
  Widget _buildModernBottomNav(int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            ref.read(homeControllerProvider.notifier).setBottomNavIndex(index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Главная',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.lock_outline),
              activeIcon: Icon(Icons.lock),
              label: 'Аутентификация',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.send_outlined),
              activeIcon: Icon(Icons.send),
              label: 'LocalSend',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }

  /// Создает плавающую кнопку действия
  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimationController.value,
          child: FloatingActionButton.extended(
            onPressed: () {
              // Показываем меню быстрых действий
              _showQuickActionsBottomSheet();
            },
            icon: const Icon(Icons.add),
            label: const Text('Быстро'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        );
      },
    );
  }

  /// Показывает нижнее меню быстрых действий
  void _showQuickActionsBottomSheet() {
    showModalBottomSheet(
      useSafeArea: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Быстрые действия',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.file_open),
              title: const Text('Открыть хранилище'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.openStore);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box),
              title: const Text('Создать хранилище'),
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.createStore);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Настройки'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UniversalPlatform.isMobile
                        ? const DynamicSettingsScreen()
                        // : const AutoSettingsScreen(),
                        : const SizedBox.expand(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
                Theme.of(context).colorScheme.onPrimary,
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
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            ToastHelper.info(title: 'Функция в разработке');
            // TODO: Показать уведомления
          },
          tooltip: 'Уведомления',
        ),
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UniversalPlatform.isMobile
                    ? const DynamicSettingsScreen()
                    : const SizedBox(),
              ),
            );
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
            Text(
              'Быстрые действия',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
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
                const SizedBox(width: 16),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.send,
                    label: 'LocalSend',
                    onTap: () => context.push(AppRoutes.localSend),
                    isPrimary: false,
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
          padding: const EdgeInsets.all(24),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: isPrimary
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
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
        return const SliverToBoxAdapter(child: SizedBox.shrink());
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Недавние базы данных',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                RecentDatabaseCard(
                  database: homeState.recentDatabase!,
                  isLoading: homeState.isLoading,
                  isAutoOpening: homeState.isAutoOpening,
                  onOpenAuto: _handleAutoOpen,
                  onOpenManual: _handleManualOpen,
                  onRemove: _handleRemove,
                ),
                const SizedBox(height: 24),
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

  /// Показывает ошибки если есть
  Widget _buildErrorMessage() {
    return SliverToBoxAdapter(
      child: Consumer(
        builder: (context, ref, child) {
          final homeState = ref.watch(homeControllerProvider);

          if (homeState.error == null) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    homeState.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildAppBar() {
    return SliverAppBar(pinned: true, title: const Text(MainConstants.appName));
  }

  // Обработчики событий
  Future<void> _handleAutoOpen() async {
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
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

class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.onPressed,
    required this.child,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.width = 150,

    this.height = 150,
    this.borderRadius = 12,
    this.isWidthFull = false,
    super.key,
  });

  final VoidCallback onPressed;
  final Widget child;

  final double borderRadius;
  final Widget? icon;
  final Color? backgroundColor;
  final double width;
  final double height;
  final bool isWidthFull;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWidthFull ? double.infinity : width,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero, // убирает лишние отступы
          backgroundColor: backgroundColor ?? Colors.transparent,
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: borderColor ?? Colors.transparent),
          ),
        ),
        child: Center(
          child: icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [icon!, const SizedBox(width: 8), child],
                )
              : child,
        ), // текст/иконка по центру
      ),
    );
  }
}
