# Провайдеры базы данных Hoplixi Store

Этот документ описывает все провайдеры Riverpod для работы с базой данных Hoplixi Store.

## Структура файлов

- `hoplixi_store_providers.dart` - основной файл со всеми провайдерами
- `providers_index.dart` - индексный файл с экспортами и документацией
- `providers_README.md` - данный документ с подробным описанием

## Категории провайдеров

### 1. Основные провайдеры

#### `hoplixiStoreManagerProvider`
- **Тип**: `Provider<HoplixiStoreManager>`
- **Описание**: Основной менеджер базы данных
- **Использование**: Создание, открытие, закрытие БД

#### `databaseStateProvider` 
- **Тип**: `StateNotifierProvider<DatabaseStateNotifier, DatabaseState>`
- **Описание**: Состояние базы данных (открыта/закрыта/ошибка)
- **Методы нотификатора**:
  - `createDatabase(CreateDatabaseDto)` - создание БД
  - `openDatabase(OpenDatabaseDto)` - открытие БД  
  - `closeDatabase()` - закрытие БД
  - `reset()` - сброс состояния
  - `setError(DatabaseError)` - установка ошибки

### 2. DAO Провайдеры

Все DAO провайдеры требуют открытой базы данных и выбрасывают `DatabaseError.operationFailed` если БД не открыта.

#### Основные DAO
- `passwordsDaoProvider` - управление паролями
- `notesDaoProvider` - управление заметками  
- `categoriesDaoProvider` - управление категориями
- `tagsDaoProvider` - управление тегами
- `totpsDaoProvider` - управление TOTP кодами
- `iconsDaoProvider` - управление иконками
- `attachmentsDaoProvider` - управление вложениями

#### DAO для связей
- `passwordTagsDaoProvider` - связи пароль-тег
- `noteTagsDaoProvider` - связи заметка-тег
- `totpTagsDaoProvider` - связи TOTP-тег

### 3. Stream Провайдеры

Провайдеры для реактивного отслеживания изменений в реальном времени.

#### Общие потоки
- `allPasswordsStreamProvider` - все пароли
- `allNotesStreamProvider` - все заметки
- `allCategoriesStreamProvider` - все категории
- `allTagsStreamProvider` - все теги
- `allTotpsStreamProvider` - все TOTP

#### Специальные потоки
- `favoritePasswordsStreamProvider` - избранные пароли
- `favoriteNotesStreamProvider` - избранные заметки
- `pinnedNotesStreamProvider` - закрепленные заметки
- `favoriteTotpsStreamProvider` - избранные TOTP

### 4. Семейные провайдеры

Параметризованные провайдеры для фильтрации данных.

#### Stream семейства
- `passwordsByCategoryProvider(categoryId)` - пароли по категории
- `notesByCategoryProvider(categoryId)` - заметки по категории
- `totpsByCategoryProvider(categoryId)` - TOTP по категории
- `categoriesByTypeProvider(CategoryType)` - категории по типу
- `tagsByTypeProvider(TagType)` - теги по типу

#### Future семейства
- `passwordTagsProvider(passwordId)` - теги пароля
- `noteTagsProvider(noteId)` - теги заметки
- `totpTagsProvider(totpId)` - теги TOTP
- `searchAllProvider(query)` - поиск по всем типам

### 5. Статистические провайдеры

Провайдеры для получения статистики и метрик.

#### Основная статистика
- `passwordsStatsProvider` - статистика паролей
- `notesStatsProvider` - статистика заметок
- `categoriesStatsProvider` - статистика категорий

#### Общие метрики
- `totalItemsCountProvider` - общее количество элементов
- `hasDatabaseDataProvider` - есть ли данные в БД

### 6. Вспомогательные провайдеры

Удобные провайдеры для проверки состояния.

- `isDatabaseOpenProvider` - открыта ли БД
- `currentDatabasePathProvider` - путь к текущей БД
- `currentDatabaseNameProvider` - имя текущей БД
- `databaseStatusProvider` - статус БД
- `databaseErrorProvider` - текущая ошибка БД

