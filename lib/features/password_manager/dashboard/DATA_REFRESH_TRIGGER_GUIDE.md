# Система оповещений об обновлении данных

## Обзор

Реализована система оповещений для автоматического обновления данных при изменениях. Система позволяет:

- Оповещать о необходимости перезапроса данных
- Централизованно управлять обновлениями
- Автоматически обновлять UI при изменениях
- Предоставлять удобные методы для триггеринга обновлений

## Архитектура

### Основные компоненты

1. **`DataRefreshTriggerProvider`** (`data_refresh_trigger_provider.dart`)
   - Основной провайдер для управления триггерами обновления
   - Хранит timestamp последнего обновления
   - Предоставляет методы для триггеринга обновлений

2. **`DataRefreshHelper`** - утилитарный класс
   - Удобные методы для различных типов обновлений
   - Поддержка контекстной информации об обновлениях

3. **Интеграция с существующими провайдерами**
   - `PaginatedPasswordsProvider` автоматически слушает триггер
   - При изменении триггера данные перезагружаются

### Провайдеры

```dart
/// Основной провайдер триггера обновления
final dataRefreshTriggerProvider = NotifierProvider<DataRefreshTriggerNotifier, DateTime>(
  () => DataRefreshTriggerNotifier(),
);

/// Провайдер для получения времени последнего обновления
final lastDataRefreshProvider = Provider<DateTime>((ref) {
  return ref.watch(dataRefreshTriggerProvider);
});

/// Провайдер для проверки устаревания данных
final isDataStaleProvider = Provider.family<bool, Duration>((ref, maxAge) {
  final lastRefresh = ref.watch(dataRefreshTriggerProvider);
  final now = DateTime.now();
  return now.difference(lastRefresh) > maxAge;
});
```

## Использование

### Базовое использование

```dart
// Триггер обновления всех данных
ref.read(dataRefreshTriggerProvider.notifier).triggerRefresh();

// Триггер обновления для конкретного типа сущности
ref.read(dataRefreshTriggerProvider.notifier).triggerRefreshForEntity('password');

// Триггер с дополнительной информацией
ref.read(dataRefreshTriggerProvider.notifier).triggerRefreshWithInfo(
  'Создан новый пароль',
  data: {'action': 'create', 'entityType': 'password'},
);
```

### Использование DataRefreshHelper

```dart
// Обновление паролей
DataRefreshHelper.refreshPasswords(ref);

// Обновление заметок
DataRefreshHelper.refreshNotes(ref);

// Обновление OTP
DataRefreshHelper.refreshOtp(ref);

// Обновление всех данных
DataRefreshHelper.refreshAll(ref);

// Обновление после создания
DataRefreshHelper.refreshAfterCreate(ref, 'password');

// Обновление после изменения
DataRefreshHelper.refreshAfterUpdate(ref, 'password', 'password-id');

// Обновление после удаления
DataRefreshHelper.refreshAfterDelete(ref, 'password', 'password-id');
```

### Отслеживание обновлений в UI

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRefresh = ref.watch(lastDataRefreshProvider);
    final isStale = ref.watch(isDataStaleProvider(const Duration(minutes: 5)));

    return Column(
      children: [
        Text('Последнее обновление: ${_formatDateTime(lastRefresh)}'),
        if (isStale) ...[
          Icon(Icons.warning, color: Colors.orange),
          Text('Данные могут быть устаревшими'),
        ],
      ],
    );
  }
}
```

### Интеграция в существующие провайдеры

Провайдеры автоматически слушают триггер обновления:

```dart
class PaginatedPasswordsNotifier extends AsyncNotifier<PaginatedPasswordsState> {
  @override
  Future<PaginatedPasswordsState> build() async {
    // ... другие слушатели

    // Слушаем триггер обновления данных
    ref.listen(dataRefreshTriggerProvider, (previous, next) {
      if (previous != next) {
        logDebug('PaginatedPasswordsNotifier: Триггер обновления данных');
        _resetAndLoad(); // Автоматическая перезагрузка
      }
    });

    return _loadInitialData();
  }
}
```

## Сценарии использования

### 1. После создания нового элемента

```dart
// В сервисе после создания пароля
await passwordService.createPassword(passwordData);
DataRefreshHelper.refreshAfterCreate(ref, 'password');
```

### 2. После обновления элемента

```dart
// В сервисе после обновления
await passwordService.updatePassword(id, updateData);
DataRefreshHelper.refreshAfterUpdate(ref, 'password', id);
```

### 3. После удаления элемента

```dart
// В сервисе после удаления
await passwordService.deletePassword(id);
DataRefreshHelper.refreshAfterDelete(ref, 'password', id);
```

### 4. После импорта/экспорта данных

```dart
// После импорта данных
await importService.importPasswords(file);
DataRefreshHelper.refreshAll(ref);
```

### 5. После синхронизации с облаком

```dart
// После синхронизации
await syncService.syncWithCloud();
DataRefreshHelper.refreshAll(ref);
```

## Преимущества

1. **Централизованное управление** - один источник правды для обновлений
2. **Автоматическая реактивность** - UI обновляется автоматически
3. **Гибкость** - поддержка различных типов обновлений
4. **Отслеживаемость** - подробное логирование всех обновлений
5. **Производительность** - только необходимые перезагрузки данных

## Отладка

Система включает подробное логирование:

```dart
// Логи триггера
logDebug('DataRefreshTriggerNotifier: Триггер обновления в $now');

// Логи реакции провайдеров
logDebug('PaginatedPasswordsNotifier: Триггер обновления данных');
```

## Будущие улучшения

1. **Селективные обновления** - обновление только измененных элементов
2. **Оптимистичные обновления** - мгновенное обновление UI до подтверждения сервера
3. **Кэширование** - сохранение данных между сессиями
4. **Оффлайн режим** - обработка обновлений при отсутствии сети
5. **Конфликты** - разрешение конфликтов при одновременных изменениях

## Примеры в коде

Смотрите `DashboardSliverAppBarExampleScreen` для демонстрации использования:

- Кнопка синхронизации (синяя) - триггерит обновление паролей
- Отображение времени последнего обновления в карточке состояния
- Автоматическое обновление списка при триггере
