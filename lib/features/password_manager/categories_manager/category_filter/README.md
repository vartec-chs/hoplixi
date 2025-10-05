# Category Filter Widget

Виджет для фильтрации категорий в приложении Hoplixi с поддержкой пагинации, поиска и адаптивного интерфейса.

## Возможности

- ✅ Фильтрация категорий по типу (notes, password, totp, mixed)
- ✅ Поддержка пагинации с настраиваемым размером страницы
- ✅ Поиск по названию категории
- ✅ Адаптивный интерфейс (модальное окно на ПК, bottom sheet на мобильных)
- ✅ Ограничение количества выбранных категорий
- ✅ Разные варианты отображения (основной виджет, кнопка)
- ✅ Callback функции для событий выбора, удаления и очистки
- ✅ Настраиваемая сортировка и внешний вид

## Компоненты

### CategoryFilterWidget
Основной виджет с текстовым полем, который при нажатии открывает модальное окно или bottom sheet.

### CategoryFilterButton  
Кнопка для открытия фильтра категорий. Показывает количество выбранных категорий.

### CategoryFilterModal
Модальное окно с полным интерфейсом выбора категорий, включая поиск и пагинацию.

## Использование

### Базовый пример

```dart
import 'package:hoplixi/features/category_filter/category_filter.dart';

CategoryFilterWidget(
  categoryType: CategoryType.password, // Обязательный параметр
  selectedCategories: _selectedCategories,
  onSelect: (category) {
    // Добавить категорию в выбор
    setState(() {
      _selectedCategories.add(category);
    });
  },
  onRemove: (category) {
    // Удалить категорию из выбора
    setState(() {
      _selectedCategories.remove(category);
    });
  },
  onClearAll: () {
    // Очистить все выбранные категории
    setState(() {
      _selectedCategories.clear();
    });
  },
)
```

### Пример с кнопкой

```dart
CategoryFilterButton(
  categoryType: CategoryType.notes,
  selectedCategories: _selectedCategories,
  onSelect: (category) => _addCategory(category),
  onRemove: (category) => _removeCategory(category),  
  onClearAll: () => _clearCategories(),
  buttonText: 'Выбрать категории',
  maxSelectedCategories: 5,
)
```

### Расширенный пример с настройками

```dart
CategoryFilterWidget(
  categoryType: CategoryType.mixed,
  selectedCategories: _selectedCategories,
  onSelect: _handleCategorySelect,
  onRemove: _handleCategoryRemove,
  onClearAll: _handleClearAll,
  
  // Дополнительные callback'и
  onApplyFilter: (categories) {
    // Применить фильтр
    _applyFilter(categories);
  },
  
  // Настройки интерфейса
  searchPlaceholder: 'Выберите категории для фильтрации',
  modalTitle: 'Фильтр категорий',
  showSelectedCount: true,
  height: 56,
  
  // Ограничения
  maxSelectedCategories: 10,
  readOnly: false,
  
  // Настройки пагинации
  pageSize: 20,
  sortBy: CategorySortBy.name,
  ascending: true,
)
```

## Параметры

### Обязательные параметры

| Параметр | Тип | Описание |
|----------|-----|----------|
| `categoryType` | `CategoryType` | Тип категорий для фильтрации (notes, password, totp, mixed) |
| `selectedCategories` | `List<Category>` | Список выбранных категорий |
| `onSelect` | `Function(Category)` | Callback при выборе категории |
| `onRemove` | `Function(Category)` | Callback при удалении категории |
| `onClearAll` | `Function()` | Callback при очистке всех категорий |

### Опциональные параметры

| Параметр | Тип | Значение по умолчанию | Описание |
|----------|-----|---------------------|----------|
| `onApplyFilter` | `Function(List<Category>)?` | `null` | Callback при применении фильтра |
| `searchPlaceholder` | `String?` | `null` | Placeholder для поля поиска |
| `modalTitle` | `String?` | `null` | Заголовок модального окна |
| `maxSelectedCategories` | `int?` | `null` | Максимальное количество выбранных категорий |
| `showSelectedCount` | `bool` | `true` | Показывать ли счетчик выбранных |
| `readOnly` | `bool` | `false` | Режим только для чтения |
| `height` | `double?` | `56` | Высота виджета |
| `width` | `double?` | `null` | Ширина виджета |
| `pageSize` | `int` | `20` | Размер страницы для пагинации |
| `sortBy` | `CategorySortBy` | `CategorySortBy.name` | Поле для сортировки |
| `ascending` | `bool` | `true` | Сортировать по возрастанию |

## Типы категорий

```dart
enum CategoryType {
  notes,    // Категории для заметок
  password, // Категории для паролей  
  totp,     // Категории для TOTP
  mixed     // Смешанные категории
}
```

## Типы сортировки

```dart
enum CategorySortBy {
  name,       // По названию
  type,       // По типу
  createdAt,  // По дате создания
  modifiedAt  // По дате изменения
}
```

## Callback функции

### onSelect
Вызывается при выборе категории. Получает объект `Category`.

```dart
onSelect: (Category category) {
  // Логика добавления категории в выбор
},
```

### onRemove
Вызывается при удалении категории из выбора. Получает объект `Category`.

```dart
onRemove: (Category category) {
  // Логика удаления категории из выбора
},
```

### onClearAll
Вызывается при очистке всех выбранных категорий.

```dart
onClearAll: () {
  // Логика очистки всего выбора
},
```

### onApplyFilter (опционально)
Вызывается при применении фильтра с финальным списком выбранных категорий.

```dart
onApplyFilter: (List<Category> categories) {
  // Логика применения фильтра
  _filterData(categories);
},
```

## Адаптивность

Виджет автоматически определяет размер экрана:
- **Мобильные устройства** (ширина < 600px): Показывается bottom sheet
- **Планшеты и ПК** (ширина ≥ 600px): Показывается модальное окно

## Пагинация

- Автоматическая подгрузка при прокрутке до конца списка
- Настраиваемый размер страницы через параметр `pageSize`
- Индикатор загрузки дополнительных данных
- Поддержка поиска с пагинацией

## Примеры использования

См. файл `example/category_filter_example_screen.dart` для подробных примеров использования всех возможностей виджета.

## Зависимости

- `flutter_riverpod` - для управления состоянием
- `hoplixi/common/text_field.dart` - кастомное текстовое поле
- `hoplixi/common/button.dart` - кастомные кнопки
- `hoplixi/core/theme/colors.dart` - цветовая схема
- `hoplixi/hoplixi_store/*` - сервисы и модели данных