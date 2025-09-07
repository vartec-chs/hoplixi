import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/box_db/simple_box.dart';

void main() {
  group('SimpleBox Delete Logic Tests', () {
    late Directory tempDir;
    late SimpleBox<Map<String, dynamic>> box;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('simple_box_test_');
    });

    tearDown(() async {
      try {
        await box.close();
      } catch (_) {}

      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'should remove all records with same ID when one is marked as deleted',
      () async {
        // Создаем коробку
        box = await SimpleBox.open<Map<String, dynamic>>(
          baseDir: tempDir,
          boxName: 'test_box',
          fromMap: (map) => map,
          toMap: (data) => data,
        );

        // Добавляем запись
        await box.put('test_id', {'value': 'first'});

        // Проверяем, что запись существует
        expect(box.containsKey('test_id'), isTrue);
        expect((await box.get('test_id'))!['value'], equals('first'));

        // Обновляем запись (создает новую запись в файле)
        await box.put('test_id', {'value': 'second'});

        // Проверяем обновленную запись
        expect(box.containsKey('test_id'), isTrue);
        expect((await box.get('test_id'))!['value'], equals('second'));

        // Удаляем запись
        final deleted = await box.delete('test_id');
        expect(deleted, isTrue);

        // Проверяем, что запись больше не доступна
        expect(box.containsKey('test_id'), isFalse);
        expect(await box.get('test_id'), isNull);

        // Закрываем и переоткрываем коробку для проверки персистентности
        await box.close();

        box = await SimpleBox.open<Map<String, dynamic>>(
          baseDir: tempDir,
          boxName: 'test_box',
          fromMap: (map) => map,
          toMap: (data) => data,
        );

        // После переоткрытия запись все еще должна быть недоступна
        expect(box.containsKey('test_id'), isFalse);
        expect(await box.get('test_id'), isNull);
      },
    );

    test(
      'should handle complex scenario with multiple updates and deletions',
      () async {
        // Создаем коробку
        box = await SimpleBox.open<Map<String, dynamic>>(
          baseDir: tempDir,
          boxName: 'test_box',
          fromMap: (map) => map,
          toMap: (data) => data,
        );

        // Добавляем несколько записей
        await box.put('id1', {'value': 'first_id1'});
        await box.put('id2', {'value': 'first_id2'});

        // Обновляем записи несколько раз
        await box.put('id1', {'value': 'second_id1'});
        await box.put('id1', {'value': 'third_id1'});
        await box.put('id2', {'value': 'second_id2'});

        // Проверяем, что записи имеют последние значения
        expect((await box.get('id1'))!['value'], equals('third_id1'));
        expect((await box.get('id2'))!['value'], equals('second_id2'));

        // Удаляем одну запись
        await box.delete('id1');

        // Проверяем состояние
        expect(box.containsKey('id1'), isFalse);
        expect(box.containsKey('id2'), isTrue);
        expect(await box.get('id1'), isNull);
        expect((await box.get('id2'))!['value'], equals('second_id2'));

        // Переоткрываем коробку
        await box.close();

        box = await SimpleBox.open<Map<String, dynamic>>(
          baseDir: tempDir,
          boxName: 'test_box',
          fromMap: (map) => map,
          toMap: (data) => data,
        );

        // Проверяем, что состояние сохранилось
        expect(box.containsKey('id1'), isFalse);
        expect(box.containsKey('id2'), isTrue);
        expect(await box.get('id1'), isNull);
        expect((await box.get('id2'))!['value'], equals('second_id2'));
      },
    );

    test('should correctly count deleted records with new logic', () async {
      // Создаем коробку
      box = await SimpleBox.open<Map<String, dynamic>>(
        baseDir: tempDir,
        boxName: 'test_box',
        fromMap: (map) => map,
        toMap: (data) => data,
      );

      // Добавляем записи
      await box.put('id1', {'value': 'data1'});
      await box.put('id2', {'value': 'data2'});

      // Обновляем записи (создает дополнительные записи в файле)
      await box.put('id1', {'value': 'updated_data1'});
      await box.put('id2', {'value': 'updated_data2'});

      // Получаем статистику до удаления
      var stats = await box.getStats();
      expect(stats['activeRecords'], equals(2));

      // Удаляем одну запись
      await box.delete('id1');

      // Получаем статистику после удаления
      stats = await box.getStats();
      expect(stats['activeRecords'], equals(1));
      // При удалении id1 должны быть помечены как удаленные все записи с этим ID
      expect(stats['deletedRecords'], greaterThan(0));
    });

    test('should handle deletion of non-existent record', () async {
      // Создаем коробку
      box = await SimpleBox.open<Map<String, dynamic>>(
        baseDir: tempDir,
        boxName: 'test_box',
        fromMap: (map) => map,
        toMap: (data) => data,
      );

      // Пытаемся удалить несуществующую запись
      final deleted = await box.delete('non_existent_id');
      expect(deleted, isFalse);
    });

    test('should handle double deletion', () async {
      // Создаем коробку
      box = await SimpleBox.open<Map<String, dynamic>>(
        baseDir: tempDir,
        boxName: 'test_box',
        fromMap: (map) => map,
        toMap: (data) => data,
      );

      // Добавляем запись
      await box.put('test_id', {'value': 'data'});

      // Удаляем запись первый раз
      final deleted1 = await box.delete('test_id');
      expect(deleted1, isTrue);

      // Пытаемся удалить ту же запись второй раз
      final deleted2 = await box.delete('test_id');
      expect(deleted2, isFalse);
    });
  });
}
