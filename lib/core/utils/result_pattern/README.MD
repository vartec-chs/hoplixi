# Result Pattern - Production-Ready Implementation

Полноценная реализация Result Pattern на базе `freezed` sealed классов для типобезопасной обработки результатов операций.

## Основные возможности

- ✅ **Type-safe**: Полная типобезопасность благодаря sealed классам
- ✅ **Exhaustive**: Компилятор требует обработки всех случаев
- ✅ **Functional**: Поддержка map, flatMap, fold и других функциональных операций
- ✅ **Async-ready**: Расширения для работы с `Future<Result>`
- ✅ **Collection support**: Работа с коллекциями результатов
- ✅ **Railway-oriented**: Цепочки операций с автоматической обработкой ошибок
- ✅ **Zero secrets in logs**: Безопасность данных

## Базовое использование

### Создание результатов

```dart
// Успех
Result<User, AppError> success = Result.success(user);

// Ошибка
Result<User, AppError> failure = Result.failure(AppError.notFound());

// Из nullable
Result<User, AppError> result = ResultConstructors.fromNullable(
  nullableUser,
  () => AppError.notFound(),
);

// С обработкой исключений
Result<User, AppError> result = ResultConstructors.tryCatch(
  () => parseUser(json),
  (error, stack) => AppError.parse(error.toString()),
);

// Асинхронно с обработкой исключений
Future<Result<User, AppError>> result = ResultConstructors.tryCatchAsync(
  () => api.getUser(id),
  (error, stack) => AppError.network(error.toString()),
);
```

### Обработка результатов

```dart
// Pattern matching с when
result.when(
  success: (user) => print('Success: ${user.name}'),
  failure: (error) => print('Error: ${error.message}'),
);

// Fold - преобразование в единое значение
String message = result.fold(
  onSuccess: (user) => 'Welcome, ${user.name}',
  onFailure: (error) => 'Error: ${error.message}',
);

// Switch expression
final widget = switch (result) {
  Success(data: final user) => UserWidget(user),
  Failure(error: final error) => ErrorWidget(error),
};

// Проверка состояния
if (result.isSuccess) {
  print('Got data: ${result.dataOrNull}');
}
```

### Извлечение значений

```dart
// Получить данные или null
User? user = result.dataOrNull;

// Получить ошибку или null
AppError? error = result.errorOrNull;

// Получить данные или бросить исключение
User user = result.getOrThrow();

// Получить данные или значение по умолчанию
User user = result.getOrElse((error) => User.guest());
User user = result.getOrDefault(User.guest());

// Конвертация в nullable
User? user = result.toNullable();
AppError? error = result.toNullableError();
```

## Трансформации

### Map - преобразование успешного значения

```dart
Result<User, AppError> userResult = await getUser(id);

// Простой map
Result<String, AppError> nameResult = userResult.map((user) => user.name);

// Несколько трансформаций
Result<int, AppError> lengthResult = userResult
    .map((user) => user.name)
    .map((name) => name.length);
```

### FlatMap - цепочка операций

```dart
// Railway-oriented programming
Result<Order, AppError> orderResult = await getUser(userId)
    .flatMap((user) => validateUser(user))
    .flatMap((user) => getUserOrders(user.id))
    .flatMap((orders) => selectLatestOrder(orders));

// Асинхронно
Future<Result<Order, AppError>> orderResult = getUser(userId)
    .flatMapAsync((user) => validateUser(user))
    .flatMapAsync((user) => getUserOrders(user.id))
    .flatMapAsync((orders) => selectLatestOrder(orders));
```

### MapAsync - асинхронные трансформации с FutureOr

```dart
// mapAsync принимает FutureOr<R> - можно передавать как sync, так и async функции!

// Синхронный трансформер
Future<Result<String, DbError>> syncResult = service
    .getPassword('id')
    .mapAsync((password) => password.title.toUpperCase());

// Асинхронный трансформер - не нужен дополнительный await!
Future<Result<String, DbError>> asyncResult = service
    .getPassword('id')
    .mapAsync((password) async {
      await someAsyncOperation();
      return password.title.toUpperCase();
    });

// То же самое для mapErrorAsync
Future<Result<User, AppError>> errorResult = service
    .getUser('id')
    .mapErrorAsync((dbError) async {
      await logError(dbError);
      return AppError.fromDbError(dbError);
    });
```

### MapError - преобразование ошибок

```dart
Result<User, UiError> result = userResult.mapError((apiError) => 
  UiError.fromApiError(apiError)
);

// Цепочка преобразований ошибок
result
    .mapError((e) => e.addContext('Getting user'))
    .mapError((e) => e.toUserFriendly());
```

