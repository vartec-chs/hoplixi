# IconPickerButton - Универсальный виджет для выбора иконки

Виджет для выбора иконки из базы данных с адаптивным интерфейсом и настраиваемым внешним видом.

## Особенности

- ✅ **Адаптивный интерфейс**: автоматически выбирает между диалогом и bottom sheet в зависимости от размера экрана
- ✅ **Пагинация**: эффективная загрузка больших списков иконок
- ✅ **Поиск и фильтрация**: поиск по имени и фильтрация по типу файла
- ✅ **Превью иконки**: отображает выбранную иконку в кнопке
- ✅ **Настраиваемый дизайн**: различные формы кнопки и размеры
- ✅ **Функция очистки**: возможность отменить выбор иконки
- ✅ **Поддержка SVG и растровых форматов**: PNG, JPG, SVG, GIF, BMP, WEBP

## Использование

### Базовый пример

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/features/icons/icons.dart';

class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  String? selectedIconId;
  store.IconData? selectedIconData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IconPickerButton(
          selectedIconId: selectedIconId,
          selectedIcon: selectedIconData,
          onIconSelected: (iconId) async {
            // Загружаем данные иконки для превью
            final iconsService = ref.read(iconsServiceProvider);
            final iconData = await iconsService.getIcon(iconId);
            
            setState(() {
              selectedIconId = iconId;
              selectedIconData = iconData;
            });
          },
          onIconCleared: () {
            setState(() {
              selectedIconId = null;
              selectedIconData = null;
            });
          },
          label: 'Выбрать иконку',
        ),
      ),
    );
  }
}
```

### Настройка внешнего вида

```dart
IconPickerButton(
  selectedIconId: selectedIconId,
  selectedIcon: selectedIconData,
  onIconSelected: onIconSelected,
  onIconCleared: onIconCleared,
  
  // Размер кнопки
  size: 120,
  
  // Подпись под кнопкой
  label: 'Иконка категории',
  
  // Форма кнопки
  shape: IconPickerButtonShape.rounded,
  
  // Показывать ли кнопку очистки
  showClearButton: true,
  
  // Текст для пустого состояния
  emptyText: 'Добавить иконку',
  
  // Включена ли кнопка
  enabled: true,
)
```

### Доступные формы кнопки

```dart
// Квадратная форма с небольшим скруглением
shape: IconPickerButtonShape.square

// Скругленная форма
shape: IconPickerButtonShape.rounded

// Круглая форма
shape: IconPickerButtonShape.circle
```

## Параметры

### IconPickerButton

| Параметр | Тип | Описание | По умолчанию |
|----------|-----|----------|-------------|
| `selectedIconId` | `String?` | ID выбранной иконки | `null` |
| `selectedIcon` | `store.IconData?` | Данные выбранной иконки для превью | `null` |
| `onIconSelected` | `ValueChanged<String>` | Callback при выборе иконки | обязательный |
| `onIconCleared` | `VoidCallback?` | Callback при очистке иконки | `null` |
| `size` | `double?` | Размер кнопки | адаптивный |
| `label` | `String?` | Подпись под кнопкой | `null` |
| `showClearButton` | `bool` | Показывать кнопку очистки | `true` |
| `shape` | `IconPickerButtonShape` | Форма кнопки | `square` |
| `emptyText` | `String` | Текст для пустого состояния | `'Выбрать иконку'` |
| `enabled` | `bool` | Включена ли кнопка | `true` |

### IconPickerModal

| Параметр | Тип | Описание | По умолчанию |
|----------|-----|----------|-------------|
| `selectedIconId` | `String?` | ID текущей выбранной иконки | `null` |
| `onIconSelected` | `Function(String, IconData)` | Callback при выборе иконки | обязательный |
| `isBottomSheet` | `bool` | Отображается как bottom sheet | `false` |
| `title` | `String` | Заголовок модального окна | `'Выбрать иконку'` |
| `pageSize` | `int` | Размер страницы для пагинации | `20` |

## Адаптивное поведение

Виджет автоматически адаптируется к размеру экрана:

### Мобильные устройства
- Открывается bottom sheet
- 4 колонки в сетке иконок
- Компактные размеры элементов

### Планшеты
- Открывается диалоговое окно
- 6 колонок в сетке иконок
- Средние размеры элементов

### Десктоп
- Открывается диалоговое окно
- До 10 колонок в зависимости от ширины экрана
- Полные размеры элементов

## Интеграция с Riverpod

Виджет использует Riverpod для управления состоянием и доступа к сервисам:

```dart
// Используется автоматически внутри виджета
final iconsService = ref.read(iconsServiceProvider);
```

## Обработка ошибок

Виджет автоматически обрабатывает ошибки загрузки иконок и отображает соответствующие сообщения пользователю.

## Производительность

- **Ленивая загрузка**: иконки загружаются по страницам
- **Кэширование**: данные иконок кэшируются в памяти
- **Оптимизированные изображения**: SVG иконки рендерятся эффективно

## Доступность

- Поддержка screen readers
- Tooltips для кнопок
- Клавиатурная навигация
- Семантические метки

## Примеры использования

Полный пример использования можно найти в файле:
`lib/features/password_manager/dashboard/features/icons/examples/icon_picker_example.dart`

## Зависимости

Виджет требует следующие зависимости:
- `flutter_riverpod` - для управления состоянием
- `responsive_framework` - для адаптивности
- `flutter_svg` - для отображения SVG иконок
- `hoplixi_store` - для доступа к базе данных

## Связанные виджеты

- `SelectableIconCard` - карточка иконки для выбора
- `IconCard` - полная карточка иконки с действиями
- `IconPickerModal` - модальное окно выбора иконки
