# Universal Filter System

Универсальная система фильтрации для всех типов записей в Hoplixi (пароли, заметки, OTP, вложения).

## Архитектура

### Основные компоненты

1. **EntityTypeProvider** - Управление типом текущей сущности
2. **UniversalFilterController** - Управление фильтрацией и состоянием
3. **UniversalFilterSection** - UI компонент секции фильтрации (SliverAppBar)
4. **UniversalFilterModal** - Модальное окно настройки фильтров
5. **UniversalRecordsList** - Список записей с пагинацией

### Поддерживаемые типы сущностей

- `password` - Пароли
- `note` - Заметки  
- `otp` - OTP/2FA коды
- `attachment` - Вложения

## Использование

### Базовое использование

```dart
import 'package:hoplixi/features/password_manager/universal_filter/universal_filter_barrel.dart';

class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Секция фильтрации
          UniversalFilterSection(
            onMenuPressed: () => Scaffold.of(context).openDrawer(),
            showEntityTypeSelector: true,
          ),
          
          // Список записей
          SliverFillRemaining(
            child: UniversalRecordsList(
              onRecordTap: (record) {
                // Обработка нажатия на запись
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### Управление типом сущности

```dart
// Получить текущий тип
final entityType = ref.watch(currentEntityTypeProvider);

// Изменить тип
ref.read(entityTypeControllerProvider.notifier)
   .changeEntityType(UniversalEntityType.note);

// Получить доступные типы
final availableTypes = ref.watch(availableEntityTypesProvider);
```

### Управление фильтрами

```dart
final controller = ref.read(universalFilterControllerProvider.notifier);

// Обновить поисковый запрос
controller.updateSearchQuery('search text');

// Переключить вкладку
controller.switchTab(UniversalFilterTab.favorites);

// Применить кастомный фильтр
controller.applyFilter(customFilter);

// Сбросить фильтры
controller.resetFilters();
```

### Кастомизация списка записей

```dart
UniversalRecordsList(
  itemBuilder: (context, record, index) {
    // Кастомный виджет элемента списка
    return CustomListItem(record: record);
  },
  onRecordTap: (record) {
    // Обработка нажатия
  },
  onRecordLongPress: (record) {
    // Обработка долгого нажатия
  },
  pageSize: 50, // Размер страницы для пагинации
  emptyWidget: CustomEmptyWidget(),
)
```

## Особенности

### Автоматическая синхронизация

Система автоматически синхронизирует:
- Изменения типа сущности с доступными вкладками фильтров
- Фильтры при переключении типов сущностей
- Перезагрузку данных при изменении фильтров

### Адаптивные вкладки

Вкладки фильтрации адаптируются к типу сущности:
- **Пароли**: Все, Избранные, Часто используемые, Архив
- **Заметки**: Все, Избранные, Архив
- **OTP**: Все, Избранные, Архив
- **Вложения**: Все, Архив

### Типобезопасность

Все фильтры типобезопасны и используют соответствующие модели:
- PasswordFilter для паролей
- NotesFilter для заметок
- OtpFilter для OTP
- AttachmentsFilter для вложений

### Пагинация

Автоматическая подгрузка данных при прокрутке списка с настраиваемым размером страницы.

## Провайдеры

### Основные провайдеры

- `entityTypeControllerProvider` - Контроллер типа сущности
- `universalFilterControllerProvider` - Контроллер фильтрации
- `currentEntityTypeProvider` - Текущий тип сущности
- `currentUniversalFilterProvider` - Текущий универсальный фильтр
- `currentActiveFilterProvider` - Текущий активный специфичный фильтр

### Computed провайдеры

- `hasActiveUniversalFiltersProvider` - Есть ли активные фильтры
- `availableFilterTabsProvider` - Доступные вкладки для текущего типа
- `currentFilterTabProvider` - Текущая активная вкладка

## Пример интеграции

Полный пример использования см. в `example/universal_filter_example_screen.dart`.

## Расширение

Для добавления нового типа сущности:

1. Добавить enum в `UniversalEntityType`
2. Создать соответствующий фильтр модели
3. Обновить `UniversalFilter` для поддержки нового типа
4. Добавить логику в контроллер и UI компоненты

## Зависимости

- flutter_riverpod (v3 Notifier API)
- freezed (для моделей данных)
- Основные модели фильтров Hoplixi