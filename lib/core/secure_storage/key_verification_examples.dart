import 'package:hoplixi/core/secure_storage/index.dart';
import 'package:hoplixi/core/flutter_secure_storageo_impl.dart';

/// Примеры использования системы проверки ключей для безопасного хранилища
///
/// Этот файл демонстрирует, как использовать новый функционал проверки
/// правильности ключей шифрования для каждого хранилища.

class KeyVerificationExamples {
  late final EncryptedKeyValueStorage _storage;

  KeyVerificationExamples() {
    final secureStorage = FlutterSecureStorageImpl();
    _storage = EncryptedKeyValueStorage(
      secureStorage: secureStorage,
      appName: 'hoplixi',
      enableCache: true,
    );
  }

  /// Пример 1: Базовое использование с автоматической проверкой ключей
  Future<void> basicUsageExample() async {
    print('=== Пример 1: Базовое использование ===');

    await _storage.initialize();

    // Создаем тестовые данные
    final testData = {'name': 'Test User', 'age': 25};

    try {
      // Записываем данные - ключ автоматически проверяется
      await _storage.write(
        storageKey: 'user_data',
        key: 'user_1',
        data: testData,
        toJson: (data) => data,
      );
      print('✓ Данные успешно записаны');

      // Читаем данные - ключ автоматически проверяется
      final readData = await _storage.read<Map<String, dynamic>>(
        storageKey: 'user_data',
        key: 'user_1',
        fromJson: (json) => json,
      );
      print('✓ Данные успешно прочитаны: $readData');
    } catch (e) {
      print('✗ Ошибка: $e');
    }
  }

  /// Пример 2: Ручная проверка ключа хранилища
  Future<void> manualKeyVerificationExample() async {
    print('\n=== Пример 2: Ручная проверка ключа ===');

    const storageKey = 'sensitive_data';

    try {
      // Проверяем правильность ключа для хранилища
      final isValid = await _storage.verifyStorageKey(storageKey);
      print(
        'Ключ для хранилища "$storageKey" ${isValid ? "правильный" : "неправильный"}',
      );

      // Получаем подробную информацию о статусе верификации
      final status = await _storage.getKeyVerificationStatus(storageKey);
      print('Статус верификации:');
      print('  - Есть подпись: ${status.hasSignature}');
      print('  - Время регистрации: ${status.registrationTime}');
      print('  - Хеш подписи: ${status.signatureHash?.substring(0, 8)}...');
    } catch (e) {
      print('✗ Ошибка при проверке ключа: $e');
    }
  }

  /// Пример 3: Диагностика безопасности всех хранилищ
  Future<void> securityDiagnosticsExample() async {
    print('\n=== Пример 3: Диагностика безопасности ===');

    try {
      // Выполняем полную диагностику безопасности
      final diagnostics = await _storage.performSecurityDiagnostics();

      print('Результаты диагностики:');
      print('  - Всего хранилищ: ${diagnostics.totalStorages}');
      print('  - Правильных ключей: ${diagnostics.validKeys}');
      print('  - Неправильных ключей: ${diagnostics.invalidKeys}');
      print('  - Целых файлов: ${diagnostics.intactFiles}');
      print('  - Поврежденных файлов: ${diagnostics.corruptedFiles}');
      print('  - Найдено проблем: ${diagnostics.issues.length}');

      // Выводим детали проблем
      for (final issue in diagnostics.issues) {
        print(
          '  🚨 ${issue.severity.name.toUpperCase()}: ${issue.description}',
        );
      }

      if (diagnostics.issues.isEmpty) {
        print('✓ Проблем безопасности не обнаружено');
      }
    } catch (e) {
      print('✗ Ошибка при диагностике: $e');
    }
  }

  /// Пример 4: Проверка всех ключей хранилищ
  Future<void> verifyAllKeysExample() async {
    print('\n=== Пример 4: Проверка всех ключей ===');

    try {
      // Получаем список всех зарегистрированных хранилищ
      final storages = await _storage.getRegisteredStorages();
      print('Зарегистрированных хранилищ: ${storages.length}');

      // Проверяем ключи для всех хранилищ
      final results = await _storage.verifyAllStorageKeys();

      for (final entry in results.entries) {
        final status = entry.value ? '✓' : '✗';
        print('  $status ${entry.key}: ${entry.value ? "ОК" : "ОШИБКА"}');
      }
    } catch (e) {
      print('✗ Ошибка при проверке ключей: $e');
    }
  }

  /// Пример 5: Восстановление поврежденного ключа
  Future<void> keyRecoveryExample() async {
    print('\n=== Пример 5: Восстановление ключа ===');

    const storageKey = 'recovery_test';

    try {
      // Сначала создаем тестовое хранилище
      await _storage.write(
        storageKey: storageKey,
        key: 'test_key',
        data: {'test': 'data'},
        toJson: (data) => data,
      );

      // Проверяем текущий статус
      bool isValid = await _storage.verifyStorageKey(storageKey);
      print('Статус ключа до восстановления: ${isValid ? "OK" : "ОШИБКА"}');

      // Если ключ поврежден, можно попробовать его перерегистрировать
      // ВНИМАНИЕ: Это следует делать только если вы уверены, что ключ правильный!
      if (!isValid) {
        print('Попытка восстановления ключа...');
        await _storage.reregisterStorageKey(storageKey);

        // Проверяем статус после восстановления
        isValid = await _storage.verifyStorageKey(storageKey);
        print(
          'Статус ключа после восстановления: ${isValid ? "OK" : "ОШИБКА"}',
        );
      }
    } catch (e) {
      print('✗ Ошибка при восстановлении ключа: $e');
    }
  }

