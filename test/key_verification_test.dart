import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/core/secure_storage/index.dart';
import 'package:hoplixi/core/flutter_secure_storageo_impl.dart';

/// Простые тесты для системы проверки ключей
///
/// Эти тесты демонстрируют базовую функциональность
/// системы проверки ключей и могут быть использованы
/// для проверки работоспособности после изменений.

// Мок реализация SecureStorage для тестов
class MockSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(_storage);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }
}

void main() {
  group('KeyVerificationService Tests', () {
    late MockSecureStorage mockSecureStorage;
    late KeyVerificationService keyVerification;

    setUp(() {
      mockSecureStorage = MockSecureStorage();
      keyVerification = KeyVerificationService(
        secureStorage: mockSecureStorage,
      );
    });

    test('Регистрация и проверка ключа напрямую', () async {
      const storageKey = 'direct_test';

      // Создаем тестовый ключ (32 байта для AES-256)
      final testKey = List.generate(32, (i) => i);
      final keyBytes = Uint8List.fromList(testKey);

      // Регистрируем ключ
      await keyVerification.registerEncryptionKey(storageKey, keyBytes);

      // Проверяем ключ
      final isValid = await keyVerification.verifyEncryptionKey(
        storageKey,
        keyBytes,
      );
      expect(
        isValid,
        isTrue,
        reason: 'Зарегистрированный ключ должен быть правильным',
      );

      // Проверяем с неправильным ключом
      final wrongKey = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final isValidWrong = await keyVerification.verifyEncryptionKey(
        storageKey,
        wrongKey,
      );
      expect(
        isValidWrong,
        isFalse,
        reason: 'Неправильный ключ должен быть отклонен',
      );
    });

    test('Получение статуса верификации', () async {
      const storageKey = 'status_test';
      final keyBytes = Uint8List.fromList(List.generate(32, (i) => i));

      // Проверяем статус до регистрации
      var status = await keyVerification.getVerificationStatus(storageKey);
      expect(
        status.hasSignature,
        isFalse,
        reason: 'Подписи не должно быть до регистрации',
      );
      expect(
        status.registrationTime,
        isNull,
        reason: 'Времени регистрации не должно быть',
      );

      // Регистрируем ключ
      await keyVerification.registerEncryptionKey(storageKey, keyBytes);

      // Проверяем статус после регистрации
      status = await keyVerification.getVerificationStatus(storageKey);
      expect(
        status.hasSignature,
        isTrue,
        reason: 'Подпись должна появиться после регистрации',
      );
      expect(
        status.registrationTime,
        isNotNull,
        reason: 'Время регистрации должно быть установлено',
      );
      expect(
        status.signatureHash,
        isNotNull,
        reason: 'Хеш подписи должен быть установлен',
      );
    });

    test('Получение списка зарегистрированных хранилищ', () async {
      // Изначально список пуст
      var storages = await keyVerification.getRegisteredStorages();
      expect(
        storages,
        isEmpty,
        reason: 'Изначально нет зарегистрированных хранилищ',
      );

      // Регистрируем несколько ключей
      final testKeys = ['storage1', 'storage2', 'storage3'];
      for (int i = 0; i < testKeys.length; i++) {
        final storageKey = testKeys[i];
        final keyBytes = Uint8List.fromList(
          List.generate(32, (j) => i * 32 + j),
        );
        await keyVerification.registerEncryptionKey(storageKey, keyBytes);
      }

      // Проверяем список
      storages = await keyVerification.getRegisteredStorages();
      expect(
        storages.length,
        equals(3),
        reason: 'Должно быть 3 зарегистрированных хранилища',
      );

      for (final storageKey in testKeys) {
        expect(
          storages,
          contains(storageKey),
          reason: 'Хранилище $storageKey должно быть в списке',
        );
      }
    });

    test('Удаление подписи ключа', () async {
      const storageKey = 'delete_test';
      final keyBytes = Uint8List.fromList(List.generate(32, (i) => i));

      // Регистрируем ключ
      await keyVerification.registerEncryptionKey(storageKey, keyBytes);

      // Проверяем, что ключ зарегистрирован
      var status = await keyVerification.getVerificationStatus(storageKey);
      expect(
        status.hasSignature,
        isTrue,
        reason: 'Ключ должен быть зарегистрирован',
      );

      // Удаляем подпись
      await keyVerification.removeKeySignature(storageKey);

      // Проверяем, что подпись удалена
      status = await keyVerification.getVerificationStatus(storageKey);
      expect(
        status.hasSignature,
        isFalse,
        reason: 'Подпись должна быть удалена',
      );

      // Проверяем, что хранилище больше не в списке
      final storages = await keyVerification.getRegisteredStorages();
      expect(
        storages,
        isNot(contains(storageKey)),
        reason: 'Хранилище не должно быть в списке после удаления',
      );
    });

    test('Проверка целостности подписей', () async {
      // Регистрируем несколько ключей
      final testKeys = ['integrity1', 'integrity2', 'integrity3'];
      for (int i = 0; i < testKeys.length; i++) {
        final storageKey = testKeys[i];
        final keyBytes = Uint8List.fromList(
          List.generate(32, (j) => i * 10 + j),
        );
        await keyVerification.registerEncryptionKey(storageKey, keyBytes);
      }

      // Проверяем целостность всех подписей
      final results = await keyVerification.verifyAllSignatures();

      expect(
        results.length,
        equals(3),
        reason: 'Должно быть 3 результата проверки',
      );
      for (final entry in results.entries) {
        expect(
          entry.value,
          isTrue,
          reason: 'Подпись ${entry.key} должна быть целой',
        );
      }
    });

    test('Повторная регистрация того же ключа', () async {
      const storageKey = 'same_key_test';
      final keyBytes = Uint8List.fromList(List.generate(32, (i) => i));

      // Первая регистрация
      await keyVerification.registerEncryptionKey(storageKey, keyBytes);

      // Получаем первоначальный статус
      final firstStatus = await keyVerification.getVerificationStatus(
        storageKey,
      );
      expect(firstStatus.hasSignature, isTrue);

      // Повторная регистрация того же ключа должна пройти успешно
      await keyVerification.registerEncryptionKey(storageKey, keyBytes);

      // Статус должен остаться валидным
      final secondStatus = await keyVerification.getVerificationStatus(
        storageKey,
      );
      expect(secondStatus.hasSignature, isTrue);

      // Ключ должен по-прежнему проходить проверку
      final isValid = await keyVerification.verifyEncryptionKey(
        storageKey,
        keyBytes,
      );
      expect(isValid, isTrue, reason: 'Ключ должен остаться валидным');
    });

    test('Попытка регистрации неправильного ключа', () async {
      const storageKey = 'wrong_key_test';
      final keyBytes1 = Uint8List.fromList(List.generate(32, (i) => i));
      final keyBytes2 = Uint8List.fromList(List.generate(32, (i) => i + 1));

      // Регистрируем первый ключ
      await keyVerification.registerEncryptionKey(storageKey, keyBytes1);

      // Проверяем, что первый ключ работает
      var isValid = await keyVerification.verifyEncryptionKey(
        storageKey,
        keyBytes1,
      );
      expect(isValid, isTrue, reason: 'Первый ключ должен быть валидным');

      // Попытка зарегистрировать другой ключ для того же хранилища должна вызвать ошибку
      expect(
        () => keyVerification.registerEncryptionKey(storageKey, keyBytes2),
        throwsA(isA<ValidationException>()),
        reason:
            'Должна быть выброшена ошибка валидации при попытке зарегистрировать неправильный ключ',
      );
    });

    test('Очистка всех данных верификации', () async {
      // Регистрируем несколько ключей
      final testKeys = ['clear1', 'clear2'];
      for (int i = 0; i < testKeys.length; i++) {
        final storageKey = testKeys[i];
        final keyBytes = Uint8List.fromList(
          List.generate(32, (j) => i * 5 + j),
        );
        await keyVerification.registerEncryptionKey(storageKey, keyBytes);
      }

      // Проверяем, что ключи зарегистрированы
      var storages = await keyVerification.getRegisteredStorages();
      expect(
        storages.length,
        equals(2),
        reason: 'Должно быть 2 зарегистрированных хранилища',
      );

      // Очищаем все данные
      await keyVerification.clearAllVerificationData();

      // Проверяем, что все данные удалены
      storages = await keyVerification.getRegisteredStorages();
      expect(
        storages,
        isEmpty,
        reason: 'После очистки не должно быть зарегистрированных хранилищ',
      );
    });
  });
}