## Side Effects

### OnSuccess / OnFailure

```dart
result
    .onSuccess((user) => logger.info('Got user: ${user.id}'))
    .onFailure((error) => logger.error('Failed: ${error.message}'));

// Асинхронно
await getUserResult()
    .onSuccessAsync((user) async => await cache.save(user))
    .onFailureAsync((error) async => await analytics.logError(error));
```

## Восстановление после ошибок

### Recover

```dart
// Предоставить альтернативное значение
Result<User, AppError> result = getUserResult()
    .recover((error) => User.guest());

// Предоставить альтернативный Result
Result<User, AppError> result = getUserResult()
    .recoverWith((error) => getCachedUser());

// Асинхронно
await getUserResult()
    .recoverAsync((error) async => await loadFromCache())
    .recoverWithAsync((error) async => await fallbackApi.getUser(id));
```

## Работа с коллекциями

### Sequence - все или ничего

```dart
List<Result<User, AppError>> results = await getUserResults();

// Получить список всех успехов или первую ошибку
Result<List<User>, AppError> allUsers = results.sequence();

allUsers.when(
  success: (users) => print('Got ${users.length} users'),
  failure: (error) => print('At least one failed: $error'),
);
```

### Collect - выборочный сбор

```dart
List<Result<User, AppError>> results = await getUserResults();

// Собрать только успешные
List<User> successfulUsers = results.collectSuccesses();

// Собрать только ошибки
List<AppError> errors = results.collectFailures();

// Разделить на успехи и ошибки
final (:successes, :failures) = results.partition();
print('Success: ${successes.length}, Failures: ${failures.length}');
```

## Комбинирование результатов

```dart
// Два результата
Result<(User, Settings), AppError> combined = ResultConstructors.combine2(
  userResult,
  settingsResult,
);

// Три результата
Result<(User, Settings, Preferences), AppError> combined = 
  ResultConstructors.combine3(
    userResult,
    settingsResult,
    preferencesResult,
  );

// Четыре результата
Result<(User, Settings, Preferences, Theme), AppError> combined = 
  ResultConstructors.combine4(
    userResult,
    settingsResult,
    preferencesResult,
    themeResult,
  );

// Использование
combined.when(
  success: (data) {
    final (user, settings, preferences, theme) = data;
    // Все данные доступны
  },
  failure: (error) => handleError(error),
);
```

## Примеры использования в Hoplixi

### В сервисах (Repository layer)

```dart
class PasswordsService {
  Future<Result<Password, DbError>> getPassword(String id) async {
    return ResultConstructors.tryCatchAsync(
      () async {
        final password = await _dao.getPasswordById(id);
        if (password == null) {
          throw DbError.notFound('Password $id not found');
        }
        return password;
      },
      (error, stack) {
        logError('getPassword', error, stack);
        return DbError.unknown(error.toString());
      },
    );
  }

  Future<Result<List<Password>, DbError>> getAllPasswords() async {
    return ResultConstructors.tryCatchAsync(
      () => _dao.watchAllPasswords().first,
      (error, stack) {
        logError('getAllPasswords', error, stack);
        return DbError.query(error.toString());
      },
    );
  }

  Future<Result<Password, DbError>> createPassword(
    PasswordInput input,
  ) async {
    return ResultConstructors.tryCatchAsync(
      () async {
        final id = UuidGenerator.generate();
        final password = Password(
          id: id,
          title: input.title,
          // ... остальные поля
        );
        await _dao.insertPassword(password);
        return password;
      },
      (error, stack) {
        logError('createPassword', error, stack);
        return DbError.insert(error.toString());
      },
    );
  }
}
```

### В провайдерах (UI layer)

```dart
@riverpod
class PasswordsNotifier extends _$PasswordsNotifier {
  @override
  Future<List<Password>> build() async {
    final service = ref.watch(passwordsServiceProvider);
    final result = await service.getAllPasswords();
    
    return result.fold(
      onSuccess: (passwords) => passwords,
      onFailure: (error) {
        logError('Failed to load passwords', error);
        showErrorToast(error.toUserMessage());
        return [];
      },
    );
  }

  Future<void> addPassword(PasswordInput input) async {
    final service = ref.watch(passwordsServiceProvider);
    
    final result = await service.createPassword(input);
    
    result
        .onSuccess((password) {
          showSuccessToast('Пароль создан');
          ref.invalidateSelf();
        })
        .onFailure((error) {
          logError('Failed to create password', error);
          showErrorToast(error.toUserMessage());
        });
  }
}
```

### Railway-oriented processing

