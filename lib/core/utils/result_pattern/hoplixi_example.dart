import 'package:hoplixi/core/utils/result_pattern/result_pattern.dart';

/// Пример использования Result Pattern с общими типами ошибок Hoplixi

// Пример модели данных
class Password {
  final String id;
  final String title;
  final String username;
  final String encryptedPassword;

  Password({
    required this.id,
    required this.title,
    required this.username,
    required this.encryptedPassword,
  });
}

// Пример DAO (имитация)
class PasswordDao {
  Future<Password?> getPasswordById(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (id == 'not-found') return null;
    return Password(
      id: id,
      title: 'Example',
      username: 'user@example.com',
      encryptedPassword: 'encrypted_data',
    );
  }

  Future<void> insertPassword(Password password) async {
    await Future.delayed(const Duration(milliseconds: 50));
    // Имитация успеха
  }

  Future<void> deletePassword(String id) async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (id == 'not-found') {
      throw Exception('Password not found');
    }
  }
}

// Пример сервиса с использованием Result Pattern
class PasswordsService {
  final PasswordDao _dao = PasswordDao();

  /// Получение пароля по ID
  Future<Result<Password, DbError>> getPassword(String id) async {
    return ResultConstructors.tryCatchAsync(
      () async {
        final password = await _dao.getPasswordById(id);
        if (password == null) {
          throw DbError.notFound('Password with id $id not found');
        }
        return password;
      },
      (error, stack) {
        if (error is DbError) return error;
        return DbError.query(
          'Failed to get password',
          sql: 'SELECT * FROM passwords WHERE id = ?',
        );
      },
    );
  }

  /// Создание нового пароля
  Future<Result<Password, DbError>> createPassword({
    required String title,
    required String username,
    required String plainPassword,
  }) async {
    return ResultConstructors.tryCatchAsync(
      () async {
        // Валидация
        if (title.isEmpty) {
          throw DbError.constraint('title_not_empty', 'Title cannot be empty');
        }

        // Шифрование (имитация)
        final encrypted = 'encrypted_$plainPassword';

        final password = Password(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          username: username,
          encryptedPassword: encrypted,
        );

        await _dao.insertPassword(password);
        return password;
      },
      (error, stack) {
        if (error is DbError) return error;
        return DbError.insert(
          'Failed to create password',
          details: error.toString(),
        );
      },
    );
  }

  /// Удаление пароля
  Future<Result<void, DbError>> deletePassword(String id) async {
    return ResultConstructors.tryCatchAsync(
      () async {
        await _dao.deletePassword(id);
      },
      (error, stack) {
        if (error is DbError) return error;
        return DbError.delete(
          'Failed to delete password',
          details: error.toString(),
        );
      },
    );
  }

  /// Пример с восстановлением после ошибки
  Future<Result<Password, DbError>> getPasswordWithFallback(String id) async {
    return getPassword(id).recoverWithAsync((error) async {
      // Попытка получить из кэша или дефолтное значение
      print('⚠️  Recovering from error: ${error.toLogMessage()}');
      return Result.success(
        Password(
          id: 'fallback',
          title: 'Fallback Password',
          username: 'fallback@example.com',
          encryptedPassword: 'encrypted_fallback',
        ),
      );
    });
  }
}

// Пример работы с криптографией
class CryptoService {
  Future<Result<String, CryptoError>> encrypt(
    String plaintext,
    String key,
  ) async {
    return ResultConstructors.tryCatchAsync(
      () async {
        if (key.length < 8) {
          throw CryptoError.invalidKey('Key must be at least 8 characters');
        }

        await Future.delayed(const Duration(milliseconds: 30));
        // Имитация шифрования
        return 'encrypted_$plaintext';
      },
      (error, stack) {
        if (error is CryptoError) return error;
        return CryptoError.encryption('Failed to encrypt data');
      },
    );
  }

  Future<Result<String, CryptoError>> decrypt(
    String ciphertext,
    String key,
  ) async {
    return ResultConstructors.tryCatchAsync(
      () async {
        if (!ciphertext.startsWith('encrypted_')) {
          throw CryptoError.invalidFormat('Invalid ciphertext format');
        }

        await Future.delayed(const Duration(milliseconds: 30));
        return ciphertext.substring('encrypted_'.length);
      },
      (error, stack) {
        if (error is CryptoError) return error;
        return CryptoError.decryption('Failed to decrypt data');
      },
    );
  }
}

