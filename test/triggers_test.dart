import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:drift/native.dart';

void main() {
  group('SQL Триггеры', () {
    late HoplixiStore database;

    setUp(() async {
      // Создаем в памяти базу данных для тестов
      database = HoplixiStore(NativeDatabase.memory());

      // Ждем инициализации (включая создание триггеров)
      await database.customStatement('SELECT 1');
    });

    tearDown(() async {
      await database.close();
    });

    test('Проверка установки всех триггеров', () async {
      // Проверяем, что триггеры установлены
      final areInstalled = await database.verifyTriggers();
      expect(areInstalled, isTrue);

      // Получаем список триггеров
      final triggers = await database.getInstalledTriggers();
      expect(triggers.isNotEmpty, isTrue);

      // Проверяем наличие ключевых триггеров
      final triggerNames = triggers.join(' ');
      expect(triggerNames.contains('update_passwords_modified_at'), isTrue);
      expect(triggerNames.contains('password_update_history'), isTrue);
      expect(triggerNames.contains('password_delete_history'), isTrue);

      print('Установленные триггеры: ${triggers.length}');
      print('Триггеры: ${triggers.join(', ')}');
    });

    test(
      'Триггер modified_at автоматически обновляется при UPDATE через SQL',
      () async {
        // Создаем категорию через SQL
        await database.customStatement('''
        INSERT INTO categories (id, name, type, created_at, modified_at) 
        VALUES ('test-category', 'Test Category', 'password', ${DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60}, ${DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60})
      ''');

        // Получаем исходное время
        final originalResult = await database.customSelect('''
        SELECT created_at, modified_at FROM categories WHERE id = 'test-category'
      ''').getSingle();

        final originalModified = originalResult.data['modified_at'];

        // Ждем немного
        await Future.delayed(const Duration(milliseconds: 100));

        // Обновляем через SQL
        await database.customStatement('''
        UPDATE categories SET name = 'Updated Category' WHERE id = 'test-category'
      ''');

        // Проверяем, что modified_at обновился
        final updatedResult = await database.customSelect('''
        SELECT created_at, modified_at FROM categories WHERE id = 'test-category'
      ''').getSingle();

        final updatedModified = updatedResult.data['modified_at'];

        expect(
          updatedModified != originalModified,
          isTrue,
          reason: 'modified_at должно автоматически обновиться триггером',
        );
      },
    );

    test(
      'Триггер истории записывает изменения при UPDATE пароля через SQL',
      () async {
        // Создаем пароль через SQL
        await database.customStatement('''
        INSERT INTO passwords (id, name, password, login, created_at, modified_at) 
        VALUES ('test-password', 'Test Password', 'encrypted_pass', 'test_user', ${DateTime.now().millisecondsSinceEpoch ~/ 1000}, ${DateTime.now().millisecondsSinceEpoch ~/ 1000})
      ''');

        // Проверяем, что истории нет
        final historyBeforeResult = await database.customSelect('''
        SELECT COUNT(*) as count FROM password_histories WHERE original_password_id = 'test-password'
      ''').getSingle();

        expect(historyBeforeResult.data['count'] as int, equals(0));

        // Обновляем пароль
        await database.customStatement('''
        UPDATE passwords SET name = 'Updated Password', password = 'new_encrypted_pass' WHERE id = 'test-password'
      ''');

        // Проверяем, что создалась запись в истории
        final historyAfterResult = await database.customSelect('''
        SELECT COUNT(*) as count FROM password_histories WHERE original_password_id = 'test-password' AND action = 'modified'
      ''').getSingle();

        expect(
          historyAfterResult.data['count'] as int,
          equals(1),
          reason: 'Триггер должен создать запись в истории при изменении',
        );

        // Проверяем содержимое записи истории
        final historyContent = await database.customSelect('''
        SELECT action, name, password FROM password_histories WHERE original_password_id = 'test-password'
      ''').getSingle();

        expect(historyContent.data['action'], equals('modified'));
        expect(
          historyContent.data['name'],
          equals('Test Password'),
        ); // Старое значение
        expect(
          historyContent.data['password'],
          equals('encrypted_pass'),
        ); // Старое значение
      },
    );

    test('Триггер истории записывает удаление пароля через SQL', () async {
      // Создаем пароль через SQL
      await database.customStatement('''
        INSERT INTO passwords (id, name, password, login, created_at, modified_at) 
        VALUES ('test-password-delete', 'Password To Delete', 'pass_to_delete', 'user_delete', ${DateTime.now().millisecondsSinceEpoch ~/ 1000}, ${DateTime.now().millisecondsSinceEpoch ~/ 1000})
      ''');

      // Удаляем пароль
      await database.customStatement('''
        DELETE FROM passwords WHERE id = 'test-password-delete'
      ''');

      // Проверяем, что создалась запись в истории
      final historyResult = await database.customSelect('''
        SELECT COUNT(*) as count FROM password_histories WHERE original_password_id = 'test-password-delete' AND action = 'deleted'
      ''').getSingle();

      expect(
        historyResult.data['count'] as int,
        equals(1),
        reason: 'Триггер должен создать запись в истории при удалении',
      );

      // Проверяем содержимое записи истории
      final historyContent = await database.customSelect('''
        SELECT action, name, password FROM password_histories WHERE original_password_id = 'test-password-delete'
      ''').getSingle();

      expect(historyContent.data['action'], equals('deleted'));
      expect(historyContent.data['name'], equals('Password To Delete'));
      expect(historyContent.data['password'], equals('pass_to_delete'));
    });

    test('Статистика истории', () async {
      // Создаем несколько паролей и изменяем их
      for (int i = 0; i < 3; i++) {
        await database.customStatement('''
          INSERT INTO passwords (id, name, password, login, created_at, modified_at) 
          VALUES ('test-pass-$i', 'Password $i', 'pass_$i', 'user_$i', ${DateTime.now().millisecondsSinceEpoch ~/ 1000}, ${DateTime.now().millisecondsSinceEpoch ~/ 1000})
        ''');

        // Обновляем для создания записи в истории
        await database.customStatement('''
          UPDATE passwords SET name = 'Updated Password $i' WHERE id = 'test-pass-$i'
        ''');
      }

      // Получаем статистику
      final stats = await database.getHistoryStatistics();
      expect(stats['password_history']! >= 3, isTrue);

      print('Статистика истории: $stats');
    });

    test('Пересоздание триггеров', () async {
      // Проверяем, что триггеры установлены
      expect(await database.verifyTriggers(), isTrue);

      // Пересоздаем триггеры
      await database.recreateTriggers();

      // Проверяем, что триггеры все еще работают
      expect(await database.verifyTriggers(), isTrue);
    });

    test('Простой тест UUID генерации в SQL', () async {
      // Проверим, что наша UUID генерация в SQL работает
      final result = await database.customSelect('''
        SELECT 
          lower(hex(randomblob(4))) || '-' || 
          lower(hex(randomblob(2))) || '-4' || 
          substr(lower(hex(randomblob(2))),2) || '-' || 
          substr('ab89',abs(random()) % 4 + 1, 1) || 
          substr(lower(hex(randomblob(2))),2) || '-' || 
          lower(hex(randomblob(6))) as uuid
      ''').getSingle();

      final uuid = result.data['uuid'] as String;

      // Проверяем формат UUID v4
      expect(uuid.length, equals(36));
      expect(uuid.contains('-'), isTrue);
      expect(uuid.split('-').length, equals(5));

      print('Сгенерированный UUID: $uuid');
    });
  });
}
