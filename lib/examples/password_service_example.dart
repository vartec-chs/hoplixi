import 'package:flutter/material.dart';
import '../hoplixi_store/services/password_service.dart';
import '../hoplixi_store/dto/db_dto.dart';
import '../hoplixi_store/hoplixi_store.dart';

/// Пример использования PasswordService в UI
class PasswordServiceExample extends StatefulWidget {
  final HoplixiStore database;

  const PasswordServiceExample({super.key, required this.database});

  @override
  State<PasswordServiceExample> createState() => _PasswordServiceExampleState();
}

class _PasswordServiceExampleState extends State<PasswordServiceExample> {
  late final PasswordService _passwordService;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _statusMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordService = PasswordService(widget.database);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Создание нового пароля
  Future<void> _createPassword() async {
    if (_nameController.text.isEmpty || _passwordController.text.isEmpty) {
      _setStatus('Заполните обязательные поля');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dto = CreatePasswordDto(
        name: _nameController.text,
        password: _passwordController.text,
        url: _urlController.text.isNotEmpty ? _urlController.text : null,
        description: 'Создано через пример UI',
        isFavorite: false,
      );

      final result = await _passwordService.createPassword(dto);

      if (result.success) {
        _setStatus('✅ ${result.message}');
        _clearFields();
      } else {
        _setStatus('❌ ${result.message}');
      }
    } catch (e) {
      _setStatus('❌ Ошибка: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Поиск паролей
  Future<void> _searchPasswords() async {
    if (_searchController.text.isEmpty) {
      _setStatus('Введите текст для поиска');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _passwordService.searchPasswords(
        searchTerm: _searchController.text,
        limit: 10,
      );

      if (result.success) {
        final passwords = result.data!;
        _setStatus('🔍 Найдено паролей: ${passwords.length}');

        // Показываем результаты в диалоге
        if (mounted) {
          _showSearchResults(passwords);
        }
      } else {
        _setStatus('❌ ${result.message}');
      }
    } catch (e) {
      _setStatus('❌ Ошибка поиска: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Получение статистики
  Future<void> _getStatistics() async {
    setState(() => _isLoading = true);

    try {
      final result = await _passwordService.getPasswordStatistics();

      if (result.success) {
        final stats = result.data!;
        _setStatus(
          '📊 Всего паролей: ${stats.totalCount}, избранных: ${stats.favoriteCount}',
        );

        // Показываем подробную статистику
        if (mounted) {
          _showStatistics(stats);
        }
      } else {
        _setStatus('❌ ${result.message}');
      }
    } catch (e) {
      _setStatus('❌ Ошибка получения статистики: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setStatus(String message) {
    setState(() => _statusMessage = message);
  }

  void _clearFields() {
    _nameController.clear();
    _passwordController.clear();
    _urlController.clear();
  }

  void _showSearchResults(List<PasswordWithDetails> passwords) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Результаты поиска'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: passwords.length,
            itemBuilder: (context, index) {
              final password = passwords[index];
              return ListTile(
                title: Text(password.password.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (password.password.url != null)
                      Text('URL: ${password.password.url}'),
                    if (password.category != null)
                      Text('Категория: ${password.category!.name}'),
                    if (password.tags.isNotEmpty)
                      Text(
                        'Теги: ${password.tags.map((t) => t.name).join(', ')}',
                      ),
                    Text('История: ${password.historyCount} записей'),
                  ],
                ),
                trailing: password.password.isFavorite
                    ? const Icon(Icons.star, color: Colors.amber)
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(PasswordStatistics stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Статистика паролей'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Всего паролей: ${stats.totalCount}'),
            Text('Избранных: ${stats.favoriteCount}'),
            const SizedBox(height: 16),
            const Text(
              'По категориям:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...stats.countByCategory.entries.map(
              (entry) => Text('  ${entry.key}: ${entry.value}'),
            ),
            const SizedBox(height: 16),
            const Text(
              'По тегам:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...stats.countByTag.entries
                .take(5)
                .map((entry) => Text('  ${entry.key}: ${entry.value}')),
            if (stats.countByTag.length > 5)
              Text('  ... и еще ${stats.countByTag.length - 5} тегов'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Service Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Статус
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusMessage.startsWith('✅')
                    ? Colors.green.withOpacity(0.1)
                    : _statusMessage.startsWith('❌')
                    ? Colors.red.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _statusMessage.startsWith('✅')
                      ? Colors.green
                      : _statusMessage.startsWith('❌')
                      ? Colors.red
                      : Colors.blue,
                ),
              ),
              child: Text(
                _statusMessage.isEmpty ? 'Готов к работе' : _statusMessage,
                style: TextStyle(
                  color: _statusMessage.startsWith('✅')
                      ? Colors.green.shade700
                      : _statusMessage.startsWith('❌')
                      ? Colors.red.shade700
                      : Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Форма создания пароля
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Создание пароля',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Название *',
                        hintText: 'Например: Gmail, Facebook',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Пароль *',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL (необязательно)',
                        hintText: 'https://example.com',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createPassword,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Создать пароль'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Поиск
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Поиск паролей',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Поисковый запрос',
                        hintText: 'Название, URL, логин или email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _searchPasswords,
                        child: const Text('Найти пароли'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Статистика
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _getStatistics,
                icon: const Icon(Icons.analytics),
                label: const Text('Показать статистику'),
              ),
            ),
            const SizedBox(height: 20),

            // Stream пример - список всех паролей
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Все пароли (Stream)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder(
                          stream: _passwordService.watchAllPasswords(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Ошибка: ${snapshot.error}'),
                              );
                            }

                            final passwords = snapshot.data ?? [];

                            if (passwords.isEmpty) {
                              return const Center(
                                child: Text('Пароли не найдены'),
                              );
                            }

                            return ListView.builder(
                              itemCount: passwords.length,
                              itemBuilder: (context, index) {
                                final password = passwords[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text(password.name[0].toUpperCase()),
                                  ),
                                  title: Text(password.name),
                                  subtitle: Text(
                                    password.url ?? 'Без URL',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: password.isFavorite
                                      ? const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                        )
                                      : null,
                                  onTap: () async {
                                    // Получаем детали пароля
                                    final result = await _passwordService
                                        .getPasswordDetails(password.id);
                                    if (result.success && mounted) {
                                      _showPasswordDetails(result.data!);
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDetails(PasswordWithDetails details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(details.password.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.password.description != null)
              Text('Описание: ${details.password.description}'),
            if (details.password.url != null)
              Text('URL: ${details.password.url}'),
            if (details.password.login != null)
              Text('Логин: ${details.password.login}'),
            if (details.password.email != null)
              Text('Email: ${details.password.email}'),
            if (details.category != null)
              Text('Категория: ${details.category!.name}'),
            if (details.tags.isNotEmpty)
              Text('Теги: ${details.tags.map((t) => t.name).join(', ')}'),
            Text('История: ${details.historyCount} записей'),
            Text('Создан: ${details.password.createdAt}'),
            Text('Изменен: ${details.password.modifiedAt}'),
            if (details.password.lastAccessed != null)
              Text('Последний доступ: ${details.password.lastAccessed}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
