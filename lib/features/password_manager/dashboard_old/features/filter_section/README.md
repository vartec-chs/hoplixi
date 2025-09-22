# Filter Section

Компонент фильтрации для менеджера паролей Hoplixi. Предоставляет комплексную систему фильтрации паролей с использованием Riverpod v3 для управления состоянием. **Реализован как SliverAppBar** для лучшей интеграции с прокручиваемым контентом.

## Основные компоненты

### FilterSectionController

NotifierProvider для управления состоянием фильтрации паролей. Использует Riverpod v3 Notifier API.

**Основные методы:**

- `updateSearchQuery(String query)` - обновляет поисковый запрос с мгновенным применением
- `switchTab(FilterTab tab)` - переключает активную вкладку (Все/Избранные/Часто используемые)
- `applyFilter(PasswordFilter newFilter)` - применяет новый фильтр из модального окна
- `updateCategories(List<String> categoryIds)` - обновляет выбранные категории
- `updateTags(List<String> tagIds)` - обновляет выбранные теги
- `resetFilters()` - сбрасывает все фильтры

### FilterSection Widget (SliverAppBar)

Основной виджет секции фильтрации, реализован как **SliverAppBar**, содержит:

- **Поле поиска** - в FlexibleSpaceBar с использованием `PrimaryTextField`
- **Кнопка меню** - в leading (через callback)
- **Кнопка фильтров** - в actions с индикатором активных фильтров
- **TabBar** - в bottom с тремя вкладками: "Все", "Избранные", "Часто используемые"

**Параметры SliverAppBar:**

- `expandedHeight` - высота в развернутом состоянии (по умолчанию 120px)
- `collapsedHeight` - высота в свернутом состоянии (по умолчанию 60px)  
- `pinned` - закреплен ли AppBar при прокрутке (по умолчанию true)
- `floating` - плавает ли AppBar (по умолчанию false)
- `snap` - быстро ли появляется при прокрутке вверх (по умолчанию false)

### FilterModal

Полноэкранное модальное окно для настройки расширенных фильтров:

- **Поиск по тексту** - по названию, логину, заметкам
- **Фильтрация по категориям** - интеграция с CategoryFilterWidget
- **Фильтрация по тегам** - интеграция с TagFilterWidget
- **Дополнительные фильтры** - заметки, архив
- **Сортировка** - по различным полям с выбором направления

## Архитектура состояния

### FilterSectionState

Неизменяемое состояние содержит:

```dart
class FilterSectionState {
  final PasswordFilter filter;           // Основной фильтр
  final FilterTab activeTab;             // Активная вкладка
  final String searchQuery;              // Поисковый запрос
  final bool hasActiveFilters;           // Индикатор активных фильтров
}
```

### FilterTab enum

Типы быстрой фильтрации:

```dart
enum FilterTab {
  all('Все'),
  favorites('Избранные'), 
  frequent('Часто используемые');
}
```

## Особенности работы

### Мгновенное применение

- Поиск по тексту применяется мгновенно
- Переключение вкладок TabBar применяется мгновенно

### Локальное состояние модального окна

- Изменения в модальном окне не влияют на глобальное состояние
- Применение происходит только при нажатии "Применить"
- При закрытии модального окна изменения отменяются

### Интеграция с существующими фильтрами

- Использует `CategoryFilterWidget` для выбора категорий
- Использует `TagFilterWidget` для выбора тегов
- Получает соответствующие ID для обновления `PasswordFilter`

## Providers

```dart
// Основной controller
final filterSectionControllerProvider = NotifierProvider<FilterSectionController, FilterSectionState>

// Computed providers
final currentPasswordFilterProvider = Provider<PasswordFilter>
final hasActiveFiltersProvider = Provider<bool>
```

## Пример использования

```dart
class ExampleScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: const Drawer(
        child: Center(child: Text('Drawer Content')),
      ),
      body: CustomScrollView(
        slivers: [
          // Секция фильтрации как SliverAppBar
          FilterSection(
            onMenuPressed: () {
              Scaffold.of(context).openDrawer();
            },
            pinned: true,
            floating: false,
            snap: false,
            expandedHeight: 120.0,
            collapsedHeight: 60.0,
          ),
          
          // Ваш контент в SliverList или других Sliver виджетах
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ListTile(
                title: Text('Item $index'),
              ),
              childCount: 100,
            ),
          ),
        ],
      ),
    );
  }
}
```

## Тестирование

См. `example/filter_section_example_screen.dart` для демонстрации всех возможностей компонента.

## Зависимости

- `flutter_riverpod` - для управления состоянием
- `hoplixi/common/text_field.dart` - для текстовых полей
- `hoplixi/features/filters/` - для интеграции с существующими фильтрами
- `hoplixi/hoplixi_store/models/password_filter.dart` - модель фильтра