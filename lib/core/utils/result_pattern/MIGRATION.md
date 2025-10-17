# Миграция на Result Pattern

## Быстрая миграция с ServiceResult на Result

### Было (ServiceResult)
```dart
class PasswordsService {
  Future<ServiceResult<Password>> getPassword(String id) async {
    try {
      final password = await _dao.getPasswordById(id);
      if (password == null) {
        return ServiceResult.failure('Password not found');
      }
      return ServiceResult.success(password);
    } catch (e, stack) {
      logError('getPassword', e, stack);
      return ServiceResult.failure('Failed to get password');
    }
  }
}

// Использование
final result = await service.getPassword(id);
if (result.isSuccess) {
  final password = result.data;
  print('Got: ${password.title}');
} else {
  print('Error: ${result.errorMessage}');
}
```

### Стало (Result Pattern)
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
        if (error is DbError) return error;
        logError('getPassword', error, stack);
        return DbError.query('Failed to get password');
      },
    );
  }
}

// Использование - вариант 1: when
final result = await service.getPassword(id);
result.when(
  success: (password) => print('Got: ${password.title}'),
  failure: (error) => print('Error: ${error.toUserMessage()}'),
);

// Использование - вариант 2: switch
final result = await service.getPassword(id);
switch (result) {
  case Success(data: final password):
    print('Got: ${password.title}');
  case Failure(error: final error):
    print('Error: ${error.toUserMessage()}');
}
```

## Чек-лист миграции

### 1. Сервисы (Repository layer)

- [ ] Заменить возвращаемый тип с `ServiceResult<T>` на `Result<T, ErrorType>`
- [ ] Выбрать подходящий тип ошибки: `DbError`, `AppError`, `CryptoError`, etc.
- [ ] Использовать `ResultConstructors.tryCatchAsync` для обёртки операций
- [ ] Бросать типизированные ошибки вместо возврата `ServiceResult.failure`
- [ ] Удалить ручные try-catch блоки (tryCatchAsync делает это за вас)

**До:**
```dart
Future<ServiceResult<List<Password>>> getAllPasswords() async {
  try {
    final passwords = await _dao.watchAllPasswords().first;
    return ServiceResult.success(passwords);
  } catch (e, stack) {
    logError('getAllPasswords', e, stack);
    return ServiceResult.failure('Failed to load passwords');
  }
}
```

**После:**
```dart
Future<Result<List<Password>, DbError>> getAllPasswords() async {
  return ResultConstructors.tryCatchAsync(
    () => _dao.watchAllPasswords().first,
    (error, stack) {
      logError('getAllPasswords', error, stack);
      return DbError.query('Failed to load passwords');
    },
  );
}
```

### 2. Провайдеры (UI layer)

- [ ] Заменить проверки `isSuccess`/`isFailure` на `when` или pattern matching
- [ ] Использовать `fold` для преобразования в UI состояния
- [ ] Применять `onSuccess`/`onFailure` для side effects (логирование, тосты)
- [ ] Использовать `getOrElse`/`getOrDefault` для значений по умолчанию

**До:**
```dart
@riverpod
class PasswordsNotifier extends _$PasswordsNotifier {
  @override
  Future<List<Password>> build() async {
    final service = ref.watch(passwordsServiceProvider);
    final result = await service.getAllPasswords();
    
    if (result.isSuccess) {
      return result.data!;
    } else {
      logError('Failed to load passwords', result.errorMessage);
      showErrorToast(result.errorMessage ?? 'Unknown error');
      return [];
    }
  }
}
```

**После:**
```dart
@riverpod
class PasswordsNotifier extends _$PasswordsNotifier {
  @override
  Future<List<Password>> build() async {
    final service = ref.watch(passwordsServiceProvider);
    
    return service
        .getAllPasswords()
        .onFailureAsync((error) async {
          logError('Failed to load passwords', error);
          showErrorToast(error.toUserMessage());
        })
        .then((result) => result.getOrDefault([]));
  }
}
```

### 3. Railway-oriented Programming

Цепочки операций становятся проще:

**До:**
```dart
Future<ServiceResult<Order>> processOrder(String userId) async {
  final userResult = await getUser(userId);
  if (!userResult.isSuccess) {
    return ServiceResult.failure(userResult.errorMessage);
  }
  
  final user = userResult.data!;
  final validationResult = await validateUser(user);
  if (!validationResult.isSuccess) {
    return ServiceResult.failure(validationResult.errorMessage);
  }
  
  final ordersResult = await getUserOrders(user.id);
  if (!ordersResult.isSuccess) {
    return ServiceResult.failure(ordersResult.errorMessage);
  }
  
  final orders = ordersResult.data!;
  return selectLatestOrder(orders);
}
```

**После:**
```dart
Future<Result<Order, AppError>> processOrder(String userId) async {
  return getUser(userId)
      .flatMapAsync((user) => validateUser(user))
      .flatMapAsync((user) => getUserOrders(user.id))
      .flatMapAsync((orders) => selectLatestOrder(orders));
}
```

### 4. Обработка ошибок в UI

**До:**
```dart
Future<void> addPassword(PasswordInput input) async {
  final service = ref.watch(passwordsServiceProvider);
  final result = await service.createPassword(input);
  
  if (result.isSuccess) {
    showSuccessToast('Пароль создан');
    ref.invalidateSelf();
  } else {
    showErrorToast(result.errorMessage ?? 'Failed to create');
  }
}
```

**После:**
```dart
Future<void> addPassword(PasswordInput input) async {
  final service = ref.watch(passwordsServiceProvider);
  
  await service
      .createPassword(input)
      .onSuccessAsync((password) async {
        showSuccessToast('Пароль создан');
        ref.invalidateSelf();
      })
      .onFailureAsync((error) async {
        logError('Failed to create password', error);
        showErrorToast(error.toUserMessage());
      });
}
```

### 5. Преимущества после миграции

✅ **Типобезопасность**: компилятор проверит обработку всех вариантов  
✅ **Нет null-checks**: нет необходимости в `result.data!`  
✅ **Композиция**: легко комбинировать операции через flatMap  
✅ **Exhaustive**: sealed классы требуют обработки всех случаев  
✅ **Читаемость**: декларативный стиль вместо императивного  
✅ **Тестируемость**: легче писать и поддерживать тесты  
✅ **Безопасность**: типизированные ошибки без утечки секретов  

### 6. Общие паттерны

#### Получить или дефолт
```dart
// Было
final user = result.isSuccess ? result.data! : User.guest();