```dart
Future<Result<ProcessedData, AppError>> processUserData(String userId) async {
  return getUser(userId)
      .flatMapAsync((user) => validateUser(user))
      .flatMapAsync((user) => enrichUserData(user))
      .flatMapAsync((enriched) => saveToDatabase(enriched))
      .mapAsync((saved) => ProcessedData.from(saved))
      .onSuccessAsync((data) async {
        await analytics.track('user_processed', data.id);
        logInfo('Successfully processed user ${data.id}');
      })
      .onFailureAsync((error) async {
        await analytics.trackError('user_processing_failed', error);
        logError('Failed to process user', error);
      });
}
```

### Работа с множественными операциями

```dart
Future<Result<DashboardData, AppError>> loadDashboard() async {
  final results = await Future.wait([
    getUserProfile(),
    getUserStats(),
    getUserNotifications(),
  ]);

  return ResultConstructors.combine3(
    results[0],
    results[1],
    results[2],
  ).map((data) {
    final (profile, stats, notifications) = data;
    return DashboardData(
      profile: profile,
      stats: stats,
      notifications: notifications,
    );
  });
}
```

### Обработка ошибок с fallback

```dart
Future<Result<User, AppError>> getUserWithFallback(String id) async {
  return getFromCache(id)
      .recoverWithAsync((_) => getFromApi(id))
      .recoverWithAsync((_) => getFromLocalDb(id))
      .recover((_) => User.guest());
}
```

## Типы ошибок

Рекомендуется определить собственные типы ошибок:

```dart
@freezed
sealed class AppError with _$AppError {
  const factory AppError.network(String message) = NetworkError;
  const factory AppError.notFound(String resource) = NotFoundError;
  const factory AppError.validation(String field, String message) = ValidationError;
  const factory AppError.permission(String action) = PermissionError;
  const factory AppError.unknown(String message) = UnknownError;

  const AppError._();

  String toUserMessage() => when(
    network: (msg) => 'Ошибка сети: $msg',
    notFound: (res) => '$res не найден',
    validation: (field, msg) => 'Ошибка в поле $field: $msg',
    permission: (action) => 'Нет прав для: $action',
    unknown: (msg) => 'Неизвестная ошибка: $msg',
  );
}

@freezed
sealed class DbError with _$DbError {
  const factory DbError.notFound(String message) = DbNotFoundError;
  const factory DbError.query(String message) = DbQueryError;
  const factory DbError.insert(String message) = DbInsertError;
  const factory DbError.update(String message) = DbUpdateError;
  const factory DbError.delete(String message) = DbDeleteError;
  const factory DbError.unknown(String message) = DbUnknownError;
}
```

## Best Practices

1. **Не логируйте секреты**: используйте безопасные сообщения
2. **Используйте typed errors**: создавайте специфичные типы ошибок
3. **Цепочка операций**: используйте flatMap для последовательных операций
4. **Асинхронность**: используйте async расширения для Future
5. **Не используйте getOrThrow без необходимости**: предпочитайте pattern matching
6. **Обрабатывайте все случаи**: sealed классы заставляют обработать все варианты
7. **Логируйте в onFailure**: side effects для логирования
8. **Восстанавливайтесь gracefully**: используйте recover/recoverWith

## Генерация кода

После изменений запустите:

```bash
dart run build_runner build --delete-conflicting-outputs
```


## Миграция с ServiceResult

```dart
// Было
ServiceResult<User> result = await service.getUser(id);
if (result.isSuccess) {
  final user = result.data;
}

// Стало
Result<User, AppError> result = await service.getUser(id);
result.when(
  success: (user) => handleUser(user),
  failure: (error) => handleError(error),
);
```

## Преимущества

- **Типобезопасность**: компилятор проверит все варианты
- **Отсутствие null checks**: явная обработка успеха и ошибок
- **Композиция**: легко комбинировать операции
- **Тестируемость**: легко писать и тестировать
- **Читаемость**: декларативный стиль кода
- **Безопасность**: никаких секретов в логах

## Дополнительные возможности

### Swap

```dart
Result<Error, Success> swapped = result.swap();
```

### Extension методы

```dart
// Для любого значения
User user = getUser();
Result<User, AppError> result = user.toSuccess<AppError>();

// Для ошибки
AppError error = AppError.notFound();
Result<User, AppError> result = error.toFailure<User>();

// Для nullable
User? maybeUser = getNullableUser();
Result<User, AppError> result = maybeUser.toResult(() => AppError.notFound());
```

---

**Версия**: 1.0.0  
**Требования**: `freezed`, `freezed_annotation`, Dart 3.0+  
**Лицензия**: MIT