## Примеры использования

### Инициализация базы данных

```dart
class DatabaseSetupWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(databaseStateProvider);
    final notifier = ref.read(databaseStateProvider.notifier);
    
    return switch (state.status) {
      DatabaseStatus.closed => ElevatedButton(
        onPressed: () => _openDatabase(notifier),
        child: Text('Открыть БД'),
      ),
      DatabaseStatus.loading => CircularProgressIndicator(),
      DatabaseStatus.open => Text('БД открыта: ${state.name}'),
      DatabaseStatus.error => Column(
        children: [
          Text('Ошибка: ${state.error}'),
          ElevatedButton(
            onPressed: () => notifier.reset(),
            child: Text('Сбросить'),
          ),
        ],
      ),
      DatabaseStatus.locked => Text('БД заблокирована'),
    };
  }
  
  void _openDatabase(DatabaseStateNotifier notifier) async {
    try {
      await notifier.openDatabase(OpenDatabaseDto(
        path: '/path/to/database.hdb',
        masterPassword: 'password',
      ));
    } catch (e) {
      // Ошибка обработается автоматически
    }
  }
}
```

### Работа с данными

```dart
class PasswordListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordsAsync = ref.watch(allPasswordsStreamProvider);
    
    return passwordsAsync.when(
      data: (passwords) => ListView.builder(
        itemCount: passwords.length,
        itemBuilder: (context, index) {
          final password = passwords[index];
          return ListTile(
            title: Text(password.name),
            subtitle: Text(password.url ?? ''),
            trailing: IconButton(
              icon: Icon(password.isFavorite 
                ? Icons.favorite 
                : Icons.favorite_border),
              onPressed: () => _toggleFavorite(ref, password),
            ),
          );
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка: $error'),
    );
  }
  
  void _toggleFavorite(WidgetRef ref, dynamic password) async {
    final dao = ref.read(passwordsDaoProvider);
    await dao.updatePassword(UpdatePasswordDto(
      id: password.id,
      isFavorite: !password.isFavorite,
    ));
  }
}
```

### Создание данных

```dart
class CreatePasswordWidget extends ConsumerWidget {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: InputDecoration(labelText: 'Название'),
        ),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'Пароль'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: () => _createPassword(ref),
          child: Text('Создать'),
        ),
      ],
    );
  }
  
  void _createPassword(WidgetRef ref) async {
    final dao = ref.read(passwordsDaoProvider);
    
    await dao.createPassword(CreatePasswordDto(
      name: _nameController.text,
      password: _passwordController.text,
    ));
    
    // Очистка полей
    _nameController.clear();
    _passwordController.clear();
  }
}
```

### Фильтрация по категории

```dart
class CategoryPasswordsWidget extends ConsumerWidget {
  final String categoryId;
  
  const CategoryPasswordsWidget({required this.categoryId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordsAsync = ref.watch(
      passwordsByCategoryProvider(categoryId),
    );
    
    return passwordsAsync.when(
      data: (passwords) => ListView.builder(
        itemCount: passwords.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(passwords[index].name),
        ),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка: $error'),
    );
  }
}
```

### Поиск

```dart
class SearchWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends ConsumerState<SearchWidget> {
  final _searchController = TextEditingController();
  String _query = '';
  
  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(
      _query.isNotEmpty ? searchAllProvider(_query) : null,
    );
    
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Поиск',
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: () => setState(() => _query = _searchController.text),
            ),
          ),
        ),
        Expanded(
          child: searchResultsAsync?.when(
            data: (results) => _buildSearchResults(results),
            loading: () => CircularProgressIndicator(),
            error: (error, stack) => Text('Ошибка: $error'),
          ) ?? Container(),
        ),
      ],
    );
  }
  
  Widget _buildSearchResults(SearchResults results) {
    if (results.isEmpty) {
      return Text('Ничего не найдено');
    }
    
    return ListView(
      children: [
        if (results.passwords.isNotEmpty) ...[
          Text('Пароли (${results.passwords.length})'),
          ...results.passwords.map((p) => ListTile(title: Text(p.name))),
        ],
        if (results.notes.isNotEmpty) ...[
          Text('Заметки (${results.notes.length})'),
          ...results.notes.map((n) => ListTile(title: Text(n.title))),
        ],
        if (results.totps.isNotEmpty) ...[
          Text('TOTP (${results.totps.length})'),
          ...results.totps.map((t) => ListTile(title: Text(t.name))),
        ],
      ],
    );
  }
}
```

