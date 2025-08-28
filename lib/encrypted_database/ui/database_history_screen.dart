import 'package:flutter/material.dart';
import 'package:hoplixi/encrypted_database/encrypted_database_manager.dart';
import 'package:hoplixi/encrypted_database/dto/db_dto.dart';
import 'package:hoplixi/core/secure_storage/secure_storage_models.dart';

/// Пример экрана для демонстрации функционала истории баз данных
class DatabaseHistoryScreen extends StatefulWidget {
  const DatabaseHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DatabaseHistoryScreen> createState() => _DatabaseHistoryScreenState();
}

class _DatabaseHistoryScreenState extends State<DatabaseHistoryScreen> {
  final EncryptedDatabaseManager _dbManager = EncryptedDatabaseManager();
  List<DatabaseEntry> _allDatabases = [];
  List<DatabaseEntry> _recentDatabases = [];
  List<DatabaseEntry> _favoriteDatabases = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeManager();
  }

  Future<void> _initializeManager() async {
    try {
      await _loadData();
    } catch (e) {
      _showErrorSnackBar('Ошибка инициализации: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _dbManager.getAllDatabases(),
        _dbManager.getRecentDatabases(limit: 5),
        _dbManager.getFavoriteDatabases(),
        _dbManager.getDatabaseHistoryStatistics(),
      ]);

      setState(() {
        _allDatabases = results[0] as List<DatabaseEntry>;
        _recentDatabases = results[1] as List<DatabaseEntry>;
        _favoriteDatabases = results[2] as List<DatabaseEntry>;
        _statistics = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки данных: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _toggleFavorite(DatabaseEntry database) async {
    try {
      await _dbManager.setDatabaseFavorite(database.path, !database.isFavorite);
      _showSuccessSnackBar(
        database.isFavorite ? 'Удалено из избранного' : 'Добавлено в избранное',
      );
      await _loadData();
    } catch (e) {
      _showErrorSnackBar('Ошибка изменения статуса избранного: $e');
    }
  }

  Future<void> _removeSavedPassword(DatabaseEntry database) async {
    try {
      await _dbManager.removeSavedMasterPassword(database.path);
      _showSuccessSnackBar('Сохраненный пароль удален');
      await _loadData();
    } catch (e) {
      _showErrorSnackBar('Ошибка удаления пароля: $e');
    }
  }

  Future<void> _removeFromHistory(DatabaseEntry database) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить из истории'),
        content: Text(
          'Удалить "${database.name}" из истории? '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbManager.removeDatabaseFromHistory(database.path);
        _showSuccessSnackBar('База данных удалена из истории');
        await _loadData();
      } catch (e) {
        _showErrorSnackBar('Ошибка удаления из истории: $e');
      }
    }
  }

  Future<void> _tryAutoLogin(DatabaseEntry database) async {
    try {
      final result = await _dbManager.openWithAutoLogin(database.path);
      if (result != null) {
        _showSuccessSnackBar('База данных открыта автоматически!');
        await _loadData(); // Обновляем время последнего доступа
      } else {
        _showErrorSnackBar('Автологин невозможен. Требуется ввод пароля.');
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка автологина: $e');
    }
  }

  Future<void> _createTestDatabase() async {
    try {
      final dto = CreateDatabaseDto(
        name: 'TestDB_${DateTime.now().millisecondsSinceEpoch}',
        masterPassword: 'test_password_123',
        description: 'Тестовая база данных, созданная из UI',
      );

      await _dbManager.createDatabase(dto);
      _showSuccessSnackBar('Тестовая база данных создана!');
      await _loadData();
    } catch (e) {
      _showErrorSnackBar('Ошибка создания тестовой базы: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История баз данных'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createTestDatabase,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),
                  _buildRecentDatabasesCard(),
                  const SizedBox(height: 16),
                  _buildFavoriteDatabasesCard(),
                  const SizedBox(height: 16),
                  _buildAllDatabasesCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Всего баз данных: ${_statistics['total'] ?? 0}'),
            Text('Избранных: ${_statistics['favorites'] ?? 0}'),
            Text(
              'С сохраненными паролями: ${_statistics['withSavedPasswords'] ?? 0}',
            ),
            Text(
              'Использованных сегодня: ${_statistics['accessedToday'] ?? 0}',
            ),
            Text(
              'Использованных на этой неделе: ${_statistics['accessedThisWeek'] ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDatabasesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Недавние базы данных',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_recentDatabases.isEmpty)
              const Text('Нет недавних баз данных')
            else
              ..._recentDatabases.map((db) => _buildDatabaseTile(db)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteDatabasesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Избранные базы данных',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_favoriteDatabases.isEmpty)
              const Text('Нет избранных баз данных')
            else
              ..._favoriteDatabases
                  .map((db) => _buildDatabaseTile(db))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllDatabasesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Все базы данных',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_allDatabases.isEmpty)
              const Text('История пуста')
            else
              ..._allDatabases.map((db) => _buildDatabaseTile(db)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseTile(DatabaseEntry database) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          database.isFavorite ? Icons.star : Icons.storage,
          color: database.isFavorite ? Colors.amber : null,
        ),
        title: Text(database.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(database.path),
            Text(
              'Последний доступ: ${database.lastAccessed.toLocal().toString().split('.')[0]}',
              style: const TextStyle(fontSize: 12),
            ),
            if (database.description != null)
              Text(
                database.description!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'favorite':
                await _toggleFavorite(database);
                break;
              case 'auto_login':
                await _tryAutoLogin(database);
                break;
              case 'remove_password':
                await _removeSavedPassword(database);
                break;
              case 'remove_history':
                await _removeFromHistory(database);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'favorite',
              child: Text(
                database.isFavorite
                    ? 'Убрать из избранного'
                    : 'Добавить в избранное',
              ),
            ),
            if (database.isMasterPasswordSaved)
              const PopupMenuItem(
                value: 'auto_login',
                child: Text('Открыть с автологином'),
              ),
            if (database.isMasterPasswordSaved)
              const PopupMenuItem(
                value: 'remove_password',
                child: Text('Удалить сохраненный пароль'),
              ),
            const PopupMenuItem(
              value: 'remove_history',
              child: Text('Удалить из истории'),
            ),
          ],
        ),
        isThreeLine: database.description != null,
      ),
    );
  }

  @override
  void dispose() {
    _dbManager.dispose();
    super.dispose();
  }
}

