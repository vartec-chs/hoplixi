import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/global/widgets/close_database_button.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/theme_switcher.dart';
import 'package:hoplixi/features/global/widgets/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entety_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/entety_type_provider.dart';

import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_app_bar.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_list_view.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
import 'package:hoplixi/hoplixi_store/providers/providers.dart';
import 'package:hoplixi/router/routes_path.dart';

/// Главный экран дашборда с полнофункциональным SliverAppBar
/// Управляет отображением паролей, заметок и OTP с фильтрацией и поиском
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDatabaseOpen = ref.watch(isDatabaseOpenProvider);
    final dbNotifier = ref.read(hoplixiStoreProvider.notifier);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
          final currentEntityType = ref.read(currentEntityTypeProvider);
          switch (currentEntityType) {
            case EntityType.password:
              context.push(AppRoutes.passwordForm);
            case EntityType.note:
              context.push(AppRoutes.notesForm);
            case EntityType.otp:
              context.push(AppRoutes.otpForm);
          }
        },
        SingleActivator(LogicalKeyboardKey.keyP, control: true): () {
          ref
              .read(entityTypeControllerProvider.notifier)
              .changeEntityType(EntityType.password);
        },
        SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          ref
              .read(entityTypeControllerProvider.notifier)
              .changeEntityType(EntityType.note);
        },
        SingleActivator(LogicalKeyboardKey.keyO, control: true): () {
          ref
              .read(entityTypeControllerProvider.notifier)
              .changeEntityType(EntityType.otp);
        }, // drawer
        SingleActivator(LogicalKeyboardKey.keyD, control: true): () {
          if (_scaffoldKey.currentState != null) {
            if (_scaffoldKey.currentState!.isDrawerOpen) {
              _scaffoldKey.currentState?.closeDrawer();
            } else {
              _scaffoldKey.currentState?.openDrawer();
            }
          }
        }, // icon
        SingleActivator(LogicalKeyboardKey.keyI, control: true): () {
          context.push(AppRoutes.iconManager);
        }, // tag
        SingleActivator(LogicalKeyboardKey.keyT, control: true): () {
          context.push(AppRoutes.tagsManager);
        }, // category
        SingleActivator(LogicalKeyboardKey.keyC, control: true): () {
          context.push(AppRoutes.categoryManager);
        },

        /// exit escape
        SingleActivator(LogicalKeyboardKey.escape): () async {
          if (isDatabaseOpen) {
            final shouldClose = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Подтверждение'),
                content: const Text(
                  'Вы хотите закрыть базу данных и выйти на главный экран?',
                ),
                actions: [
                  SmoothButton(
                    type: SmoothButtonType.text,
                    label: 'Отмена',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  SmoothButton(
                    label: 'Закрыть',
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
            if (shouldClose == true) {
              await ref.read(clearAllProvider.notifier).clearAll();
              await dbNotifier.closeDatabase();
              if (context.mounted) context.go(AppRoutes.home);
            }
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
          canPop: false, // если false → блокирует закрытие

          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              logInfo(
                'Экран закрыт, результат: $result',
                tag: 'DashboardScreen',
              );
            } else {
              logInfo(
                'Попытка закрыть, но не получилось',
                tag: 'DashboardScreen',
              );
              if (isDatabaseOpen) {
                final shouldClose = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Подтверждение'),
                    content: const Text('Вы хотите закрыть базу данных?'),
                    actions: [
                      SmoothButton(
                        type: SmoothButtonType.text,
                        label: 'Отмена',
                        onPressed: () => Navigator.pop(context, false),
                      ),
                      SmoothButton(
                        label: 'Закрыть',
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                );
                if (shouldClose == true) {
                  await ref.read(clearAllProvider.notifier).clearAll();
                  await dbNotifier.closeDatabase();
                  if (context.mounted) context.go(AppRoutes.home);
                }
              }
            }
          },
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            key: _scaffoldKey,
            body: SafeArea(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Полнофункциональный SliverAppBar
                  Builder(
                    builder: (context) {
                      return DashboardSliverAppBar(
                        onMenuPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        onFilterApplied: () {
                          logInfo('DashboardScreen: Фильтры применены');
                        },
                        expandedHeight: 173.0,
                        collapsedHeight: 60.0,
                        pinned: true,
                        floating: false,
                        snap: false,
                        showEntityTypeSelector: true,
                      );
                    },
                  ),

                  // Главный контент - список сущностей с пагинацией
                  EntityListView(scrollController: _scrollController),
                ],
              ),
            ),

            // Drawer навигации
            drawer: _buildDrawer(context),

            // Expandable FAB для создания новых сущностей
            floatingActionButton: Consumer(
              builder: (context, ref, child) {
                final currentEntityType = ref.watch(currentEntityTypeProvider);
                return ExpandableFAB(
                  iconData: currentEntityType == EntityType.password
                      ? Icons.key
                      : currentEntityType == EntityType.note
                      ? Icons.note
                      : currentEntityType == EntityType.otp
                      ? Icons.security
                      : Icons.add,
                  entityName: currentEntityType == EntityType.password
                      ? 'пароль'
                      : currentEntityType == EntityType.note
                      ? 'заметку'
                      : currentEntityType == EntityType.otp
                      ? 'OTP'
                      : 'сущность',
                  onCreateEntity: () {
                    if (currentEntityType == EntityType.password) {
                      context.push(AppRoutes.passwordForm);
                    } else if (currentEntityType == EntityType.note) {
                      logInfo('DashboardScreen: Создание новой заметки');
                      context.push(AppRoutes.notesForm);
                      // context.push(AppRoutes.noteForm);
                    } else if (currentEntityType == EntityType.otp) {
                      logInfo('DashboardScreen: Создание нового OTP');
                      context.push(AppRoutes.otpForm);
                    } else {
                      logInfo(
                        'DashboardScreen: Неизвестный тип сущности для создания',
                      );
                    }
                  },
                  onCreateCategory: () {
                    logInfo('DashboardScreen: Создание новой категории');
                    context.push(AppRoutes.categoryManager);
                  },
                  onCreateTag: () {
                    logInfo('DashboardScreen: Создание нового тега');
                    context.push(AppRoutes.tagsManager);
                  },
                  onIconCreate: () {
                    logInfo('DashboardScreen: Создание новой иконки');
                    context.push(AppRoutes.iconManager);
                  },
                  importOtpCodes: currentEntityType == EntityType.otp
                      ? () {
                          logInfo('DashboardScreen: Импорт OTP кодов');
                          context.push(AppRoutes.importOtpCodes);
                        }
                      : null,
                  migratePasswords: currentEntityType == EntityType.password
                      ? () {
                          logInfo('DashboardScreen: Миграция паролей');
                          context.push(AppRoutes.passwordMigration);
                        }
                      : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final currentEntityType = ref.watch(currentEntityTypeProvider);
        return Drawer(
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Header
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.security,
                        size: 48,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hoplixi',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Менеджер паролей',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),

                      const ThemeSwitcher(size: 24),
                    ],
                  ),
                ),

                // Навигация по сущностям
                ListTile(
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Дашборд'),
                  selected: true,
                  onTap: () {
                    Navigator.pop(context);
                    logInfo('DashboardScreen: Уже на дашборде');
                  },
                ),

                const CloseDatabaseButton(useListTile: true),

                const Divider(),

                // Управление паролями
                ListTile(
                  leading: const Icon(Icons.password),
                  selected: currentEntityType == EntityType.password,
                  title: const Text('Пароли'),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(entityTypeControllerProvider.notifier)
                        .changeEntityType(EntityType.password);
                    logInfo('DashboardScreen: Переход к паролям');
                  },
                ),

                // Управление заметками
                ListTile(
                  leading: const Icon(Icons.note),
                  selected: currentEntityType == EntityType.note,
                  title: const Text('Заметки'),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(entityTypeControllerProvider.notifier)
                        .changeEntityType(EntityType.note);
                    logInfo('DashboardScreen: Переход к заметкам');
                  },
                ),

                // Управление OTP
                ListTile(
                  leading: const Icon(Icons.security),
                  selected: currentEntityType == EntityType.otp,
                  title: const Text('OTP'),
                  onTap: () {
                    Navigator.pop(context);
                    ref
                        .read(entityTypeControllerProvider.notifier)
                        .changeEntityType(EntityType.otp);
                    logInfo('DashboardScreen: Переход к OTP');
                  },
                ),

                const Divider(),

                // Управление категориями
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('Категории'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.categoryManager);
                    logInfo('DashboardScreen: Переход к категориям');
                  },
                ),

                // Управление тегами
                ListTile(
                  leading: const Icon(Icons.local_offer),
                  title: const Text('Теги'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.tagsManager);
                    logInfo('DashboardScreen: Переход к тегам');
                  },
                ),

                // Управление иконками
                ListTile(
                  leading: const Icon(Icons.image),
                  title: const Text('Иконки'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.iconManager);
                    logInfo('DashboardScreen: Переход к иконкам');
                  },
                ),

                const Divider(),

                // О приложении
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('О приложении'),
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'Hoplixi',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2025 Hoplixi',
                      applicationIcon: Image.asset(
                        'assets/img/logo.png',
                        width: 48,
                        height: 48,
                      ),
                      children: [
                        const Text(
                          'Hoplixi - это безопасный и удобный менеджер паролей с открытым исходным кодом, разработанный для защиты ваших данных.',
                        ),
                      ],
                    );
                    logInfo(
                      'DashboardScreen: Переход к информации о приложении',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