  /// Пример 6: Обработка ошибок проверки ключей
  Future<void> errorHandlingExample() async {
    print('\n=== Пример 6: Обработка ошибок ===');

    const storageKey = 'error_test';

    try {
      // Попытка чтения из несуществующего хранилища
      final data = await _storage.read<Map<String, dynamic>>(
        storageKey: storageKey,
        key: 'nonexistent_key',
        fromJson: (json) => json,
      );
      print('Данные: $data');
    } on ValidationException catch (e) {
      print('🔒 Ошибка валидации ключа: ${e.message}');
      print('Возможные причины:');
      print('  - Ключ был поврежден');
      print('  - Используется неправильный ключ');
      print('  - Произошла атака на систему');
    } on EncryptionException catch (e) {
      print('🔐 Ошибка шифрования: ${e.message}');
    } on SecureStorageException catch (e) {
      print('💾 Ошибка хранилища: ${e.message}');
    } catch (e) {
      print('❌ Неожиданная ошибка: $e');
    }
  }

  /// Пример 7: Мониторинг изменений ключей
  Future<void> keyMonitoringExample() async {
    print('\n=== Пример 7: Мониторинг ключей ===');

    try {
      // Получаем базовый снимок состояния
      final initialDiagnostics = await _storage.performSecurityDiagnostics();
      print('Базовое состояние зафиксировано');

      // Создаем несколько тестовых хранилищ
      for (int i = 1; i <= 3; i++) {
        await _storage.write(
          storageKey: 'monitor_test_$i',
          key: 'data',
          data: {'index': i, 'timestamp': DateTime.now().toIso8601String()},
          toJson: (data) => data,
        );
      }

      // Получаем новый снимок состояния
      final newDiagnostics = await _storage.performSecurityDiagnostics();

      print('Изменения:');
      print('  Хранилищ было: ${initialDiagnostics.totalStorages}');
      print('  Хранилищ стало: ${newDiagnostics.totalStorages}');
      print(
        '  Добавлено: ${newDiagnostics.totalStorages - initialDiagnostics.totalStorages}',
      );

      // Проверяем целостность новых ключей
      final keyResults = await _storage.verifyAllStorageKeys();
      final validKeys = keyResults.values.where((v) => v).length;
      print(
        '  Все ключи валидны: ${validKeys == keyResults.length ? "ДА" : "НЕТ"}',
      );
    } catch (e) {
      print('✗ Ошибка мониторинга: $e');
    }
  }

  /// Запуск всех примеров
  Future<void> runAllExamples() async {
    print('🔐 ДЕМОНСТРАЦИЯ СИСТЕМЫ ПРОВЕРКИ КЛЮЧЕЙ ХРАНИЛИЩА 🔐\n');

    await basicUsageExample();
    await manualKeyVerificationExample();
    await securityDiagnosticsExample();
    await verifyAllKeysExample();
    await keyRecoveryExample();
    await errorHandlingExample();
    await keyMonitoringExample();

    print('\n✅ Все примеры выполнены');
  }
}

/// Пример интеграции в приложение
class SecureStorageManager {
  late final EncryptedKeyValueStorage _storage;

  SecureStorageManager({required FlutterSecureStorageImpl secureStorage}) {
    _storage = EncryptedKeyValueStorage(
      secureStorage: secureStorage,
      appName: 'hoplixi',
      enableCache: true,
    );
  }

  /// Инициализация с проверкой безопасности
  Future<void> initialize() async {
    await _storage.initialize();

    // Выполняем диагностику безопасности при запуске
    final diagnostics = await _storage.performSecurityDiagnostics();

    if (diagnostics.issues.isNotEmpty) {
      final criticalIssues = diagnostics.issues
          .where((issue) => issue.severity == SecurityIssueSeverity.critical)
          .toList();

      if (criticalIssues.isNotEmpty) {
        throw SecurityException(
          'Critical security issues detected: ${criticalIssues.length} issues found. '
          'Application cannot start safely.',
        );
      }
    }
  }

  /// Безопасное сохранение данных с проверкой ключа
  Future<void> saveData<T>({
    required String storageKey,
    required String key,
    required T data,
    required Map<String, dynamic> Function(T) toJson,
  }) async {
    // Проверяем ключ перед сохранением
    final isValidKey = await _storage.verifyStorageKey(storageKey);
    if (!isValidKey) {
      final status = await _storage.getKeyVerificationStatus(storageKey);
      if (!status.hasSignature) {
        // Новое хранилище - это нормально
        print('Info: Creating new storage: $storageKey');
      } else {
        throw SecurityException(
          'Storage key verification failed for: $storageKey. '
          'Data cannot be saved safely.',
        );
      }
    }

    await _storage.write(
      storageKey: storageKey,
      key: key,
      data: data,
      toJson: toJson,
    );
  }

  /// Безопасное чтение данных с проверкой ключа
  Future<T?> loadData<T>({
    required String storageKey,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    // Проверяем ключ перед чтением
    final isValidKey = await _storage.verifyStorageKey(storageKey);
    if (!isValidKey) {
      throw SecurityException(
        'Storage key verification failed for: $storageKey. '
        'Data cannot be read safely.',
      );
    }

    return await _storage.read<T>(
      storageKey: storageKey,
      key: key,
      fromJson: fromJson,
    );
  }

  /// Получение отчета о безопасности
  Future<SecurityDiagnostics> getSecurityReport() async {
    return await _storage.performSecurityDiagnostics();
  }

  /// Очистка ресурсов
  void dispose() {
    _storage.dispose();
  }
}

/// Исключение безопасности
class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
