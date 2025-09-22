# FilterModal - Универсальный фильтр для Dashboard

`FilterModal` - это адаптируемое модальное окно фильтра, которое работает с провайдерами типа сущности и фильтров, автоматически отображая соответствующие фильтры для выбранного типа сущности.

## Основные возможности

- **Автоматическая адаптация**: Отображает фильтры в зависимости от выбранного типа сущности (пароли, заметки, OTP)
- **Интеграция с Riverpod**: Работает с системой провайдеров для управления состоянием
- **Базовые и специфические фильтры**: Поддерживает общие фильтры для всех типов и специфические для каждого типа
- **Категории и теги**: Встроенная поддержка фильтрации по категориям и тегам
- **Поиск**: Полнотекстовый поиск по всем сущностям
- **Валидация**: Автоматическая валидация введенных данных

## Архитектура

### Провайдеры

- `entityTypeControllerProvider` - управление текущим типом сущности
- `baseFilterProvider` - базовые фильтры (поиск, категории, теги, даты)
- `passwordFilterProvider` - специфические фильтры для паролей
- `notesFilterProvider` - специфические фильтры для заметок  
- `otpFilterProvider` - специфические фильтры для OTP

### Секции фильтров

- `BaseFilterSection` - общие фильтры для всех типов
- `PasswordFilterSection` - фильтры для паролей
- `NotesFilterSection` - фильтры для заметок
- `OtpFilterSection` - фильтры для OTP

## Использование

### Основное использование

```dart
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';

// В вашем виджете
void _openFilterModal() {
  showDialog(
    context: context,
    builder: (context) => FilterModal(
      onFilterApplied: () {
        // Обновить список элементов или выполнить другие действия
        print('Фильтры применены');
      },
    ),
  );
}
```

### Управление типом сущности

```dart
// Изменение типа сущности
ref.read(entityTypeControllerProvider.notifier)
   .changeEntityType(EntityType.password);

// Получение текущего типа
final currentType = ref.watch(currentEntityTypeProvider);
```

### Работа с фильтрами

```dart
// Получение текущих фильтров
final baseFilter = ref.watch(baseFilterProvider);
final passwordFilter = ref.watch(passwordFilterProvider);

// Обновление фильтров
ref.read(baseFilterProvider.notifier).updateQuery('test');
ref.read(passwordFilterProvider.notifier).updateName('example');

// Сброс фильтров
ref.read(baseFilterProvider.notifier).reset();
```

### Прослушивание изменений фильтров

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Автоматически перестраивается при изменении фильтров
    final baseFilter = ref.watch(baseFilterProvider);
    final currentEntityType = ref.watch(currentEntityTypeProvider);
    
    return Column(
      children: [
        Text('Текущий тип: ${currentEntityType.label}'),
        Text('Поиск: ${baseFilter.query ?? "не задан"}'),
        Text('Категорий: ${baseFilter.categoryIds.length}'),
      ],
    );
  }
}
```

## Поддерживаемые типы сущностей

### EntityType.password
- Поиск по названию, URL, имени пользователя
- Фильтры наличия данных (URL, имя пользователя, TOTP)
- Статус пароля (скомпрометированный, истекший, часто используемый)
- Сортировка по различным полям

### EntityType.note  
- Поиск по заголовку и содержимому
- Фильтры свойств (закрепленная, есть содержимое, есть вложения)
- Диапазон длины содержимого
- Сортировка по различным полям

### EntityType.otp
- Поиск по издателю и имени аккаунта
- Фильтр по типу OTP (TOTP/HOTP)
- Фильтр по алгоритмам хеширования
- Настройки количества цифр и периода
- Связь с паролями

## Интеграция с категориями и тегами

FilterModal автоматически интегрируется с системой категорий и тегов:

```dart
// Категории загружаются автоматически на основе типа сущности
CategoryType categoryType = _getCategoryType(entityType);

// Теги также загружаются автоматически
TagType tagType = _getTagType(entityType);
```

## Валидация и обработка ошибок

- Автоматическая валидация полей (например, диапазоны дат, числовые значения)
- Отображение ошибок валидации в UI
- Логирование всех операций для отладки
- Toast-уведомления для пользователя

## Настройка и расширение

### Добавление нового типа сущности

1. Добавить новый тип в `EntityType` enum
2. Создать соответствующий filter provider
3. Создать секцию фильтра для нового типа
4. Обновить методы `_getCategoryType` и `_getTagType` в FilterModal
5. Добавить case в `_buildSpecificFiltersSection`

### Кастомизация UI

FilterModal использует существующие компоненты:
- `PrimaryTextField` для полей ввода
- `SmoothButton` для кнопок
- `CategoryFilterWidget` и `TagFilterWidget` для фильтров
- Стандартные Material Design компоненты

## Примеры

Полный пример использования доступен в `filter_modal_example_screen.dart`, который демонстрирует:
- Переключение между типами сущностей
- Открытие FilterModal
- Отображение текущих фильтров
- Обработку изменений фильтров

## Логирование и отладка

FilterModal включает подробное логирование:
- Инициализация и загрузка данных
- Изменения фильтров
- Применение и сброс фильтров
- Ошибки и исключения

Используйте `logDebug`, `logInfo`, `logError` для отслеживания работы компонента.