// Пример комбинированной операции
class PasswordManager {
  final PasswordsService _passwordsService = PasswordsService();
  final CryptoService _cryptoService = CryptoService();

  /// Создание и шифрование пароля (Railway-oriented)
  Future<Result<Password, AppError>> createEncryptedPassword({
    required String title,
    required String username,
    required String plainPassword,
    required String masterKey,
  }) async {
    // Цепочка операций: шифрование -> создание записи
    return _cryptoService
        .encrypt(plainPassword, masterKey)
        .mapErrorAsync(
          (cryptoError) =>
              AppError.unknown('Encryption failed', cause: cryptoError),
        )
        .flatMapAsync((encrypted) async {
          final createResult = await _passwordsService.createPassword(
            title: title,
            username: username,
            plainPassword: encrypted,
          );
          return createResult.mapError(
            (dbError) =>
                AppError.unknown('Database operation failed', cause: dbError),
          );
        });
  }

  /// Получение и расшифровка пароля
  Future<Result<String, AppError>> getDecryptedPassword(
    String id,
    String masterKey,
  ) async {
    return _passwordsService
        .getPassword(id)
        .mapErrorAsync(
          (dbError) =>
              AppError.unknown('Failed to get password', cause: dbError),
        )
        .flatMapAsync((password) async {
          final decryptResult = await _cryptoService.decrypt(
            password.encryptedPassword,
            masterKey,
          );
          return decryptResult.mapError(
            (cryptoError) =>
                AppError.unknown('Decryption failed', cause: cryptoError),
          );
        });
  }
}

