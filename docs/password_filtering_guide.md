# Руководство по фильтрации паролей

Это руководство объясняет, как использовать `PasswordFilter` для мощной фильтрации карточек паролей в приложении Hoplixi.

## Обзор

Система фильтрации построена на трех основных компонентах:

1. **PasswordFilter** - модель фильтра с всеми параметрами
2. **PasswordsDao** - методы для выполнения фильтрации на уровне БД
3. **PasswordService** - удобные методы для использования в UI

## Основные возможности PasswordFilter

### Поиск по тексту
```dart
final filter = PasswordFilter.create(
  query: 'gmail', // поиск в названии, URL, логине, email, заметках
);
```

### Фильтрация по статусам
```dart
final filter = PasswordFilter.create(
  isFavorite: true,     // только избранные
  isArchived: false,    // исключить архивные
  hasNotes: true,       // только с заметками
  isFrequent: true,     // часто используемые (usedCount >= 100)
);
```

### Фильтрация по категориям
```dart
final filter = PasswordFilter.create(
  categoryIds: ['work-id', 'personal-id'],  // список категорий
  categoriesMatch: MatchMode.any,           // любая из категорий
);
```

### Фильтрация по тегам
```dart
final filter = PasswordFilter.create(
  tagIds: ['important', 'secure'],    // список тегов
  tagsMatch: MatchMode.all,           // все теги одновременно (AND)
  // tagsMatch: MatchMode.any,        // любой тег (OR)
);
```

### Фильтрация по датам
```dart
final filter = PasswordFilter.create(
  createdAfter: DateTime.now().subtract(Duration(days: 30)),    // созданные за месяц
  modifiedBefore: DateTime.now().subtract(Duration(days: 7)),   // не изменялись неделю
  lastAccessedAfter: DateTime.now().subtract(Duration(days: 1)), // использованные сегодня
);
```

### Сортировка
```dart
final filter = PasswordFilter.create(
  sortField: PasswordSortField.name,        // поле сортировки
  sortDirection: SortDirection.asc,         // направление
);
```

Доступные поля для сортировки:
- `name` - по названию
- `createdAt` - по дате создания  
- `modifiedAt` - по дате изменения
- `lastAccessed` - по дате последнего доступа
- `usedCount` - по количеству использований

### Пагинация
```dart
final filter = PasswordFilter.create(
  limit: 50,      // количество записей
  offset: 100,    // пропустить записей
);
```

## Использование в DAO

### Получение отфильтрованных паролей
```dart
final passwordsDao = PasswordsDao(database);
final passwords = await passwordsDao.getFilteredPasswords(filter);
```

### Подсчет отфильтрованных паролей
```dart
final count = await passwordsDao.countFilteredPasswords(filter);
```

### Stream для реактивного UI
```dart
Stream<List<Password>> passwordsStream = passwordsDao.watchFilteredPasswords(filter);
```

## Использование в сервисе

### Основные методы
```dart
final passwordService = PasswordService(database);

// Получение отфильтрованных паролей с деталями (теги, категория)
final result = await passwordService.getFilteredPasswords(filter);

// Подсчет паролей
final countResult = await passwordService.countFilteredPasswords(filter);

// Быстрый поиск
final searchResult = await passwordService.quickSearchPasswords('google');
```

### Stream методы
```dart
// Наблюдение за отфильтрованными паролями
passwordService.watchFilteredPasswords(filter).listen((passwords) {
  // Обновить UI
});
```

## Примеры использования

### 1. Простой поиск по тексту
```dart
final filter = PasswordFilter.create(query: 'bank');
final result = await passwordService.getFilteredPasswords(filter);
```

### 2. Избранные пароли за последний месяц
```dart
final filter = PasswordFilter.create(
  isFavorite: true,
  createdAfter: DateTime.now().subtract(Duration(days: 30)),
  sortField: PasswordSortField.createdAt,
  sortDirection: SortDirection.desc,
);
```

### 3. Пароли с определенными тегами и категорией
```dart
final filter = PasswordFilter.create(
  categoryIds: ['work-category-id'],
  tagIds: ['important', 'secure'],
  tagsMatch: MatchMode.all,  // должны быть оба тега
  isArchived: false,
);
```

