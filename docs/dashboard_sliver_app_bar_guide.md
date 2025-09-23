# DashboardSliverAppBar Component Documentation

## Обзор

Компонент `DashboardSliverAppBar` предоставляет полнофункциональный SliverAppBar для дашборда с интегрированными функциями фильтрации, поиска и управления типами сущностей.

## Основные возможности

### 1. Основные элементы UI:
- **Drawer кнопка** - слева для открытия боковой панели
- **Выбор типа сущности** - компактный dropdown справа
- **Кнопка фильтров** - с индикатором активных фильтров
- **Поле поиска** - с автоматическим debounce
- **Вкладки фильтров** - FilterTabs компонент

### 2. Интеграция с провайдерами:
- `currentEntityTypeProvider` - текущий тип сущности
- `baseFilterProvider` - базовые фильтры и поисковый запрос
- `filterTabsControllerProvider` - управление вкладками
- `availableFilterTabsProvider` - доступные вкладки

## Использование

### Базовая интеграция:

```dart
import 'package:hoplixi/features/password_manager/dashboard/widgets/dashboard_app_bar.dart';

class MyDashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          DashboardSliverAppBar(
            onMenuPressed: () => Scaffold.of(context).openDrawer(),
            onFilterApplied: () => print('Фильтры применены'),
          ),
          // Остальной контент...
        ],
      ),
    );
  }
}
```

### Расширенная настройка:

```dart
DashboardSliverAppBar(
  // Callbacks
  onMenuPressed: () => _openDrawer(),
  onFilterApplied: () => _handleFiltersApplied(),
  
  // Размеры
  expandedHeight: 180.0,
  collapsedHeight: 60.0,
  
  // Поведение
  pinned: true,
  floating: false,
  snap: false,
  
  // UI настройки
  showEntityTypeSelector: true,
  additionalActions: [
    IconButton(
      icon: Icon(Icons.settings),
      onPressed: () => _openSettings(),
    ),
  ],
)
```

## API

### DashboardSliverAppBar

#### Параметры:
- `onMenuPressed: VoidCallback?` - Callback для кнопки drawer
- `onFilterApplied: VoidCallback?` - Callback при применении фильтров
- `expandedHeight: double` - Высота в расширенном состоянии (160.0)
- `collapsedHeight: double` - Высота в свернутом состоянии (60.0)
- `pinned: bool` - Закреплен ли AppBar (true)
- `floating: bool` - Плавает ли AppBar (false)
- `snap: bool` - Быстрое появление при скролле (false)
- `showEntityTypeSelector: bool` - Показывать селектор типа (true)
- `additionalActions: List<Widget>?` - Дополнительные actions

#### Автоматические функции:
- **Синхронизация поиска** - автоматическое обновление baseFilter.query с debounce 300ms
- **Индикатор фильтров** - красная точка на кнопке при активных фильтрах
- **Синхронизация вкладок** - автоматическая синхронизация при смене типа сущности
- **Адаптивные подсказки** - разные placeholder для поиска в зависимости от типа

### CompactDashboardSliverAppBar

Упрощенная версия для использования в других экранах:

```dart
CompactDashboardSliverAppBar(
  title: 'Мой экран',
  showFilterButton: true,
  onMenuPressed: () => _openDrawer(),
  onFilterPressed: () => _openFilters(),
  actions: [
    IconButton(
      icon: Icon(Icons.add),
      onPressed: () => _addItem(),
    ),
  ],
)
```

#### Параметры:
- `title: String` - Заголовок ('Hoplixi')
- `showFilterButton: bool` - Показывать кнопку фильтров (false)
- `onMenuPressed: VoidCallback?` - Callback для drawer
- `onFilterPressed: VoidCallback?` - Callback для фильтров
- `actions: List<Widget>?` - Дополнительные actions

## Архитектура

### Внутренняя структура:

1. **Верхняя часть** (collapsed height):
   - Leading: кнопка drawer
   - Title: заголовок дашборда
   - Actions: селектор типа, кнопка фильтров, дополнительные actions

2. **Нижняя часть** (expanded content):
   - Поле поиска с адаптивными подсказками
   - Компонент FilterTabs

3. **Интерактивность**:
   - Автоматическое скрытие/показ при скролле
   - Плавные анимации переходов
   - Синхронизация состояния с провайдерами

### Интеграция с системой фильтрации:

```dart
// Автоматическая синхронизация поиска
_onSearchChanged(String query) {
  Future.delayed(Duration(milliseconds: 300), () {
    if (_searchController.text == query) {
      ref.read(baseFilterProvider.notifier).updateQuery(query);
    }
  });
}

// Автоматическая синхронизация типов сущности
ref.listen(currentEntityTypeProvider, (previous, next) {
  if (previous != next) {
    ref.read(filterTabsControllerProvider.notifier).syncWithEntityType();
  }
});
```

## Примеры использования

### Полный пример с drawer:
См. `dashboard_app_bar_example_screen.dart` - `DashboardSliverAppBarExampleScreen`

### Компактный пример:
См. `dashboard_app_bar_example_screen.dart` - `CompactDashboardSliverAppBarExampleScreen`

## Customization

### Изменение высот:
```dart
DashboardSliverAppBar(
  expandedHeight: 200.0, // Больше места для контента
  collapsedHeight: 80.0, // Больше места для заголовка
)
```

### Отключение элементов:
```dart
DashboardSliverAppBar(
  showEntityTypeSelector: false, // Скрыть селектор типа
  additionalActions: [], // Убрать дополнительные кнопки
)
```

### Кастомные actions:
```dart
DashboardSliverAppBar(
  additionalActions: [
    IconButton(
      icon: Icon(Icons.notifications),
      onPressed: () => _showNotifications(),
    ),
    PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(child: Text('Настройки')),
        PopupMenuItem(child: Text('Помощь')),
      ],
    ),
  ],
)
```

## Troubleshooting

### Общие проблемы:

1. **Поиск не работает**: Убедитесь, что baseFilterProvider правильно подключен
2. **Вкладки не отображаются**: Проверьте, что availableFilterTabsProvider возвращает вкладки
3. **Некорректная высота**: Убедитесь, что expandedHeight > collapsedHeight

### Отладка:
Все изменения состояния автоматически логируются через AppLogger в DEBUG режиме.

## Зависимости

Компонент требует:
- `EntityTypeDropdown` - для селектора типа сущности
- `FilterModal` - для модального окна фильтров
- `FilterTabs` - для вкладок фильтров
- `PrimaryTextField` - для поля поиска
- Все соответствующие провайдеры из `dashboard/providers/`