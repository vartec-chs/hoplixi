import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard_old/features/filter_section/filter_section.dart';
import 'package:hoplixi/features/password_manager/dashboard_old/features/passwords_list/passwords_list_barrel.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'widgets/expandable_fab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  Widget _buildDrawer() {
    return Drawer(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: Text(
              'Hoplixi',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),

            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Настройки')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Резервное копирование'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Резервное копирование')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Безопасность'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Безопасность')));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    return PopScope(
      child: Scaffold(
        drawer: _buildDrawer(),
        body: RefreshIndicator(
          onRefresh: () async {
            // Обновляем список паролей через новый provider
            await ref
                .read(passwordsListControllerProvider.notifier)
                .refreshPasswords();
          },
          child: SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                Builder(
                  builder: (scaffoldContext) => FilterSection(
                    onMenuPressed: () =>
                        Scaffold.of(scaffoldContext).openDrawer(),
                    pinned: true,
                    floating: false,
                    snap: false,
                    expandedHeight: 162.0,
                    collapsedHeight: 60.0,
                  ),
                ),
                PasswordsList(scrollController: _scrollController),
                // Password List
                // SliverPadding(
                //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                //   sliver: _filteredPasswords.isEmpty
                //       ? SliverToBoxAdapter(
                //           child: SizedBox(
                //             height: 200,
                //             child: Center(
                //               child: Column(
                //                 mainAxisAlignment: MainAxisAlignment.center,
                //                 children: [
                //                   Icon(
                //                     Icons.search_off,
                //                     size: 48,
                //                     color: theme.colorScheme.onSurface.withOpacity(
                //                       0.6,
                //                     ),
                //                   ),
                //                   const SizedBox(height: 16),
                //                   Text(
                //                     _searchQuery.isNotEmpty
                //                         ? 'Ничего не найдено'
                //                         : _selectedTab == 'favorites'
                //                         ? 'Нет избранных паролей'
                //                         : 'Нет паролей',
                //                     style: theme.textTheme.bodyLarge?.copyWith(
                //                       color: theme.colorScheme.onSurface
                //                           .withOpacity(0.6),
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //         )
                //       : SliverList(
                //           delegate: SliverChildBuilderDelegate((context, index) {
                //             final password = _filteredPasswords[index];
                //             return Padding(
                //               padding: const EdgeInsets.only(bottom: 12.0),
                //               child: PasswordCard(
                //                 password: password,
                //                 onFavoriteToggle: (id) {
                //                   setState(() {
                //                     final passwordIndex = _passwords.indexWhere(
                //                       (p) => p['id'] == id,
                //                     );
                //                     if (passwordIndex != -1) {
                //                       _passwords[passwordIndex]['isFavorite'] =
                //                           !_passwords[passwordIndex]['isFavorite'];
                //                     }
                //                   });
                //                 },
                //                 onEdit: (id) {
                //                   // TODO: Implement edit functionality
                //                   ScaffoldMessenger.of(context).showSnackBar(
                //                     SnackBar(
                //                       content: Text('Редактирование пароля $id'),
                //                     ),
                //                   );
                //                 },
                //               ),
                //             );
                //           }, childCount: _filteredPasswords.length),
                //         ),
                // ),
                // // Bottom spacing for FAB
                // const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
        floatingActionButton: ExpandableFAB(
          onCreatePassword: () => {context.push(AppRoutes.passwordForm)},
          onCreateCategory: () => {context.push(AppRoutes.categoryManager)},
          onIconCreate: () => {context.push(AppRoutes.iconManager)},
          onCreateTag: () => {context.push(AppRoutes.tagsManager)},
        ),
      ),
    );
  }
}
