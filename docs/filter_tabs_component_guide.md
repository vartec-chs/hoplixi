# FilterTabs Component Documentation

## Обзор

Компонент `FilterTabs` предоставляет интерфейс вкладок для управления фильтрами в дашборде. Компонент полностью интегрирован с системой состояния Riverpod и автоматически адаптируется к различным типам сущностей.

## Архитектура

### Основные файлы:
- `widgets/filter_tabs.dart` - UI компонент вкладок
- `providers/filter_tabs_provider.dart` - Управление состоянием вкладок
- `models/filter_tab.dart` - Модель и логика вкладок
- `widgets/dashboard_filter_tabs_integration.dart` - Примеры интеграции

### Провайдеры:
- `filterTabsControllerProvider` - Контроллер состояния текущей вкладки
- `availableFilterTabsProvider` - Доступные вкладки для текущего типа сущности

## Использование

### Базовая интеграция:

```dart
import 'package:hoplixi/features/password_manager/dashboard/widgets/filter_tabs.dart';

class MyDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const FilterTabs(), // Просто добавьте компонент
        // Остальной контент
      ],
    );
  }
}
```

### Расширенная интеграция с обработкой изменений:

```dart
class AdvancedDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Слушаем изменения вкладки
    ref.listen(filterTabsControllerProvider, (previous, next) {
      if (previous != next) {
        // Обработка изменения вкладки
        print('Изменена вкладка: ${next.label}');
      }
    });

    return Column(
      children: [
        const FilterTabs(),
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              final currentTab = ref.watch(filterTabsControllerProvider);
              return _buildContentForTab(currentTab);
            },
          ),
        ),
      ],
    );
  }
}
```

## API

### FilterTabsController

#### Методы:
- `changeTab(FilterTab tab)` - Изменяет активную вкладку
- `syncWithEntityType()` - Синхронизирует вкладку с типом сущности
- `getTabForEntityType()` - Получает подходящую вкладку для текущего типа
- `isTabAvailable(FilterTab tab)` - Проверяет доступность вкладки

#### Автоматическое применение фильтров:
Контроллер автоматически применяет соответствующие фильтры через `BaseFilterProvider`:

- **All**: Сбрасывает фильтры избранного и архивного
- **Favorites**: Показывает только избранные, исключает архивные
- **Frequent**: Исключает архивные, логика частоты в специфичных провайдерах
- **Archived**: Показывает только архивные

### FilterTab enum

#### Доступные вкладки:
- `FilterTab.all` - Все элементы
- `FilterTab.favorites` - Избранные
- `FilterTab.frequent` - Часто используемые
- `FilterTab.archived` - Архивные

#### Методы:
- `getAvailableTabsForEntity(EntityType type)` - Возвращает доступные вкладки для типа сущности

## Дизайн

### Параметры TabBar:
- **Высота**: 48px
- **Индикатор**: Цвет primary, высота 3px, скругленные углы
- **Выравнивание**: По левому краю
- **Цвета**: Активная вкладка - primary, неактивная - onSurface с прозрачностью
- **Анимация**: Стандартная анимация Material Design

### Адаптивность:
- Автоматически скрывает недоступные вкладки
- Адаптируется к изменению типа сущности
- Поддерживает светлую и темную темы

## Интеграция с фильтрами

### Автоматическая синхронизация:
```dart
// При изменении типа сущности вкладки автоматически синхронизируются
ref.listen(currentEntityTypeProvider, (previous, next) {
  ref.read(filterTabsControllerProvider.notifier).syncWithEntityType();
});
```

### Получение текущей вкладки:
```dart
final currentTab = ref.watch(filterTabsControllerProvider);
```

### Получение доступных вкладок:
```dart
final availableTabs = ref.watch(availableFilterTabsProvider);
```

## Логирование

Компонент автоматически логирует:
- Инициализацию с начальной вкладкой
- Изменения вкладок
- Применение фильтров
- Синхронизацию с типами сущностей

## Примеры интеграции

Смотрите файл `dashboard_filter_tabs_integration.dart` для:
- `DashboardFilterTabsIntegration` - Полная интеграция с дашбордом
- `SimpleFilterTabsExample` - Простая интеграция
- `AdvancedFilterTabsExample` - Расширенная интеграция с дополнительными элементами

## Troubleshooting

### Общие проблемы:

1. **Вкладка не меняется**: Убедитесь, что вкладка доступна для текущего типа сущности
2. **Фильтры не применяются**: Проверьте интеграцию с `BaseFilterProvider`
3. **Некорректное отображение**: Убедитесь, что тема правильно настроена

### Отладка:
Включите логирование для отслеживания изменений состояния:
```dart
import 'package:hoplixi/core/logger/app_logger.dart';
// Логи автоматически записываются при DEBUG режиме
```