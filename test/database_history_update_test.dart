import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/hoplixi_store/services/database_history_service.dart';

void main() {
  group('DatabaseHistoryService - Password Update Tests', () {
    late DatabaseHistoryService service;

    setUp(() {
      service = DatabaseHistoryService();
    });

    tearDown(() async {
      try {
        await service.dispose();
      } catch (e) {
        // Ignore disposal errors in tests
      }
    });

    test(
      'должен обновлять пароль в существующей записи без изменения createdAt',
      () async {
        // Arrange
        const testPath = '/test/database.hpx';
        const testName = 'Test Database';
        const password1 = 'password123';
        const password2 = 'newpassword456';

        // Act & Assert - Создаем первую запись
        await service.recordDatabaseAccess(
          path: testPath,
          name: testName,
          masterPassword: password1,
          saveMasterPassword: true,
        );

        // Получаем первую запись
        final entry1 = await service.getEntryByPath(testPath);
        expect(entry1, isNotNull);
        expect(entry1!.masterPassword, equals(password1));
        expect(entry1.saveMasterPassword, isTrue);

        final originalCreatedAt = entry1.createdAt;
        expect(originalCreatedAt, isNotNull);

        // Ждем немного, чтобы убедиться, что время изменилось
        await Future.delayed(const Duration(milliseconds: 100));

        // Обновляем пароль
        await service.recordDatabaseAccess(
          path: testPath,
          name: testName,
          masterPassword: password2,
          saveMasterPassword: true,
        );

        // Получаем обновленную запись
        final entry2 = await service.getEntryByPath(testPath);
        expect(entry2, isNotNull);
        expect(entry2!.masterPassword, equals(password2));
        expect(entry2.saveMasterPassword, isTrue);

        // Дата создания должна остаться прежней
        expect(entry2.createdAt, equals(originalCreatedAt));

        // lastAccessed должна обновиться
        expect(entry2.lastAccessed, isNot(equals(entry1.lastAccessed)));
        expect(entry2.lastAccessed!.isAfter(entry1.lastAccessed!), isTrue);
      },
    );

    test(
      'должен создавать новую запись с новой createdAt для нового пути',
      () async {
        // Arrange
        const testPath1 = '/test/database1.hpx';
        const testPath2 = '/test/database2.hpx';
        const testName = 'Test Database';
        const password = 'password123';

        // Act - Создаем две записи с разными путями
        await service.recordDatabaseAccess(
          path: testPath1,
          name: testName,
          masterPassword: password,
          saveMasterPassword: true,
        );

        await Future.delayed(const Duration(milliseconds: 100));

        await service.recordDatabaseAccess(
          path: testPath2,
          name: testName,
          masterPassword: password,
          saveMasterPassword: true,
        );

        // Assert
        final entry1 = await service.getEntryByPath(testPath1);
        final entry2 = await service.getEntryByPath(testPath2);

        expect(entry1, isNotNull);
        expect(entry2, isNotNull);

        // Обе записи должны иметь разные даты создания
        expect(entry1!.createdAt, isNot(equals(entry2!.createdAt)));
        expect(entry2.createdAt!.isAfter(entry1.createdAt!), isTrue);
      },
    );

    test('должен правильно обновлять saveMasterPassword флаг', () async {
      // Arrange
      const testPath = '/test/database.hpx';
      const testName = 'Test Database';
      const password = 'password123';

      // Act & Assert - Создаем запись без сохранения пароля
      await service.recordDatabaseAccess(
        path: testPath,
        name: testName,
        masterPassword: password,
        saveMasterPassword: false,
      );

      final entry1 = await service.getEntryByPath(testPath);
      expect(entry1, isNotNull);
      expect(entry1!.masterPassword, isNull);
      expect(entry1.saveMasterPassword, isFalse);

      final originalCreatedAt = entry1.createdAt;

      await Future.delayed(const Duration(milliseconds: 100));

      // Обновляем запись с сохранением пароля
      await service.recordDatabaseAccess(
        path: testPath,
        name: testName,
        masterPassword: password,
        saveMasterPassword: true,
      );

      final entry2 = await service.getEntryByPath(testPath);
      expect(entry2, isNotNull);
      expect(entry2!.masterPassword, equals(password));
      expect(entry2.saveMasterPassword, isTrue);

      // Дата создания должна остаться прежней
      expect(entry2.createdAt, equals(originalCreatedAt));
    });
  });
}