### 4. Часто используемые пароли
```dart
final filter = PasswordFilter.create(
  isFrequent: true,
  sortField: PasswordSortField.usedCount,
  sortDirection: SortDirection.desc,
  limit: 20,
);
```

### 5. Пагинированный поиск
```dart
Future<void> loadPage(int page, int pageSize) async {
  final filter = PasswordFilter.create(
    isArchived: false,
    sortField: PasswordSortField.name,
    limit: pageSize,
    offset: page * pageSize,
  );
  
  final passwords = await passwordService.getFilteredPasswords(filter);
  final total = await passwordService.countFilteredPasswords(
    filter.copyWith(limit: null, offset: null)
  );
  
  // Обновить UI с данными страницы
}
```

### 6. Сложный фильтр
```dart
final complexFilter = PasswordFilter.create(
  query: 'social',                              // поиск по тексту
  categoryIds: ['social-media', 'personal'],    // категории
  tagIds: ['2fa', 'verified'],                  // теги
  tagsMatch: MatchMode.any,                     // любой из тегов
  isFavorite: null,                            // не важно
  isArchived: false,                           // не архивные
  hasNotes: true,                              // с заметками
  createdAfter: DateTime(2024, 1, 1),         // с начала года
  isFrequent: null,                            // не важно
  sortField: PasswordSortField.lastAccessed,   // по дате доступа
  sortDirection: SortDirection.desc,            // сначала новые
  limit: 100,                                  // до 100 записей
);
```

## Оптимизация производительности

### 1. Используйте limit для больших наборов данных
```dart
final filter = PasswordFilter.create(limit: 50); // ограничьте результаты
```

### 2. Избегайте подсчета если он не нужен
```dart
// Не вызывайте countFilteredPasswords без необходимости
final passwords = await passwordService.getFilteredPasswords(filter);
// Подсчет только при необходимости пагинации
```

### 3. Используйте Stream для реактивного UI
```dart
// Stream автоматически обновляет UI при изменениях
passwordService.watchFilteredPasswords(filter)
```

### 4. Кэширование фильтров
```dart
class PasswordListController {
  PasswordFilter? _lastFilter;
  List<PasswordWithDetails>? _cachedResults;
  
  Future<void> applyFilter(PasswordFilter filter) async {
    if (filter == _lastFilter) {
      return; // используем кэш
    }
    
    _lastFilter = filter;
    final result = await passwordService.getFilteredPasswords(filter);
    _cachedResults = result.data;
  }
}
```

## Интеграция с UI

### Пример контроллера списка паролей
```dart
class PasswordListController {
  final PasswordService _passwordService;
  PasswordFilter _currentFilter = const PasswordFilter();
  
  // Установка поискового запроса
  void setSearchQuery(String query) {
    _currentFilter = _currentFilter.copyWith(query: query);
    _refreshPasswords();
  }
  
  // Переключение избранных
  void toggleFavorites() {
    final newFavorite = _currentFilter.isFavorite == true ? null : true;
    _currentFilter = _currentFilter.copyWith(isFavorite: newFavorite);
    _refreshPasswords();
  }
  
  // Установка категории
  void filterByCategory(String? categoryId) {
    final categories = categoryId != null ? [categoryId] : <String>[];
    _currentFilter = _currentFilter.copyWith(categoryIds: categories);
    _refreshPasswords();
  }
  
  // Сброс фильтров
  void clearFilters() {
    _currentFilter = const PasswordFilter();
    _refreshPasswords();
  }
}
```

## Ошибки и отладка

### Проверка активности фильтра
```dart
if (filter.hasActiveConstraints) {
  print('Фильтр активен');
} else {
  print('Фильтр пустой - будут возвращены все пароли');
}
```

### Отладка SQL запросов
Фильтрация по тегам использует сложные SQL запросы. При проблемах проверьте:
1. Существуют ли указанные теги в БД
2. Правильно ли указаны ID тегов
3. Корректность логики MatchMode (any/all)

### Производительность
При медленной фильтрации:
1. Добавьте индексы в БД на часто фильтруемые поля
2. Используйте LIMIT для ограничения результатов
3. Избегайте сложных текстовых поисков по большим полям

## Заключение

Система фильтрации `PasswordFilter` предоставляет мощные и гибкие возможности для поиска и организации паролей. Используйте комбинации различных фильтров для создания точных запросов, а Stream API для создания реактивного пользовательского интерфейса.