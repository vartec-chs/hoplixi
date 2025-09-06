import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/auto_preferences/auto_settings_screen.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/preferences/dynamic_settings_screen.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'home_controller.dart';
import 'widgets/index.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _initializeController();
  }

  Future<void> _initializeController() async {
    await _controller.initialize();

    // Если пароль сохранен, предлагаем автоматическое открытие
    if (await _controller.canAutoOpenAsync && mounted) {
      _showAutoOpenDialog();
    }
  }

  void _showAutoOpenDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Автоматическое открытие'),
        content: Text(
          'Найдена недавно открытая база данных "${_controller.recentDatabase?.name}" с сохраненным паролем. Открыть автоматически?',
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              if (UniversalPlatform.isMobile)
                SliverAppBar(
                  pinned: true,
                  centerTitle: true,
                  title: const Text(
                    MainConstants.appName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const DynamicSettingsScreen(),
                          ),
                        );
                      },
                      tooltip: 'Настройки',
                    ),
                  ],
                )
              else
                SliverAppBar(
                  pinned: true,
                  centerTitle: true,
                  title: const Text(
                    MainConstants.appName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const AutoSettingsScreen(),
                          ),
                        );
                      },
                      tooltip: 'Настройки',
                    ),
                  ],
                ),

              // Карточка недавней базы данных
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 2,
                  children: [
                    SmoothButton(
                      onPressed: () {
                        context.go(AppRoutes.openStore);
                      },
                      isFullWidth: true,
                      label: 'Открыть хранилище',
                      icon: const Icon(Icons.file_open_sharp, size: 32),
                    ),

                    const SizedBox(height: 16),

                    SmoothButton(
                      onPressed: () {
                        context.go(AppRoutes.createStore);
                      },
                      isFullWidth: true,
                      type: SmoothButtonType.outlined,
                      label: 'Создать хранилище',
                      icon: const Icon(Icons.add_box, size: 32),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: Divider(height: 2)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    if (_controller.hasRecentDatabase) {
                      return RecentDatabaseCard(
                        database: _controller.recentDatabase!,
                        isLoading: _controller.isLoading,
                        isAutoOpening: _controller.isAutoOpening,
                        onOpenAuto: _handleAutoOpen,
                        onOpenManual: _handleManualOpen,
                        onRemove: _handleRemove,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Показываем ошибки если есть
              SliverToBoxAdapter(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    if (_controller.error != null) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _controller.error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAutoOpen() async {
    final result = await _controller.autoOpenRecentDatabase();
    if (result != null && mounted) {
      // Переходим к экрану базы данных
      _navigateToDatabase();
    }
  }

  Future<void> _handleManualOpen() async {
    if (!_controller.hasRecentDatabase) return;

    final result = await DatabasePasswordDialog.show(
      context,
      _controller.recentDatabase!,
    );

    if (result != null && mounted) {
      final dbResult = result.savePassword
          ? await _controller.openRecentDatabaseWithPasswordAndSave(
              result.password,
            )
          : await _controller.openRecentDatabaseWithPassword(result.password);

      if (dbResult != null && mounted) {
        _navigateToDatabase();
      }
    }
  }

  Future<void> _handleRemove() async {
    final confirmed = await _showRemoveConfirmDialog();
    if (confirmed == true) {
      await _controller.removeRecentDatabase();
    }
  }

  Future<bool?> _showRemoveConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из истории'),
        content: Text(
          'Удалить "${_controller.recentDatabase?.name}" из истории недавно открытых баз данных?',
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
    // TODO: Добавить навигацию к главному экрану базы данных
    // context.go(AppRoutes.database);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('База данных успешно открыта!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget buildAppBar() {
    return SliverAppBar(pinned: true, title: const Text(MainConstants.appName));
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
