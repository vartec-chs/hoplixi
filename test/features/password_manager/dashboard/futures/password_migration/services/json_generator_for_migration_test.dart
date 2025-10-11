import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:hoplixi/features/password_manager/dashboard/futures/password_migration/services/json_generator_for_migration.dart';

void main() {
  group('JsonGeneratorForMigration', () {
    test('generateAndSave creates JSON file with correct structure', () {
      // Создаем временный файл
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'test_migration.json'));

      // Удаляем файл, если существует
      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }

      // Создаем генератор
      final generator = JsonGeneratorForMigration();

      // Генерируем 3 пароля и 2 категории
      generator.generateAndSave(
        passwordCount: 3,
        categoryCount: 2,
        filePath: tempFile.path,
      );

      // Проверяем, что файл создан
      expect(tempFile.existsSync(), isTrue);

      // Читаем и парсим JSON
      final jsonString = tempFile.readAsStringSync();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Проверяем структуру
      expect(data.containsKey('passwords'), isTrue);
      expect(data.containsKey('categories'), isTrue);
      expect(data['passwords'], isList);
      expect(data['categories'], isList);
      expect(data['passwords'].length, equals(3));
      expect(data['categories'].length, equals(2));

      // Проверяем первый пароль
      final firstPassword = data['passwords'][0] as Map<String, dynamic>;
      expect(firstPassword['name'], equals('Password 1'));
      expect(firstPassword['password'], equals('')); // Пустой пароль
      expect(firstPassword['description'], equals('')); // Пустое описание
      expect(firstPassword['url'], equals('')); // Пустой URL
      expect(firstPassword['login'], equals('')); // Пустой логин
      expect(firstPassword['email'], equals('')); // Пустой email
      expect(firstPassword['notes'], equals('')); // Пустые заметки
      expect(firstPassword['isFavorite'], isFalse);
      expect(
        firstPassword['categoryId'],
        isNotNull,
      ); // Должен быть привязан к категории

      // Проверяем первую категорию
      final firstCategory = data['categories'][0] as Map<String, dynamic>;
      expect(firstCategory['name'], equals('Category 1'));
      expect(firstCategory['color'], equals('FFFFFF'));
      expect(firstCategory['id'], isNotNull); // Должен быть ID

      // Проверяем, что пароли привязаны к существующим категориям
      final categoryIds = (data['categories'] as List)
          .map((c) => (c as Map<String, dynamic>)['id'])
          .toSet();

      for (final password in data['passwords'] as List) {
        final passwordMap = password as Map<String, dynamic>;
        final categoryId = passwordMap['categoryId'];
        if (categoryId != null) {
          expect(
            categoryIds.contains(categoryId),
            isTrue,
            reason: 'Password should be linked to existing category',
          );
        }
      }

      // Проверяем красивое форматирование (должны быть переносы строк и отступы)
      expect(
        jsonString.contains('\n'),
        isTrue,
        reason: 'JSON should be formatted with line breaks',
      );
      expect(
        jsonString.contains('  '),
        isTrue,
        reason: 'JSON should be formatted with indentation',
      );

      // Очищаем
      tempFile.deleteSync();
    });

    test('passwords are distributed evenly across categories', () {
      final tempDir = Directory.systemTemp;
      final tempFile = File(path.join(tempDir.path, 'test_distribution.json'));

      if (tempFile.existsSync()) {
        tempFile.deleteSync();
      }

      final generator = JsonGeneratorForMigration();

      // Генерируем 6 паролей и 3 категории (по 2 пароля на категорию)
      generator.generateAndSave(
        passwordCount: 6,
        categoryCount: 3,
        filePath: tempFile.path,
      );

      final jsonString = tempFile.readAsStringSync();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final passwords = data['passwords'] as List;

      // Подсчитываем сколько паролей привязано к каждой категории
      final categoryPasswordCount = <String, int>{};

      for (final password in passwords) {
        final categoryId = (password as Map<String, dynamic>)['categoryId'];
        if (categoryId != null) {
          categoryPasswordCount[categoryId] =
              (categoryPasswordCount[categoryId] ?? 0) + 1;
        }
      }

      // Каждая категория должна иметь 2 пароля
      expect(categoryPasswordCount.length, equals(3));
      for (final count in categoryPasswordCount.values) {
        expect(count, equals(2));
      }

      tempFile.deleteSync();
    });
  });
}
