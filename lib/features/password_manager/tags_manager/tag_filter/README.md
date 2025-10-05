# Tag Filter Widget

Комплект виджетов для фильтрации тегов с поддержкой модального окна на ПК и bottom sheet для мобильных устройств.

## Виджеты

### TagFilterWidget

Основной виджет фильтрации в виде текстового поля с кнопкой раскрытия.

### TagFilterButton

Компактный виджет фильтрации в виде кнопки с индикатором количества выбранных тегов.

## Функциональность

- Поддержка различных типов тегов (notes, password, totp, mixed)
- Адаптивный интерфейс (модальное окно для ПК, bottom sheet для мобильных)
- Пагинация для большого количества тегов
- Поиск по названию тегов
- Ограничение максимального количества выбранных тегов
- Показ счетчика выбранных тегов
- Режим только для чтения

## Использование

```dart
import 'package:hoplixi/features/password_manager/tags_manager/tag_filter/tag_filter.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

class ExampleScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends ConsumerState<ExampleScreen> {
  List<store.Tag> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Пример использования Tag Filter')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Базовое использование
            TagFilterWidget(
              tagType: TagType.password,
              selectedTags: _selectedTags,
              onTagSelect: (tag) {
                setState(() {
                  _selectedTags.add(tag);
                });
              },
              onTagRemove: (tag) {
                setState(() {
                  _selectedTags.removeWhere((t) => t.id == tag.id);
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedTags.clear();
                });
              },
            ),
            
            SizedBox(height: 20),
            
            // С дополнительными параметрами
            TagFilterWidget(
              tagType: TagType.notes,
              selectedTags: _selectedTags,
              maxSelectedTags: 5,
              modalTitle: 'Выберите теги для заметок',
              searchPlaceholder: 'Поиск тегов заметок...',
              showSelectedCount: true,
              onTagSelect: (tag) {
                setState(() {
                  _selectedTags.add(tag);
                });
              },
              onTagRemove: (tag) {
                setState(() {
                  _selectedTags.removeWhere((t) => t.id == tag.id);
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedTags.clear();
                });
              },
              onApplyFilter: (tags) {
                // Обработка применения фильтра
                print('Применен фильтр с ${tags.length} тегами');
              },
            ),
            
            SizedBox(height: 20),
            
            // Компактный виджет-кнопка
            TagFilterButton(
              tagType: TagType.totp,
              selectedTags: _selectedTags,
              modalTitle: 'Выберите теги TOTP',
              onTagSelect: (tag) {
                setState(() {
                  _selectedTags.add(tag);
                });
              },
              onTagRemove: (tag) {
                setState(() {
                  _selectedTags.removeWhere((t) => t.id == tag.id);
                });
              },
              onClearAll: () {
                setState(() {
                  _selectedTags.clear();
                });
              },
            ),
            
            SizedBox(height: 10),
            
            // Только иконка, без текста
            TagFilterButton(
              tagType: TagType.mixed,
              selectedTags: _selectedTags,
              showButtonText: false,
              buttonSize: Size(40, 40),
              onTagSelect: (tag) { /* ... */ },
              onTagRemove: (tag) { /* ... */ },
              onClearAll: () { /* ... */ },
            ),
          ],
        ),
      ),
    );
  }
}
```

## Параметры TagFilterWidget

### Обязательные параметры

- `tagType` (TagType): Тип тегов для фильтрации (notes, password, totp, mixed)
- `selectedTags` (List<store.Tag>): Текущий список выбранных тегов
- `onTagSelect` (Function(store.Tag)): Callback при выборе тега
- `onTagRemove` (Function(store.Tag)): Callback при удалении тега из выбора
- `onClearAll` (Function()): Callback при очистке всех выбранных тегов

### Опциональные параметры

- `onApplyFilter` (Function(List<store.Tag>)?): Callback при применении фильтра
- `searchPlaceholder` (String?): Placeholder для поля поиска
- `modalTitle` (String?): Заголовок модального окна
- `maxSelectedTags` (int?): Максимальное количество выбранных тегов
- `showSelectedCount` (bool): Показывать ли счетчик выбранных тегов (по умолчанию: true)
- `readOnly` (bool): Режим только для чтения (по умолчанию: false)
- `height` (double?): Кастомная высота виджета
- `width` (double?): Кастомная ширина виджета

## Параметры TagFilterButton

### Обязательные параметры TagFilterButton

- `tagType` (TagType): Тип тегов для фильтрации (notes, password, totp, mixed)
- `selectedTags` (List<store.Tag>): Текущий список выбранных тегов
- `onTagSelect` (Function(store.Tag)): Callback при выборе тега
- `onTagRemove` (Function(store.Tag)): Callback при удалении тега из выбора
- `onClearAll` (Function()): Callback при очистке всех выбранных тегов

### Опциональные параметры TagFilterButton

- `onApplyFilter` (Function(List<store.Tag>)?): Callback при применении фильтра
- `modalTitle` (String?): Заголовок модального окна
- `maxSelectedTags` (int?): Максимальное количество выбранных тегов
- `readOnly` (bool): Режим только для чтения (по умолчанию: false)
- `showButtonText` (bool): Показывать ли текст кнопки (по умолчанию: true)
- `buttonText` (String?): Кастомный текст кнопки
- `buttonSize` (Size?): Размер кнопки

## Особенности

1. **Адаптивность**: Автоматически определяет размер экрана и использует соответствующий интерфейс
2. **Пагинация**: Автоматически подгружает теги при скролле
3. **Поиск**: Поддерживает поиск тегов по названию в реальном времени
4. **Валидация**: Проверяет ограничения на максимальное количество тегов
5. **Цветовая схема**: Поддерживает цвета тегов и автоматически определяет контрастный цвет текста

## Интеграция с темами

Виджет автоматически адаптируется к текущей теме приложения и использует цветовую схему из `AppColors`.