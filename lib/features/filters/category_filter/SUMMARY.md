# Category Filter - Краткое описание

Виджет фильтрации категорий для приложения Hoplixi с поддержкой пагинации и адаптивного интерфейса.

## Основные компоненты

1. **CategoryFilterWidget** - основной виджет с текстовым полем
2. **CategoryFilterButton** - кнопка для открытия фильтра
3. **CategoryFilterModal** - модальное окно с полным интерфейсом

## Ключевые особенности

- Обязательный параметр `CategoryType` (notes, password, totp, mixed)
- Пагинация с настраиваемым размером страницы
- Callback функции: `onSelect`, `onRemove`, `onClearAll`
- Адаптивный интерфейс (modal на ПК, bottom sheet на мобильных)
- Поиск и сортировка категорий
- Ограничение количества выбираемых категорий

## Быстрый старт

```dart
CategoryFilterWidget(
  categoryType: CategoryType.password,
  selectedCategories: _selected,
  onSelect: (cat) => _add(cat),
  onRemove: (cat) => _remove(cat),
  onClearAll: () => _clear(),
)
```

## Структура папки

```
category_filter/
├── category_filter.dart           # Экспорты
├── category_filter_widget.dart    # Основной виджет
├── widgets/
│   ├── category_filter_modal.dart # Модальное окно
│   └── category_filter_button.dart # Кнопка
├── example/
│   └── category_filter_example_screen.dart # Примеры
├── README.md                      # Полная документация
└── SUMMARY.md                     # Краткое описание
```