### Статистика

```dart
class StatsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordsStatsAsync = ref.watch(passwordsStatsProvider);
    final notesStatsAsync = ref.watch(notesStatsProvider);
    final totalCountAsync = ref.watch(totalItemsCountProvider);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статистика базы данных', 
                 style: Theme.of(context).textTheme.headlineSmall),
            SizedBox(height: 16),
            totalCountAsync.when(
              data: (count) => Text('Всего элементов: $count'),
              loading: () => Text('Загрузка...'),
              error: (e, _) => Text('Ошибка: $e'),
            ),
            SizedBox(height: 8),
            passwordsStatsAsync.when(
              data: (stats) => Text('Паролей: ${stats.totalCount}'),
              loading: () => Text('Загрузка паролей...'),
              error: (e, _) => Text('Ошибка паролей: $e'),
            ),
            SizedBox(height: 8),
            notesStatsAsync.when(
              data: (stats) => Text('Заметок: ${stats.totalCount}'),
              loading: () => Text('Загрузка заметок...'),
              error: (e, _) => Text('Ошибка заметок: $e'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Обработка ошибок

Все провайдеры правильно обрабатывают ошибки:

1. **DAO провайдеры** выбрасывают `DatabaseError.operationFailed` если БД не открыта
2. **Stream провайдеры** передают ошибки через `AsyncError`
3. **Future провайдеры** возвращают безопасные значения по умолчанию при ошибках

### Централизованная обработка ошибок

```dart
class DatabaseErrorHandler extends ConsumerWidget {
  final Widget child;
  
  const DatabaseErrorHandler({required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = ref.watch(databaseErrorProvider);
    
    if (error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Ошибка базы данных'),
              Text(error.displayMessage),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(databaseStateProvider.notifier).reset(),
                child: Text('Сбросить'),
              ),
            ],
          ),
        ),
      );
    }
    
    return child;
  }
}
```

## Лучшие практики

### 1. Проверка состояния БД

Всегда проверяйте состояние базы данных перед использованием:

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final isOpen = ref.watch(isDatabaseOpenProvider);
  
  if (!isOpen) {
    return DatabaseClosedWidget();
  }
  
  // Используйте провайдеры только здесь
  final data = ref.watch(someDataProvider);
  return DataWidget(data);
}
```

### 2. Обработка загрузки

Используйте `when` для обработки всех состояний:

```dart
final dataAsync = ref.watch(someStreamProvider);

return dataAsync.when(
  data: (data) => DataWidget(data),
  loading: () => LoadingWidget(),
  error: (error, stack) => ErrorWidget(error.toString()),
);
```

### 3. Очистка ресурсов

Провайдеры автоматически очищают ресурсы, но следите за жизненным циклом:

```dart
@override
void dispose() {
  // Riverpod автоматически очистит провайдеры
  super.dispose();
}
```

### 4. Оптимизация производительности

- Используйте `ref.read()` для одноразовых операций
- Используйте `ref.watch()` для отслеживания изменений
- Предпочитайте stream провайдеры для реактивных данных

## Отладка

Для отладки используйте встроенное логирование:

```dart
// Логи автоматически записываются в консоль
// Теги для фильтрации:
// - 'DatabaseProviders' - общие операции провайдеров
// - 'DatabaseStateNotifier' - операции с состоянием БД
```

Включите наблюдатель провайдеров в `main.dart`:

```dart
class ProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    print('[${provider.name ?? provider.runtimeType}] $newValue');
  }
}

void main() {
  runApp(
    ProviderScope(
      observers: [ProviderLogger()],
      child: MyApp(),
    ),
  );
}
```
