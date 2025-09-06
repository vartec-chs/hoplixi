import 'package:flutter/material.dart';
import 'widgets/search_header.dart';
import 'widgets/tab_bar_section.dart';
import 'widgets/password_card.dart';
import 'widgets/filter_modal.dart';
import 'widgets/expandable_fab.dart';

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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Hoplixi',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
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
            Dialog(child: Container(width: 400, child: const FilterModal())),
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
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Search Header
              SliverToBoxAdapter(
                child: Builder(
                  builder: (context) => SearchHeader(
                    controller: _searchController,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onDrawerPressed: () => Scaffold.of(context).openDrawer(),
                    onFilterPressed: _showFilterModal,
                  ),
                ),
              ),
              // Tab Bar Section
              SliverToBoxAdapter(
                child: TabBarSection(controller: _tabController),
              ),
              // Password List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: _filteredPasswords.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          height: 200,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 48,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
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
        ),
        floatingActionButton: ExpandableFAB(
          onCreatePassword: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Создать пароль')));
          },
          onCreateCategory: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Создать категорию')));
          },
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