/// Простой пример экрана выбора базы данных из истории
class DatabasePickerScreen extends StatefulWidget {
  const DatabasePickerScreen({Key? key}) : super(key: key);

  @override
  State<DatabasePickerScreen> createState() => _DatabasePickerScreenState();
}

class _DatabasePickerScreenState extends State<DatabasePickerScreen> {
  final EncryptedDatabaseManager _dbManager = EncryptedDatabaseManager();
  List<DatabaseEntry> _databases = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDatabases();
  }

  Future<void> _loadDatabases() async {
    try {
      final databases = await _dbManager.getAllDatabases();
      setState(() {
        _databases = databases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    }
  }

  List<DatabaseEntry> get _filteredDatabases {
    if (_searchQuery.isEmpty) return _databases;

    return _databases
        .where(
          (db) =>
              db.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              db.path.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (db.description?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбрать базу данных'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск баз данных...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredDatabases.isEmpty
          ? const Center(child: Text('Нет баз данных'))
          : ListView.builder(
              itemCount: _filteredDatabases.length,
              itemBuilder: (context, index) {
                final database = _filteredDatabases[index];
                return ListTile(
                  leading: Icon(
                    database.isFavorite ? Icons.star : Icons.storage,
                    color: database.isFavorite ? Colors.amber : null,
                  ),
                  title: Text(database.name),
                  subtitle: Text(database.path),
                  trailing: database.isMasterPasswordSaved
                      ? const Icon(Icons.key, color: Colors.green)
                      : null,
                  onTap: () => Navigator.pop(context, database),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final path = await _dbManager.pickDatabaseFile();
          if (path != null) {
            // Проверяем, есть ли база в истории
            final dbInfo = await _dbManager.getDatabaseInfo(path);
            final database =
                dbInfo ??
                DatabaseEntry(
                  id: path.hashCode.toString(),
                  name: path.split('/').last,
                  path: path,
                  lastAccessed: DateTime.now(),
                );
            Navigator.pop(context, database);
          }
        },
        child: const Icon(Icons.folder_open),
      ),
    );
  }

  @override
  void dispose() {
    _dbManager.dispose();
    super.dispose();
  }
}
