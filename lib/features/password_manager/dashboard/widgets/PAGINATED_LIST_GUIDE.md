# Пагинированный список паролей - Руководство по использованию

## Обзор

Реализован полнофункциональный пагинированный список паролей с поддержкой:
- Автоматической пагинации при скролле
- Фильтрации по вкладкам (все, избранные, часто используемые, архив)
- Реактивного обновления при изменении фильтров
- Pull-to-refresh функциональности
- Переключения между различными типами сущностей

## Архитектура

### Провайдеры

1. **`PaginatedPasswordsProvider`** (`paginated_passwords_provider.dart`)
   - Основной провайдер для управления пагинированным списком паролей
   - Автоматически реагирует на изменения фильтров
   - Управляет состоянием загрузки и ошибками

2. **Состояние `PaginatedPasswordsState`**
   ```dart
   class PaginatedPasswordsState {
     final List<CardPasswordDto> passwords;    // Загруженные пароли
     final bool isLoading;                     // Первичная загрузка
     final bool isLoadingMore;                 // Загрузка дополнительных данных
     final bool hasMore;                       // Есть ли еще данные
     final String? error;                      // Ошибка загрузки
     final int currentPage;                    // Текущая страница
     final int totalCount;                     // Общее количество
   }
   ```

3. **Методы провайдера**
   - `loadMore()` - загрузка следующей страницы
   - `refresh()` - обновление данных (pull-to-refresh)
   - Геттеры: `currentCount`, `hasMore`, `isLoadingMore`, `passwords`, `totalCount`

### Виджеты

1. **`EntityListView`** (`entity_list_view.dart`)
   - Основной виджет для отображения списков различных сущностей
   - Поддерживает передачу внешнего ScrollController
   - Автоматически определяет тип сущности и отображает соответствующий контент

2. **Внутренние Sliver-виджеты**
   - `_PasswordsSliverList` - список паролей как Sliver
   - `_LoadingSliverView` - индикатор загрузки как Sliver
   - `_ErrorSliverView` - отображение ошибок как Sliver
   - `_EmptyView` - пустое состояние с поддержкой "в разработке"

## Использование

### Базовое использование

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Ваш SliverAppBar или другие Sliver-виджеты
          
          // Список сущностей с пагинацией
          const EntityListView(),
        ],
      ),
    );
  }
}
```

### Использование с внешним ScrollController

```dart
class MyScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Ваши Sliver-виджеты
          
          // Список с переданным контроллером
          EntityListView(scrollController: _scrollController),
        ],
      ),
    );
  }
}
```

### Программное управление

```dart
// Загрузка дополнительных данных
ref.read(paginatedPasswordsProvider.notifier).loadMore();

// Обновление данных
await ref.read(paginatedPasswordsProvider.notifier).refresh();

// Получение текущего состояния
final passwordsAsync = ref.watch(paginatedPasswordsProvider);
passwordsAsync.when(
  loading: () => LoadingWidget(),
  error: (error, _) => ErrorWidget(error),
  data: (state) => YourContentWidget(state),
);
```

### Интеграция с фильтрами

Провайдер автоматически реагирует на изменения:
- `passwordFilterProvider` - фильтр паролей
- `filterTabsControllerProvider` - активная вкладка
- При изменении любого из этих провайдеров список автоматически перезагружается

## Конфигурация

### Размер страницы
```dart
const int kPasswordsPageSize = 20; // В paginated_passwords_provider.dart
```

### Порог для загрузки следующей страницы
```dart
// В EntityListView._onScroll()
if (_scrollController.position.pixels >=
    _scrollController.position.maxScrollExtent - 200) {
  // Загружаем больше данных когда до конца остается 200 пикселей
}
```

## Обработка ошибок

1. **Ошибки загрузки данных** - отображаются с кнопкой "Повторить"
2. **Ошибки пагинации** - показываются в нижней части списка
3. **Пустое состояние** - специальный экран для пустых списков
4. **"В разработке"** - для сущностей, которые еще не реализованы

## Производительность

1. **Автоматическая очистка** - провайдер с `autoDispose` автоматически очищается
2. **Эффективная пагинация** - загружается только необходимое количество элементов
3. **Реактивность** - обновления только при реальных изменениях фильтров
4. **Debouncing** - предотвращение множественных загрузок при быстром скролле

## Поддерживаемые сущности

1. **Пароли** ✅ - полная реализация с пагинацией
2. **Заметки** 🚧 - заглушка "в разработке"
3. **OTP** 🚧 - заглушка "в разработке"

## Будущие улучшения

1. Реализация списков для заметок и OTP
2. Добавление виртуализации для очень больших списков
3. Поддержка бесконечного скролла с кэшированием
4. Оптимизация запросов к базе данных
5. Добавление анимаций при загрузке/обновлении

## Отладка

Для отладки включены подробные логи:
```dart
logDebug('PaginatedPasswordsNotifier: Загружено ${passwords.length} паролей');
logError('Ошибка загрузки данных', error: e, stackTrace: s);
```

Логи помогают отслеживать:
- Инициализацию провайдера
- Изменения фильтров
- Процесс загрузки данных
- Ошибки и их причины