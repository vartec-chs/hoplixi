import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/global/widgets/close_database_button.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/theme_switcher.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entety_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/entety_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/lists_providers/paginated_passwords_provider.dart';
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
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final entityType = ref.read(currentEntityTypeProvider);

    // Пагинация только для паролей пока что
    if (entityType != EntityType.password) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Загружаем больше данных когда до конца остается 200 пикселей
      ref.read(paginatedPasswordsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDatabaseOpen = ref.watch(isDatabaseOpenProvider);
    final dbNotifier = ref.read(hoplixiStoreProvider.notifier);
    return PopScope(
      canPop: false, // если false → блокирует закрытие
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          logInfo('Экран закрыт, результат: $result', tag: 'DashboardScreen');
        } else {
          logInfo('Попытка закрыть, но не получилось', tag: 'DashboardScreen');
          if (isDatabaseOpen) {
            final shouldClose = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Подтверждение'),
                content: const Text(
                  'Вы хотите закрыть приложение? Это закроет базу данных.',
                ),
                actions: [
                  TextButton(
                    child: const Text('Отмена'),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  TextButton(
                    child: const Text('Закрыть'),
                    onPressed: () => Navigator.pop(context, true),
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
                    expandedHeight: 180.0,
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
                  _onCreatePassword();
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
              onCreateCategory: _onCreateCategory,
              onCreateTag: _onCreateTag,
              onIconCreate: _onCreateIcon,
              importOtpCodes: currentEntityType == EntityType.otp
                  ? () {
                      logInfo('DashboardScreen: Импорт OTP кодов');
                      context.push(AppRoutes.importOtpCodes);
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final currentEntityType = ref.watch(currentEntityTypeProvider);
        return Drawer(
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

              // Настройки
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Настройки'),
                onTap: () {
                  Navigator.pop(context);
                  // context.go('/settings');
                  logInfo('DashboardScreen: Переход к настройкам');
                },
              ),

              // Помощь
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Помощь'),
                onTap: () {
                  Navigator.pop(context);
                  // context.go('/help');
                  logInfo('DashboardScreen: Переход к помощи');
                },
              ),

              // О приложении
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('О приложении'),
                onTap: () {
                  Navigator.pop(context);
                  // context.go('/about');
                  logInfo('DashboardScreen: Переход к информации о приложении');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onCreatePassword() {
    logInfo('DashboardScreen: Создание нового пароля');
    context.push(AppRoutes.passwordForm);
  }

  void _onCreateCategory() {
    logInfo('DashboardScreen: Переход к созданию категории');
    context.push(AppRoutes.categoryManager);
  }

  void _onCreateTag() {
    logInfo('DashboardScreen: Переход к созданию тега');
    context.push(AppRoutes.tagsManager);
  }

  void _onCreateIcon() {
    logInfo('DashboardScreen: Переход к созданию иконки');
    context.push(AppRoutes.iconManager);
  }
}
