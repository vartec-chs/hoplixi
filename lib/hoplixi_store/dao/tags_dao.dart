import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/tags.dart';
import '../dto/db_dto.dart';
import '../enums/entity_types.dart';

part 'tags_dao.g.dart';

@DriftAccessor(tables: [Tags])
class TagsDao extends DatabaseAccessor<HoplixiStore> with _$TagsDaoMixin {
  TagsDao(HoplixiStore db) : super(db);

  /// Создание нового тега
  Future<String> createTag(CreateTagDto dto) async {
    final companion = TagsCompanion(
      name: Value(dto.name),
      color: Value(dto.color),
      type: Value(dto.type),
    );

    await into(
      attachedDatabase.tags,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID из companion
    return companion.id.value;
  }

  /// Обновление тега
  Future<bool> updateTag(UpdateTagDto dto) async {
    final companion = TagsCompanion(
      id: Value(dto.id),
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      color: dto.color != null ? Value(dto.color) : const Value.absent(),
      type: dto.type != null ? Value(dto.type!) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await update(attachedDatabase.tags).replace(companion);
    return rowsAffected;
  }

  /// Удаление тега по ID
  Future<bool> deleteTag(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.tags,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение тега по ID
  Future<Tag?> getTagById(String id) async {
    final query = select(attachedDatabase.tags)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех тегов
  Future<List<Tag>> getAllTags() async {
    final query = select(attachedDatabase.tags)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Получение тегов по типу
  Future<List<Tag>> getTagsByType(TagType type) async {
    final query = select(attachedDatabase.tags)
      ..where((tbl) => tbl.type.equals(type.name) | tbl.type.equals('mixed'))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Получение тега по имени
  Future<Tag?> getTagByName(String name) async {
    final query = select(attachedDatabase.tags)
      ..where((tbl) => tbl.name.equals(name));
    return await query.getSingleOrNull();
  }

  /// Поиск тегов по имени
  Future<List<Tag>> searchTags(String searchTerm) async {
    final query = select(attachedDatabase.tags)
      ..where((tbl) => tbl.name.like('%$searchTerm%'))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Проверка существования тега с именем
  Future<bool> tagExists(String name, {String? excludeId}) async {
    var query = select(attachedDatabase.tags)
      ..where((tbl) => tbl.name.equals(name));

    if (excludeId != null) {
      query = query..where((tbl) => tbl.id.equals(excludeId).not());
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Получение количества тегов
  Future<int> getTagsCount() async {
    final query = selectOnly(attachedDatabase.tags)
      ..addColumns([attachedDatabase.tags.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.tags.id.count()) ?? 0;
  }

  /// Получение количества тегов по типам
  Future<Map<String, int>> getTagsCountByType() async {
    final query = selectOnly(attachedDatabase.tags)
      ..addColumns([
        attachedDatabase.tags.type,
        attachedDatabase.tags.id.count(),
      ])
      ..groupBy([attachedDatabase.tags.type]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.tags.type)!:
            row.read(attachedDatabase.tags.id.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за всеми тегами
  Stream<List<Tag>> watchAllTags() {
    final query = select(attachedDatabase.tags)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Stream для наблюдения за тегами по типу
  Stream<List<Tag>> watchTagsByType(TagType type) {
    final query = select(attachedDatabase.tags)
      ..where((tbl) => tbl.type.equals(type.name) | tbl.type.equals('mixed'))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Batch операции для создания множественных тегов
  Future<void> createTagsBatch(List<CreateTagDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = TagsCompanion(
          name: Value(dto.name),
          color: Value(dto.color),
          type: Value(dto.type),
        );
        batch.insert(attachedDatabase.tags, companion);
      }
    });
  }

  /// Получение тегов с подсчетом использования
  Future<List<TagWithUsageCount>> getTagsWithUsageCount(TagType type) async {
    // Этот метод требует кастомного запроса для подсчета использования тегов

    String joinTable;
    switch (type) {
      case TagType.password:
        joinTable = 'password_tags';
        break;
      case TagType.notes:
        joinTable = 'note_tags';
        break;
      case TagType.totp:
        joinTable = 'totp_tags';
        break;
      case TagType.mixed:
        // Для mixed нужен более сложный запрос
        return await _getTagsWithMixedUsageCount();
    }

    final query = customSelect(
      '''
      SELECT t.*, COALESCE(COUNT(ut.tag_id), 0) as usage_count 
      FROM tags t 
      LEFT JOIN $joinTable ut ON t.id = ut.tag_id 
      WHERE t.type = ? OR t.type = 'mixed'
      GROUP BY t.id 
      ORDER BY t.name
    ''',
      variables: [Variable(type.name)],
    );

    final results = await query.get();
    return results
        .map(
          (row) => TagWithUsageCount(
            tag: Tag(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              color: row.read<String?>('color'),
              type: TagType.values.firstWhere(
                (e) => e.name == row.read<String>('type'),
              ),
              createdAt: row.read<DateTime>('created_at'),
              modifiedAt: row.read<DateTime>('modified_at'),
            ),
            usageCount: row.read<int>('usage_count'),
          ),
        )
        .toList();
  }

  /// Получение mixed тегов с подсчетом использования во всех типах
  Future<List<TagWithUsageCount>> _getTagsWithMixedUsageCount() async {
    final query = customSelect('''
      SELECT t.*, 
             COALESCE(p.count, 0) + COALESCE(n.count, 0) + COALESCE(o.count, 0) as usage_count
      FROM tags t 
      LEFT JOIN (SELECT tag_id, COUNT(*) as count FROM password_tags GROUP BY tag_id) p ON t.id = p.tag_id
      LEFT JOIN (SELECT tag_id, COUNT(*) as count FROM note_tags GROUP BY tag_id) n ON t.id = n.tag_id
      LEFT JOIN (SELECT tag_id, COUNT(*) as count FROM totp_tags GROUP BY tag_id) o ON t.id = o.tag_id
      WHERE t.type = 'mixed'
      ORDER BY t.name
    ''');

    final results = await query.get();
    return results
        .map(
          (row) => TagWithUsageCount(
            tag: Tag(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              color: row.read<String?>('color'),
              type: TagType.mixed,
              createdAt: row.read<DateTime>('created_at'),
              modifiedAt: row.read<DateTime>('modified_at'),
            ),
            usageCount: row.read<int>('usage_count'),
          ),
        )
        .toList();
  }

  /// Получение популярных тегов (наиболее используемых)
  Future<List<TagWithUsageCount>> getPopularTags({int limit = 10}) async {
    final query = customSelect(
      '''
      SELECT t.*, 
             COALESCE(p.count, 0) + COALESCE(n.count, 0) + COALESCE(o.count, 0) as usage_count
      FROM tags t 
      LEFT JOIN (SELECT tag_id, COUNT(*) as count FROM password_tags GROUP BY tag_id) p ON t.id = p.tag_id
      LEFT JOIN (SELECT tag_id, COUNT(*) as count FROM note_tags GROUP BY tag_id) n ON t.id = n.tag_id
      LEFT JOIN (SELECT tag_id, COUNT(*) as count FROM totp_tags GROUP BY tag_id) o ON t.id = o.tag_id
      ORDER BY usage_count DESC, t.name ASC
      LIMIT ?
    ''',
      variables: [Variable(limit)],
    );

    final results = await query.get();
    return results
        .map(
          (row) => TagWithUsageCount(
            tag: Tag(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              color: row.read<String?>('color'),
              type: TagType.values.firstWhere(
                (e) => e.name == row.read<String>('type'),
              ),
              createdAt: row.read<DateTime>('created_at'),
              modifiedAt: row.read<DateTime>('modified_at'),
            ),
            usageCount: row.read<int>('usage_count'),
          ),
        )
        .toList();
  }

  /// Получение неиспользуемых тегов
  Future<List<Tag>> getUnusedTags() async {
    final query = customSelect('''
      SELECT t.* 
      FROM tags t 
      LEFT JOIN password_tags pt ON t.id = pt.tag_id
      LEFT JOIN note_tags nt ON t.id = nt.tag_id
      LEFT JOIN totp_tags ot ON t.id = ot.tag_id
      WHERE pt.tag_id IS NULL AND nt.tag_id IS NULL AND ot.tag_id IS NULL
      ORDER BY t.name
    ''');

    final results = await query.get();
    return results
        .map(
          (row) => Tag(
            id: row.read<String>('id'),
            name: row.read<String>('name'),
            color: row.read<String?>('color'),
            type: TagType.values.firstWhere(
              (e) => e.name == row.read<String>('type'),
            ),
            createdAt: row.read<DateTime>('created_at'),
            modifiedAt: row.read<DateTime>('modified_at'),
          ),
        )
        .toList();
  }
}

/// Класс для тега с подсчетом использования
class TagWithUsageCount {
  final Tag tag;
  final int usageCount;

  TagWithUsageCount({required this.tag, required this.usageCount});
}
