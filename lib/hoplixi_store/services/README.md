# Документация по сервисам метаданных

Созданы удобные сервисы для работы с категориями, иконками и тегами в UI приложения Hoplixi.

## Структура сервисов

### 1. ServiceResult<T> - Базовый класс результатов
```dart
class ServiceResult<T> {
  final bool success;
  final String? message;
  final T? data;
}
```

### 2. CategoriesService - Сервис для работы с категориями
```dart
// Создание категории
final result = await categoriesService.createCategory(
  name: 'Социальные сети',
  description: 'Пароли от социальных сетей',
  color: '#2196F3',
  type: CategoryType.password,
);

if (result.success) {
  print('Категория создана: ${result.categoryId}');
} else {
  print('Ошибка: ${result.message}');
}

// Получение всех категорий
final categories = await categoriesService.getAllCategories();

// Поиск категорий
final searchResults = await categoriesService.searchCategories('соц');

// Stream для отслеживания изменений
categoriesService.watchAllCategories().listen((categories) {
  // Обновление UI
});
```

### 3. IconsService - Сервис для работы с иконками
```dart
// Создание иконки
final result = await iconsService.createIcon(
  name: 'Facebook Icon',
  type: IconType.png,
  data: iconBytes,
);

// Получение статистики
final stats = await iconsService.getIconsStats();
print('Общий размер иконок: ${stats['totalSize']} байт');

// Очистка неиспользуемых иконок
final cleanupResult = await iconsService.cleanupUnusedIcons();
print('Удалено иконок: ${cleanupResult.message}');
```

### 4. TagsService - Сервис для работы с тегами
```dart
// Создание тега
final result = await tagsService.createTag(
  name: 'Важные',
  color: '#F44336',
  type: TagType.mixed,
);

// Получение популярных тегов
final popularTags = await tagsService.getPopularTags(limit: 5);

// Получение предложений тегов
final suggestions = await tagsService.getTagSuggestions('ва', type: TagType.password);
```

### 5. MetadataService - Объединенный сервис
```dart
// Инициализация
final metadataService = MetadataService.create(database);

// Доступ к подсервисам
final categoriesService = metadataService.categories;
final iconsService = metadataService.icons;
final tagsService = metadataService.tags;

// Общая статистика
final stats = await metadataService.getOverallStats();

// Поиск по всем типам
final searchResults = await metadataService.searchAll('facebook');

// Рекомендации для UI
final recommendations = await metadataService.getRecommendations();

// Валидация целостности
final validation = await metadataService.validateIntegrity();
if (!validation['isValid']) {
  print('Проблемы: ${validation['issues']}');
  print('Предложения: ${validation['suggestions']}');
}
```

## Примеры использования в Flutter UI

### Создание формы добавления категории
```dart
class AddCategoryDialog extends StatefulWidget {
  final CategoriesService categoriesService;
  
  const AddCategoryDialog({Key? key, required this.categoriesService}) : super(key: key);
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  CategoryType _selectedType = CategoryType.mixed;
  String _selectedColor = '#2196F3';
  bool _isLoading = false;

  Future<void> _createCategory() async {
    setState(() => _isLoading = true);
    
    final result = await widget.categoriesService.createCategory(
      name: _nameController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      color: _selectedColor,
      type: _selectedType,
    );
    
    setState(() => _isLoading = false);
    
    if (result.success) {
      Navigator.of(context).pop(result.categoryId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### Список категорий с поиском
```dart
class CategoriesListView extends StatefulWidget {
  final CategoriesService categoriesService;
  
  const CategoriesListView({Key? key, required this.categoriesService}) : super(key: key);
}

class _CategoriesListViewState extends State<CategoriesListView> {
  final _searchController = TextEditingController();
  List<Category> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchCategories(_searchController.text);
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final categories = await widget.categoriesService.getAllCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  Future<void> _searchCategories(String query) async {
    setState(() => _isLoading = true);
    final categories = await widget.categoriesService.searchCategories(query);
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Поиск категорий...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ListTile(
                    title: Text(category.name),
                    subtitle: category.description != null 
                      ? Text(category.description!) 
                      : null,
                    leading: CircleAvatar(
                      backgroundColor: Color(int.parse(category.color.substring(1), radix: 16) + 0xFF000000),
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Редактировать'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Удалить'),
                        ),
                      ],
                      onSelected: (value) => _handleMenuAction(value, category),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, Category category) async {
    switch (action) {
      case 'edit':
        // Открыть диалог редактирования
        break;
      case 'delete':
        final confirmed = await _showDeleteConfirmation(category.name);
        if (confirmed) {
          final result = await widget.categoriesService.deleteCategory(category.id);
          if (result.success) {
            _loadCategories(); // Перезагрузить список
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message!)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message!),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        break;
    }
  }

  Future<bool> _showDeleteConfirmation(String categoryName) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение удаления'),
        content: Text('Вы уверены, что хотите удалить категорию "$categoryName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    ) ?? false;
  }
}
```

### Статистическая панель
```dart
class MetadataStatsPanel extends StatefulWidget {
  final MetadataService metadataService;
  
  const MetadataStatsPanel({Key? key, required this.metadataService}) : super(key: key);
}

class _MetadataStatsPanelState extends State<MetadataStatsPanel> {
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _recommendations;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final stats = await widget.metadataService.getOverallStats();
    final recommendations = await widget.metadataService.getRecommendations();
    
    setState(() {
      _stats = stats;
      _recommendations = recommendations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final summary = _stats!['summary'];
    final cleanup = _recommendations!['cleanup'];

    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Общая статистика', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Категории', summary['totalCategories']),
                      _buildStatItem('Иконки', summary['totalIcons']),
                      _buildStatItem('Теги', summary['totalTags']),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (cleanup['canCleanup'])
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Рекомендации', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (cleanup['unusedTagsCount'] > 0)
                      Text('• ${cleanup['unusedTagsCount']} неиспользуемых тегов'),
                    if (cleanup['unusedIconsCount'] > 0)
                      Text('• ${cleanup['unusedIconsCount']} неиспользуемых иконок'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _performCleanup,
                      child: const Text('Выполнить очистку'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(value.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }

  Future<void> _performCleanup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение очистки'),
        content: const Text('Вы уверены, что хотите удалить неиспользуемые элементы?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Очистить'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      final results = await widget.metadataService.cleanupUnused();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(results['overall']['message'])),
      );
      
      if (results['overall']['success']) {
        _loadData(); // Перезагрузить данные
      }
    }
  }
}
```

## Особенности реализации

1. **Валидация данных** - все сервисы включают валидацию входных данных
2. **Обработка ошибок** - используется логирование и возвращение понятных сообщений об ошибках
3. **Асинхронность** - все операции асинхронные для не блокирования UI
4. **Streams** - поддержка реактивного программирования для отслеживания изменений
5. **Batch операции** - поддержка массовых операций для производительности
6. **Кэширование** - результаты можно кэшировать на уровне UI

## Интеграция с блоками состояния

Сервисы можно легко интегрировать с Bloc/Cubit:

```dart
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final CategoriesService _categoriesService;

  CategoriesBloc(this._categoriesService) : super(CategoriesInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SearchCategories>(_onSearchCategories);
    on<CreateCategory>(_onCreateCategory);
  }

  Future<void> _onLoadCategories(LoadCategories event, Emitter<CategoriesState> emit) async {
    emit(CategoriesLoading());
    try {
      final categories = await _categoriesService.getAllCategories();
      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(CategoriesError(e.toString()));
    }
  }
}
```
