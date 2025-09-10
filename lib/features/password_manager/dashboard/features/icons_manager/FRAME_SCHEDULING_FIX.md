# Исправление ошибки "Build scheduled during frame"

## Проблема

Получали ошибку:

```text
Build scheduled during frame.
While the widget tree was being built, laid out, and painted, a new frame was scheduled to rebuild the widget tree.
This might be because setState() was called from a layout or paint callback.
```

## Причина

Ошибка возникала из-за того, что `setState()` вызывался во время построения UI-дерева в следующих местах:

1. **IconPickerModal**:
   - В методах `_onSearchChanged()` и `_onTypeFilterChanged()`
   - В методе `_goToPage()`
   - В методе `_applyFilters()`

2. **IconPickerExample**:
   - В методах `_onIconSelected()` и `_onIconCleared()`

## Решение

### 1. Использование SchedulerBinding.instance.addPostFrameCallback()

Обернули все вызовы `setState()` в callback, который выполняется после завершения текущего кадра:

```dart
// Неправильно:
setState(() {
  _selectedIconId = iconId;
});

// Правильно:
SchedulerBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  setState(() {
    _selectedIconId = iconId;
  });
});
```

### 2. Дебаунсинг для поиска

Для поля поиска добавили дебаунсинг с таймером, чтобы избежать множественных вызовов `setState()`:

```dart
Timer? _debounceTimer;

void _onSearchChanged(String query) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    if (!mounted) return;
    setState(() {
      _searchQuery = query;
      _currentPage = 0;
    });
    _loadCurrentPage();
  });
}
```

### 3. Проверка mounted

Во всех callback'ах добавили проверку `mounted` для предотвращения вызовов на уничтоженных виджетах:

```dart
if (!mounted) return;
```

## Изменённые файлы

1. **IconPickerModal** (`icon_picker_modal.dart`):
   - Добавлен импорт `dart:async` для Timer
   - Добавлено поле `Timer? _debounceTimer`
   - Переписаны методы `_onSearchChanged()`, `_onTypeFilterChanged()`, `_goToPage()`
   - Удален неиспользуемый метод `_applyFilters()`
   - Обновлен `dispose()` для отмены таймера

2. **IconPickerExample** (`icon_picker_example.dart`):
   - Добавлен импорт `package:flutter/scheduler.dart`
   - Переписаны методы `_onIconSelected()` и `_onIconCleared()`

## Результат

- ✅ Устранена ошибка "Build scheduled during frame"
- ✅ Улучшена производительность благодаря дебаунсингу поиска
- ✅ Предотвращены утечки памяти через проверки `mounted`
- ✅ Сохранена вся функциональность виджетов

## Рекомендации

При работе с setState() в callback'ах всегда используйте один из подходов:

1. **SchedulerBinding.instance.addPostFrameCallback()** - для единичных вызовов
2. **Timer с дебаунсингом** - для частых событий (поиск, скролл)
3. **Future.microtask()** - как альтернатива для простых случаев

Всегда проверяйте `mounted` перед вызовом `setState()` в асинхронных операциях.
