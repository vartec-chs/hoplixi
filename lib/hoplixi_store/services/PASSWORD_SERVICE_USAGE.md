# PasswordService - Полный сервис для работы с паролями

## Описание

`PasswordService` - это комплексный сервис для работы с паролями в приложении Hoplixi, который предоставляет:

- ✅ CRUD операции с паролями
- ✅ Автоматическую работу с историей изменений
- ✅ Управление категориями и тегами
- ✅ Поиск и фильтрацию
- ✅ Stream-подписки для реактивного UI
- ✅ Статистику и аналитику
- ✅ Batch операции для массовых изменений
- ✅ Проверку целостности данных

## Основные возможности

### 1. Создание паролей

```dart
final passwordService = PasswordService(database);

// Создание простого пароля
final createDto = CreatePasswordDto(
  name: 'Gmail',
  password: 'super_secret_password',
  email: 'user@gmail.com',
  url: 'https://gmail.com',
  categoryId: 'email_category_id',
);

final result = await passwordService.createPassword(
  createDto,
  tagIds: ['work', 'important'], // Добавляем теги
);

if (result.success) {
  print('Пароль создан: ${result.data}');
} else {
  print('Ошибка: ${result.message}');
}
```

### 2. Обновление паролей

```dart
// Обновление пароля с заменой всех тегов
final updateDto = UpdatePasswordDto(
  id: 'password_id',
  name: 'Gmail Account',
  password: 'new_super_secret_password',
  notes: 'Обновлен пароль',
);

final result = await passwordService.updatePassword(
  updateDto,
  tagIds: ['personal', 'email'], // Новые теги
  replaceAllTags: true, // Заменить все теги
);
```

### 3. Поиск и фильтрация

```dart
// Поиск по тексту
final searchResult = await passwordService.searchPasswords(
  searchTerm: 'gmail',
  limit: 20,
);

// Поиск по категории
final categoryResult = await passwordService.searchPasswords(
  categoryId: 'email_category_id',
);

// Поиск по тегам (И условие - пароли должны иметь ВСЕ указанные теги)
final tagsAndResult = await passwordService.searchPasswords(
  tagIds: ['work', 'important'],
  includeTagsInAnd: true,
);

// Поиск по тегам (ИЛИ условие - пароли с ЛЮБЫМ из указанных тегов)
final tagsOrResult = await passwordService.searchPasswords(
  tagIds: ['work', 'personal'],
  includeTagsInAnd: false,
);

// Только избранные пароли
final favoritesResult = await passwordService.searchPasswords(
  isFavorite: true,
);
```

### 4. Работа с деталями пароля

```dart
// Получение полной информации о пароле
final detailsResult = await passwordService.getPasswordDetails('password_id');

if (detailsResult.success) {
  final details = detailsResult.data!;
  print('Пароль: ${details.password.name}');
  print('Теги: ${details.tags.map((t) => t.name).join(', ')}');
  print('Категория: ${details.category?.name ?? 'Без категории'}');
  print('Записей в истории: ${details.historyCount}');
}
```

### 5. Управление тегами

```dart
// Добавление тега к паролю
await passwordService.addTagToPassword('password_id', 'tag_id');

// Удаление тега у пароля
await passwordService.removeTagFromPassword('password_id', 'tag_id');

// Получение тегов пароля
final tagsResult = await passwordService.getPasswordTags('password_id');
```

### 6. Работа с историей

```dart
// Получение истории пароля
final historyResult = await passwordService.getPasswordHistory(
  'password_id',
  limit: 10,
  offset: 0,
);

// Очистка истории пароля
final clearResult = await passwordService.clearPasswordHistory('password_id');
```

### 7. Статистика

```dart
// Получение общей статистики по паролям
final statsResult = await passwordService.getPasswordStatistics();

if (statsResult.success) {
  final stats = statsResult.data!;
  print('Всего паролей: ${stats.totalCount}');
  print('Избранных: ${stats.favoriteCount}');
  print('По категориям: ${stats.countByCategory}');
  print('По тегам: ${stats.countByTag}');
}
```

