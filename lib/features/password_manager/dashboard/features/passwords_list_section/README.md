# Компонент списка паролей для Hoplixi

Этот модуль реализует полноценный компонент для отображения отфильтрованных паролей с использованием современных подходов Flutter и Riverpod v3.

## Структура компонентов

### 1. PasswordsListController (`passwords_list_controller.dart`)

**Назначение**: Контроллер на основе Riverpod v3 Notifier API для управления состоянием списка паролей.

**Основные возможности**:
- ✅ Использует современный `NotifierProvider` из Riverpod v3
- ✅ Автоматическая интеграция с фильтрами из `FilterSectionController`
- ✅ Реактивное обновление при изменении фильтров
- ✅ Пагинация с размером страницы 50 элементов
- ✅ Оптимистические обновления UI (избранное, удаление)
- ✅ Обработка ошибок с откатом изменений
- ✅ Pull-to-refresh функциональность

**Методы**:
```dart
// Загрузка паролей
await loadPasswords()

// Загрузка дополнительных паролей (пагинация)
await loadMorePasswords()

// Переключение избранного
await toggleFavorite(passwordId)

// Удаление пароля
await deletePassword(passwordId)

// Уведомление об изменениях (для интеграции с формами)
notifyPasswordChanged()
```

**Providers**:
```dart
// Основной контроллер
passwordsListControllerProvider

// Computed providers для удобного доступа
passwordsListProvider           // List<CardPasswordDto>
isPasswordsLoadingProvider     // bool
passwordsErrorProvider         // String?
hasMorePasswordsProvider       // bool
passwordsTotalCountProvider    // int

// Для уведомлений об изменениях
passwordChangeNotifierProvider // void Function()
```

### 2. PasswordsList (`passwords_list.dart`)

**Назначение**: UI компонент для отображения списка паролей с использованием Flutter Slivers.

**Особенности**:
- ✅ Использует `CustomScrollView` с Slivers для оптимальной производительности
- ✅ Автоматическая пагинация при скролле
- ✅ Pull-to-refresh
- ✅ Состояния: загрузка, ошибка, пустой список
- ✅ Современная `ModernPasswordCard` с поддержкой тегов
- ✅ Обработка действий: избранное, редактирование, удаление
- ✅ Анимации и плавные переходы

**Компоненты**:
```dart
PasswordsList()              // Основной виджет списка
ModernPasswordCard()         // Карточка пароля с тегами
```

### 3. ModernPasswordCard

**Возможности карточки пароля**:
- ✅ Отображение тегов (максимум 4, остальные "+N")
- ✅ Отображение категорий с цветовой индикацией
- ✅ Логин и email с иконками
- ✅ Переключение избранного
- ✅ Контекстное меню (редактирование, удаление)
- ✅ Современный Material Design 3

### 4. Интеграция с фильтрами

Компонент автоматически интегрируется с существующим `FilterSectionController`:

```dart
// Автоматическое обновление при изменении фильтра
ref.listen(currentPasswordFilterProvider, (previous, next) {
  if (previous != next) {
    _loadPasswordsWithFilter(next);
  }
});
```

**Поддерживаемые фильтры**:
- Текстовый поиск
- Фильтрация по вкладкам (все, избранные, часто используемые)
- Категории и теги
- Даты создания/изменения
- И другие из `PasswordFilter`

## Использование

### Базовое использование

```dart
class MyPasswordsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          // Ваши фильтры и поиск
          SearchBar(
            onChanged: (query) {
              ref.read(filterSectionControllerProvider.notifier)
                 .updateSearchQuery(query);
            },
          ),
          
          // Список паролей
          Expanded(
            child: PasswordsList(),
          ),
        ],
      ),
    );
  }
}
```

### Интеграция с формами создания/редактирования

```dart
// После создания или редактирования пароля:
onPasswordSaved: () {
  // Уведомляем список об изменениях
  ref.read(passwordChangeNotifierProvider)();
  
  Navigator.pop(context, true);
}
```

### Установка HoplixiStore

```dart
// В инициализации приложения или провайдере
ref.read(passwordsListControllerProvider.notifier)
   .setHoplixiStore(yourHoplixiStoreInstance);
```

## Требования к архитектуре

### Необходимые провайдеры

Вам нужно реализовать следующие провайдеры:

```dart
// Provider для базы данных
final hoplixiStoreProvider = Provider<HoplixiStore>((ref) {
  return yourHoplixiStoreInstance;
});
```

### Зависимости

- `flutter_riverpod: ^2.4.0+`
- Существующий `FilterSectionController`
- `PasswordService` из `hoplixi_store`
- Модели: `CardPasswordDto`, `PasswordFilter`

## Архитектурные особенности

### Современный Riverpod v3

- Использует новый `Notifier` API вместо устаревших `StateNotifier`
- Computed providers для селективной подписки
- Автоматическое управление подписками

### Безопасность

- Отсутствие прямых манипуляций с чувствительными данными в UI
- Использование сервисного слоя для всех операций с паролями
- Безопасная очистка ошибок

### Производительность

- Slivers для оптимизированного скролла
- Пагинация для больших списков
- Оптимистические обновления UI
- Селективные пересборки компонентов

### UX

- Pull-to-refresh
- Состояния загрузки и ошибок
- Анимации и плавные переходы
- Подтверждения для критических действий

## Примеры интеграции

См. `passwords_list_integration_example.dart` для полного примера интеграции всех компонентов с:
- Поиском
- Фильтрами по вкладкам
- Активными фильтрами
- Навигацией к формам
- Обработкой результатов

## Customization

### Изменение размера страницы

```dart
// В PasswordsListController измените:
static const int _pageSize = 100; // вместо 50
```

### Кастомизация карточки

Создайте свою реализацию карточки пароля, реализующую тот же интерфейс:

```dart
class CustomPasswordCard extends StatelessWidget {
  final CardPasswordDto password;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  
  // Ваша реализация
}
```

### Дополнительные фильтры

Расширьте `PasswordFilter` и обновите логику в контроллере для поддержки новых типов фильтрации.

## Troubleshooting

1. **Список не обновляется**: Убедитесь, что `hoplixiStoreProvider` корректно настроен
2. **Ошибки фильтрации**: Проверьте совместимость с `FilterSectionController`
3. **Производительность**: При больших списках рассмотрите увеличение `_pageSize`
4. **Уведомления**: Используйте `passwordChangeNotifierProvider` после изменений паролей

## Дальнейшее развитие

- [ ] Поддержка группировки по категориям
- [ ] Виртуализация для очень больших списков
- [ ] Drag-and-drop сортировка
- [ ] Расширенные анимации переходов
- [ ] Поддержка множественного выбора
- [ ] Экспорт выбранных паролей