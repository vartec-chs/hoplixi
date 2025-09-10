import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'widgets/password_card.dart';
import 'widgets/filter_modal.dart';
import 'widgets/expandable_fab.dart';
import '../../../common/text_field.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'all';
  String _searchQuery = '';

  // Mock data for passwords
  final List<Map<String, dynamic>> _passwords = [
    {
      'id': '1',
      'title': 'Google Account',
      'description': 'Основной аккаунт Google для работы и личных дел',
      'login': 'user@gmail.com',
      'password': '********',
      'url': 'https://google.com',
      'category': 'Email',
      'isFavorite': true,
    },
    {
      'id': '2',
      'title': 'GitHub',
      'description': 'Профессиональный аккаунт для разработки',
      'login': 'developer123',
      'password': '********',
      'url': 'https://github.com',
      'category': 'Development',
      'isFavorite': false,
    },
    {
      'id': '3',
      'title': 'Banking App',
      'description': 'Мобильное приложение банка для управления финансами',
      'login': 'client789',
      'password': '********',
      'url': 'https://bank.com',
      'category': 'Finance',
      'isFavorite': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index == 0 ? 'all' : 'favorites';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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

  void _showFilterModal() {
    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      // Show bottom sheet on mobile
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const FilterModal(),
      );
    } else {
      // Show dialog on desktop
      showDialog(
        context: context,
        builder: (context) =>
            Dialog(child: Container(child: const FilterModal())),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredPasswords {
    var filtered = _passwords;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (password) =>
                password['title'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                password['description'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                password['login'].toString().toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    // Filter by tab selection
    if (_selectedTab == 'favorites') {
      filtered = filtered.where((password) => password['isFavorite']).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      child: Scaffold(
        drawer: _buildDrawer(),
        body: CustomScrollView(
          slivers: [
            // SliverAppBar for search
            SliverAppBar(
              expandedHeight: 114.0,
              floating: true,
              pinned: false,
              snap: false,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Theme.of(context).colorScheme.surface,
              leading: Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  tooltip: 'Меню',
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _showFilterModal,
                    icon: Icon(
                      Icons.tune,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    tooltip: 'Фильтры',
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 60.0,
                    bottom: 4.0,
                  ),
                  child: PrimaryTextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    hintText: 'Поиск паролей...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ),
            // SliverAppBar for tabs
            SliverAppBar(
              // expandedHeight: 40,
              collapsedHeight: 60.0,
              floating: false,
              pinned: false,
              snap: false,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Theme.of(context).colorScheme.surface,
              automaticallyImplyLeading: false,
              flexibleSpace: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.shadow.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Theme.of(context).colorScheme.onSecondary,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  labelStyle: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'Все', height: 40),
                    Tab(text: 'Избранные', height: 40),
                  ],
                ),
              ),
            ),
            // Password List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: _filteredPasswords.isEmpty
                  ? SliverToBoxAdapter(
                      child: SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Ничего не найдено'
                                    : _selectedTab == 'favorites'
                                    ? 'Нет избранных паролей'
                                    : 'Нет паролей',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final password = _filteredPasswords[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: PasswordCard(
                            password: password,
                            onFavoriteToggle: (id) {
                              setState(() {
                                final passwordIndex = _passwords.indexWhere(
                                  (p) => p['id'] == id,
                                );
                                if (passwordIndex != -1) {
                                  _passwords[passwordIndex]['isFavorite'] =
                                      !_passwords[passwordIndex]['isFavorite'];
                                }
                              });
                            },
                            onEdit: (id) {
                              // TODO: Implement edit functionality
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Редактирование пароля $id'),
                                ),
                              );
                            },
                          ),
                        );
                      }, childCount: _filteredPasswords.length),
                    ),
            ),
            // Bottom spacing for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        floatingActionButton: ExpandableFAB(
          onCreatePassword: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Создать пароль')));
          },
          onCreateCategory: () {
            context.push(AppRoutes.categoryManager);
          },
          onIconCreate: () => context.push(AppRoutes.iconManager),
          onCreateTag: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Создать тег')));
          },
        ),
      ),
    );
  }
}