// Стало
final user = result.getOrDefault(User.guest());
// или
final user = result.getOrElse((error) => User.guest());
```

#### Side effects
```dart
// Было
if (result.isSuccess) {
  logInfo('Success');
} else {
  logError('Failed', result.errorMessage);
}

// Стало
result
    .onSuccess((data) => logInfo('Success'))
    .onFailure((error) => logError('Failed', error));
```

#### Трансформация
```dart
// Было
ServiceResult<String> nameResult;
if (userResult.isSuccess) {
  nameResult = ServiceResult.success(userResult.data!.name);
} else {
  nameResult = ServiceResult.failure(userResult.errorMessage);
}

// Стало
final nameResult = userResult.map((user) => user.name);
```

#### Восстановление
```dart
// Было
final userResult = await getUser(id);
final user = userResult.isSuccess 
    ? userResult.data! 
    : await getCachedUser(id) ?? User.guest();

// Стало
final user = await getUser(id)
    .recoverWithAsync((error) => getCachedUser(id))
    .then((result) => result.getOrDefault(User.guest()));
```

## Порядок миграции

1. ✅ Создать Result Pattern типы (уже готово)
2. ✅ Создать типы ошибок (AppError, DbError, etc.)
3. 🔄 Мигрировать сервисы (начните с простых)
4. 🔄 Обновить провайдеры (один за другим)
5. 🔄 Удалить ServiceResult после полной миграции
6. 🔄 Обновить тесты

## Полезные команды

```bash
# Генерация freezed кода после создания новых типов ошибок
dart run build_runner build --delete-conflicting-outputs

# Поиск всех использований ServiceResult
# (для отслеживания прогресса миграции)
grep -r "ServiceResult" lib/
```

## Примеры типов ошибок

Используйте существующие типы из `common_errors.dart`:
- `AppError` - общие ошибки приложения
- `DbError` - ошибки базы данных
- `CryptoError` - ошибки шифрования
- `ImportExportError` - ошибки импорта/экспорта
- `SyncError` - ошибки синхронизации

Или создайте свои специфичные типы по аналогии.

---

**Документация**: см. `lib/core/utils/result_pattern/README.MD`  
**Примеры**: см. `lib/core/utils/result_pattern/result_example.dart`  
**Hoplixi примеры**: см. `lib/core/utils/result_pattern/hoplixi_example.dart`