### 8. Stream подписки для UI

```dart
// Подписка на все пароли
StreamBuilder<List<Password>>(
  stream: passwordService.watchAllPasswords(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) {
          final password = snapshot.data![index];
          return ListTile(title: Text(password.name));
        },
      );
    }
    return CircularProgressIndicator();
  },
);

// Подписка на избранные пароли
StreamBuilder<List<Password>>(
  stream: passwordService.watchFavoritePasswords(),
  builder: (context, snapshot) {
    // UI код
  },
);

// Подписка на пароли конкретной категории
StreamBuilder<List<Password>>(
  stream: passwordService.watchPasswordsByCategory('category_id'),
  builder: (context, snapshot) {
    // UI код
  },
);

// Подписка на теги конкретного пароля
StreamBuilder<List<Tag>>(
  stream: passwordService.watchPasswordTags('password_id'),
  builder: (context, snapshot) {
    // UI код для отображения тегов
  },
);
```

### 9. Создание категорий

```dart
// Создание новой категории для паролей
final categoryDto = CreateCategoryDto(
  name: 'Социальные сети',
  description: 'Пароли от социальных сетей',
  color: 'FF5722',
  type: CategoryType.password,
);

final categoryResult = await passwordService.createCategory(categoryDto);
```

### 10. Batch операции

```dart
// Массовое создание паролей
final passwordDtos = [
  CreatePasswordDto(name: 'Facebook', password: 'pass1'),
  CreatePasswordDto(name: 'Twitter', password: 'pass2'),
  CreatePasswordDto(name: 'Instagram', password: 'pass3'),
];

await passwordService.createPasswordsBatch(passwordDtos);

// Массовое добавление тегов к паролям
await passwordService.addTagsToPasswordsBatch(
  ['password1_id', 'password2_id'],
  ['tag1_id', 'tag2_id'],
);
```

### 11. Утилитарные функции

```dart
// Очистка потерянных связей
final cleanupResult = await passwordService.cleanupOrphanedRelations();
print('Очищено связей: ${cleanupResult.data}');

// Проверка целостности данных
final validationResult = await passwordService.validateDataIntegrity();
final issues = validationResult.data!;
print('Пароли с отсутствующими категориями: ${issues['passwordsWithMissingCategories']}');
print('Потерянные связи тегов: ${issues['orphanedTagRelations']}');
```

## Автоматическая работа с историей

Сервис автоматически сохраняет историю всех изменений паролей:

- ✅ При создании пароля - сохраняется в историю
- ✅ При обновлении пароля - старая версия сохраняется в историю
- ✅ При удалении пароля - финальная версия сохраняется в историю

История создается автоматически через триггеры базы данных, поэтому вы не можете случайно забыть сохранить изменения в историю.

## Обработка ошибок

Все методы возвращают объект `ServiceResult<T>`, который содержит:
- `success` - флаг успешности операции
- `message` - описание результата или ошибки
- `data` - результат операции (если успешна)

```dart
final result = await passwordService.createPassword(dto);

if (result.success) {
  // Операция успешна
  final passwordId = result.data!;
  showSuccessMessage(result.message);
} else {
  // Произошла ошибка
  showErrorMessage(result.message);
}
```

## Логирование

Сервис автоматически логирует все операции с использованием системы логирования приложения:
- INFO - успешные операции
- DEBUG - детальная информация для отладки
- ERROR - ошибки с полным стек-трейсом
- WARNING - предупреждения

## Интеграция с UI

Сервис специально разработан для удобного использования в UI:

1. **Реактивность** - Stream методы для автоматического обновления UI
2. **Детальная информация** - методы возвращают полные объекты с тегами и категориями
3. **Понятные результаты** - описательные сообщения об ошибках и успехе
4. **Оптимизация** - batch операции для массовых изменений
5. **Валидация** - проверка данных перед операциями

Используйте этот сервис как единую точку входа для всех операций с паролями в вашем UI!
