import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_drawer.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/shared/widgets/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entety_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/entety_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_app_bar.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_list_view.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/expandable_fab.dart';
import 'package:hoplixi/hoplixi_store/providers/providers.dart';
import 'package:hoplixi/app/router/routes_path.dart';

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
          child: SensitiveContent(
            sensitivity: ContentSensitivity.sensitive,
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
              drawer: DashboardDrawer(context: context),

              // Expandable FAB для создания новых сущностей
              floatingActionButton: Consumer(
                builder: (context, ref, child) {
                  final currentEntityType = ref.watch(
                    currentEntityTypeProvider,
                  );
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
      ),
    );
  }
}
