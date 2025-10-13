import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:hoplixi/app/theme/theme_switcher.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/shared/widgets/close_database_button.dart';

class DashboardDrawer extends ConsumerWidget {
  const DashboardDrawer({super.key, required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                logInfo('DashboardScreen: Переход к информации о приложении');
              },
            ),
          ],
        ),
      ),
    );
  }
}