void main() async {
  print('=== Hoplixi Result Pattern Examples ===\n');

  final service = PasswordsService();
  final cryptoService = CryptoService();
  final manager = PasswordManager();

  // Пример 1: Успешное создание пароля
  print('--- Пример 1: Создание пароля ---');
  final createResult = await service.createPassword(
    title: 'Gmail',
    username: 'user@gmail.com',
    plainPassword: 'secret123',
  );

  createResult
      .onSuccess((password) {
        print('✅ Пароль создан: ${password.title}');
        print('   ID: ${password.id}');
      })
      .onFailure((error) {
        print('❌ Ошибка: ${error.toUserMessage()}');
        print('   Лог: ${error.toLogMessage()}');
      });

  // Пример 2: Ошибка not found
  print('\n--- Пример 2: Password not found ---');
  final notFoundResult = await service.getPassword('not-found');
  notFoundResult.when(
    success: (password) => print('✅ Пароль найден: ${password.title}'),
    failure: (error) {
      print('❌ Пользователь видит: ${error.toUserMessage()}');
      print('📝 В логах сохранено: ${error.toLogMessage()}');
    },
  );

  // Пример 3: Валидация
  print('\n--- Пример 3: Валидация ---');
  final validationResult = await service.createPassword(
    title: '', // Пустой title
    username: 'test@test.com',
    plainPassword: 'password',
  );
  validationResult.when(
    success: (_) => print('✅ Создано'),
    failure: (error) => print('❌ ${error.toUserMessage()}'),
  );

  // Пример 3.1: mapAsync с FutureOr (синхронный + асинхронный)
  print('\n--- Пример 3.1: mapAsync с FutureOr ---');

  // Синхронный трансформер - работает без изменений
  final syncMapResult = await service
      .getPassword('test-id')
      .mapAsync((password) => password.title.toUpperCase());

  syncMapResult.when(
    success: (title) => print('✅ Sync transform: $title'),
    failure: (error) => print('❌ ${error.toUserMessage()}'),
  );

  // Асинхронный трансформер - теперь не нужен await внутри!
  final asyncMapResult = await service.getPassword('test-id').mapAsync((
    password,
  ) async {
    await Future.delayed(Duration(milliseconds: 5));
    return '🔄 ${password.title.toUpperCase()}';
  });

  asyncMapResult.when(
    success: (title) => print('✅ Async transform: $title'),
    failure: (error) => print('❌ ${error.toUserMessage()}'),
  );

  // mapErrorAsync тоже поддерживает FutureOr!
  final errorTransformResult = await service
      .getPassword('not-found')
      .mapErrorAsync((dbError) async {
        await Future.delayed(Duration(milliseconds: 5));
        return AppError.notFound(
          'Трансформированная ошибка: ${dbError.message}',
        );
      });

  errorTransformResult.when(
    success: (password) => print('✅ Найден: ${password.title}'),
    failure: (appError) => print('❌ ${appError.toUserMessage()}'),
  );

  // Пример 4: Криптография
  print('\n--- Пример 4: Шифрование ---');
  final encryptResult = await cryptoService.encrypt(
    'secret data',
    'masterkey123',
  );
  final encrypted = encryptResult.getOrElse((error) {
    print('❌ Ошибка шифрования: ${error.toUserMessage()}');
    return 'fallback_encrypted';
  });
  print('✅ Зашифровано: $encrypted');

  final decryptResult = await cryptoService.decrypt(encrypted, 'masterkey123');
  decryptResult.when(
    success: (plain) => print('✅ Расшифровано: $plain'),
    failure: (error) => print('❌ ${error.toUserMessage()}'),
  );

  // Пример 5: Ошибка криптографии
  print('\n--- Пример 5: Неверный ключ ---');
  final weakKeyResult = await cryptoService.encrypt('data', 'weak');
  weakKeyResult.when(
    success: (_) => print('✅ Зашифровано'),
    failure: (error) {
      print('❌ Пользователь видит: ${error.toUserMessage()}');
      print('📝 В логах (без секретов): ${error.toLogMessage()}');
    },
  );

  // Пример 6: Railway-oriented programming
  print('\n--- Пример 6: Railway-oriented ---');
  final combinedResult = await manager.createEncryptedPassword(
    title: 'Bank Account',
    username: 'john@bank.com',
    plainPassword: 'secure_password_123',
    masterKey: 'master_key_strong',
  );

  combinedResult.when(
    success: (password) =>
        print('✅ Пароль создан и зашифрован: ${password.title}'),
    failure: (error) {
      print('❌ Что-то пошло не так: ${error.toUserMessage()}');
      print('📝 Лог: ${error.toLogMessage()}');
    },
  );

  // Пример 7: Восстановление после ошибки
  print('\n--- Пример 7: Recover ---');
  final recoverResult = await service.getPasswordWithFallback('not-found');
  recoverResult.when(
    success: (password) =>
        print('✅ Получен пароль (может быть fallback): ${password.title}'),
    failure: (error) => print('❌ ${error.toUserMessage()}'),
  );

  // Пример 8: Комбинирование результатов
  print('\n--- Пример 8: Комбинирование ---');
  final pass1 = await service.createPassword(
    title: 'Service 1',
    username: 'user1',
    plainPassword: 'pass1',
  );
  final pass2 = await service.createPassword(
    title: 'Service 2',
    username: 'user2',
    plainPassword: 'pass2',
  );

  final combined = ResultConstructors.combine2(pass1, pass2);
  combined.when(
    success: (data) {
      final (password1, password2) = data;
      print('✅ Созданы оба пароля:');
      print('   1. ${password1.title}');
      print('   2. ${password2.title}');
    },
    failure: (error) =>
        print('❌ Хотя бы один не создан: ${error.toUserMessage()}'),
  );

  // Пример 9: Extension для конвертации
  print('\n--- Пример 9: Error conversion ---');
  try {
    throw Exception('Some database error');
  } catch (e) {
    final appError = e.toAppError('Database operation failed');
    print('Converted to AppError: ${appError.toLogMessage()}');

    final dbError = e.toDbError('Query failed');
    print('Converted to DbError: ${dbError.toLogMessage()}');
  }

  // Пример 10: Map цепочка
  print('\n--- Пример 10: Map chain ---');
  final chainResult = await service
      .createPassword(title: 'Test', username: 'test', plainPassword: 'pass')
      .mapAsync((password) => password.title.toUpperCase())
      .mapAsync((title) => 'Processed: $title');

  chainResult.when(
    success: (result) => print('✅ Результат цепочки: $result'),
    failure: (error) => print('❌ ${error.toUserMessage()}'),
  );

  print('\n=== Примеры завершены ===');
}
