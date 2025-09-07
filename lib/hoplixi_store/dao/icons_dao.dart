import 'package:drift/drift.dart';
import 'dart:typed_data';
import '../hoplixi_store.dart';
import '../tables/icons.dart';
import '../dto/db_dto.dart';
import '../enums/entity_types.dart';

part 'icons_dao.g.dart';

@DriftAccessor(tables: [Icons])
class IconsDao extends DatabaseAccessor<HoplixiStore> with _$IconsDaoMixin {
  IconsDao(super.db);

  /// Создание новой иконки
  Future<String> createIcon(CreateIconDto dto) async {
    final companion = IconsCompanion(
      name: Value(dto.name),
      type: Value(dto.type),
      data: Value(dto.data),
    );

    await into(
      attachedDatabase.icons,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID из companion
    return companion.id.value;
  }

  /// Обновление иконки
  Future<bool> updateIcon(UpdateIconDto dto) async {
    final companion = IconsCompanion(
      id: Value(dto.id),
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      type: dto.type != null ? Value(dto.type!) : const Value.absent(),
      data: dto.data != null ? Value(dto.data!) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await update(
      attachedDatabase.icons,
    ).replace(companion);
    return rowsAffected;
  }

  /// Удаление иконки по ID
  Future<bool> deleteIcon(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.icons,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение иконки по ID
  Future<IconData?> getIconById(String id) async {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех иконок
  Future<List<IconData>> getAllIcons() async {
    final query = select(attachedDatabase.icons)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Получение иконок по типу
  Future<List<IconData>> getIconsByType(IconType type) async {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.type.equals(type.name))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Получение иконки по имени
  Future<IconData?> getIconByName(String name) async {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.name.equals(name));
    return await query.getSingleOrNull();
  }

  /// Поиск иконок по имени
  Future<List<IconData>> searchIcons(String searchTerm) async {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.name.like('%$searchTerm%'))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Проверка существования иконки с именем
  Future<bool> iconExists(String name, {String? excludeId}) async {
    var query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.name.equals(name));

    if (excludeId != null) {
      query = query..where((tbl) => tbl.id.equals(excludeId).not());
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Получение количества иконок
  Future<int> getIconsCount() async {
    final query = selectOnly(attachedDatabase.icons)
      ..addColumns([attachedDatabase.icons.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.icons.id.count()) ?? 0;
  }

  /// Получение количества иконок по типам
  Future<Map<String, int>> getIconsCountByType() async {
    final query = selectOnly(attachedDatabase.icons)
      ..addColumns([
        attachedDatabase.icons.type,
        attachedDatabase.icons.id.count(),
      ])
      ..groupBy([attachedDatabase.icons.type]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.icons.type)!:
            row.read(attachedDatabase.icons.id.count()) ?? 0,
    };
  }

  /// Получение размера всех иконок в байтах
  Future<int> getTotalIconsSize() async {
    final query = customSelect('''
      SELECT SUM(LENGTH(data)) as total_size 
      FROM icons
    ''');

    final result = await query.getSingle();
    return result.read<int?>('total_size') ?? 0;
  }

  /// Получение иконок с размером больше указанного (в байтах)
  Future<List<IconWithSize>> getIconsLargerThan(int sizeInBytes) async {
    final query = customSelect(
      '''
      SELECT *, LENGTH(data) as size 
      FROM icons 
      WHERE LENGTH(data) > ?
      ORDER BY size DESC
    ''',
      variables: [Variable(sizeInBytes)],
    );

    final results = await query.get();
    return results
        .map(
          (row) => IconWithSize(
            icon: IconData(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              type: IconType.values.firstWhere(
                (e) => e.name == row.read<String>('type'),
              ),
              data: row.read<Uint8List>('data'),
              createdAt: row.read<DateTime>('created_at'),
              modifiedAt: row.read<DateTime>('modified_at'),
            ),
            sizeInBytes: row.read<int>('size'),
          ),
        )
        .toList();
  }

  /// Stream для наблюдения за всеми иконками
  Stream<List<IconData>> watchAllIcons() {
    final query = select(attachedDatabase.icons)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Stream для наблюдения за иконками по типу
  Stream<List<IconData>> watchIconsByType(IconType type) {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.type.equals(type.name))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Batch операции для создания множественных иконок
  Future<void> createIconsBatch(List<CreateIconDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = IconsCompanion(
          name: Value(dto.name),
          type: Value(dto.type),
          data: Value(dto.data),
        );
        batch.insert(attachedDatabase.icons, companion);
      }
    });
  }

  /// Получение иконок с информацией об использовании
  Future<List<IconWithUsage>> getIconsWithUsage() async {
    final query = customSelect('''
      SELECT i.*, COUNT(c.icon_id) as usage_count
      FROM icons i
      LEFT JOIN categories c ON i.id = c.icon_id
      GROUP BY i.id
      ORDER BY usage_count DESC, i.name ASC
    ''');

    final results = await query.get();
    return results
        .map(
          (row) => IconWithUsage(
            icon: IconData(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              type: IconType.values.firstWhere(
                (e) => e.name == row.read<String>('type'),
              ),
              data: row.read<Uint8List>('data'),
              createdAt: row.read<DateTime>('created_at'),
              modifiedAt: row.read<DateTime>('modified_at'),
            ),
            usageCount: row.read<int>('usage_count'),
          ),
        )
        .toList();
  }

  /// Получение неиспользуемых иконок
  Future<List<IconData>> getUnusedIcons() async {
    final query = customSelect('''
      SELECT i.*
      FROM icons i
      LEFT JOIN categories c ON i.id = c.icon_id
      WHERE c.icon_id IS NULL
      ORDER BY i.name
    ''');

    final results = await query.get();
    return results
        .map(
          (row) => IconData(
            id: row.read<String>('id'),
            name: row.read<String>('name'),
            type: IconType.values.firstWhere(
              (e) => e.name == row.read<String>('type'),
            ),
            data: row.read<Uint8List>('data'),
            createdAt: row.read<DateTime>('created_at'),
            modifiedAt: row.read<DateTime>('modified_at'),
          ),
        )
        .toList();
  }

  /// Очистка неиспользуемых иконок
  Future<int> cleanupUnusedIcons() async {
    final result = await customUpdate('''
      DELETE FROM icons 
      WHERE id NOT IN (
        SELECT DISTINCT icon_id 
        FROM categories 
        WHERE icon_id IS NOT NULL
      )
    ''');

    return result;
  }
}

/// Класс для иконки с размером
class IconWithSize {
  final IconData icon;
  final int sizeInBytes;

  IconWithSize({required this.icon, required this.sizeInBytes});
}

/// Класс для иконки с информацией об использовании
class IconWithUsage {
  final IconData icon;
  final int usageCount;

  IconWithUsage({required this.icon, required this.usageCount});
}
