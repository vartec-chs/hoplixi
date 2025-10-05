# Виджет для фильтрации тегов - Краткое описание

## Что создано

Создан полный набор виджетов для фильтрации тегов в Flutter приложении:

### 1. Основные файлы:

- **`tag_filter_widget.dart`** - Главный виджет фильтрации в виде текстового поля
- **`widgets/tag_filter_modal.dart`** - Модальное окно с выбором тегов
- **`widgets/tag_filter_button.dart`** - Компактный виджет-кнопка
- **`tag_filter.dart`** - Файл экспорта всех компонентов
- **`example/tag_filter_example_screen.dart`** - Пример использования
- **`README.md`** - Подробная документация

### 2. Ключевые возможности:

✅ **Адаптивный интерфейс**: модальное окно для ПК, bottom sheet для мобильных  
✅ **Пагинация**: автоматическая подгрузка тегов при скролле  
✅ **Поиск**: фильтрация тегов по названию в реальном времени  
✅ **Типы тегов**: поддержка всех типов (notes, password, totp, mixed)  
✅ **Ограничения**: лимит на максимальное количество выбранных тегов  
✅ **Состояния**: режим только для чтения, показ счетчика  
✅ **Цвета**: поддержка цветов тегов с автоматическим контрастом  
✅ **Callback функции**: onSelect, onRemove, onClearAll, onApplyFilter  

### 3. Два варианта использования:

#### TagFilterWidget - Полноразмерное поле
```dart
TagFilterWidget(
  tagType: TagType.password,
  selectedTags: selectedTags,
  onTagSelect: (tag) => { /* добавить тег */ },
  onTagRemove: (tag) => { /* удалить тег */ },
  onClearAll: () => { /* очистить все */ },
)
```

#### TagFilterButton - Компактная кнопка  
```dart
TagFilterButton(
  tagType: TagType.notes,
  selectedTags: selectedTags,
  showButtonText: false,  // только иконка
  buttonSize: Size(40, 40),
  onTagSelect: (tag) => { /* ... */ },
  onTagRemove: (tag) => { /* ... */ },
  onClearAll: () => { /* ... */ },
)
```

## Интеграция

Для использования в других частях приложения:

```dart
import 'package:hoplixi/features/password_manager/tags_manager/tag_filter/tag_filter.dart';
```

Виджеты автоматически интегрируются с:
- Существующим TagsService
- Системой цветов AppColors  
- Провайдерами Riverpod
- Логированием через app_logger