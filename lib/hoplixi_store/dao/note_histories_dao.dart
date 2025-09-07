import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/note_histories.dart';
import '../enums/entity_types.dart';

part 'note_histories_dao.g.dart';

/// DAO для работы с историей заметок
@DriftAccessor(tables: [NoteHistories])
class NoteHistoriesDao extends DatabaseAccessor<HoplixiStore>
    with _$NoteHistoriesDaoMixin {
  NoteHistoriesDao(super.db);

  /// Получить всю историю для конкретной заметки
  Future<List<NoteHistory>> getNoteHistory(String noteId) {
    return (select(attachedDatabase.noteHistories)
          ..where((tbl) => tbl.originalNoteId.equals(noteId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Получить историю с пагинацией
  Future<List<NoteHistory>> getNoteHistoryWithPagination(
    String noteId, {
    int limit = 20,
    int offset = 0,
  }) {
    return (select(attachedDatabase.noteHistories)
          ..where((tbl) => tbl.originalNoteId.equals(noteId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Получить последнюю запись истории для заметки
  Future<NoteHistory?> getLastNoteHistory(String noteId) {
    return (select(attachedDatabase.noteHistories)
          ..where((tbl) => tbl.originalNoteId.equals(noteId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Получить всю историю (все заметки) с фильтрацией по действию
  Future<List<NoteHistory>> getAllNoteHistory({
    ActionInHistory? action,
    int limit = 100,
    int offset = 0,
  }) {
    final query = select(attachedDatabase.noteHistories);

    if (action != null) {
      query.where((tbl) => tbl.action.equals(action.name));
    }

    query
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    return query.get();
  }

  /// Получить статистику истории для заметки
  Future<Map<String, int>> getNoteHistoryStats(String noteId) async {
    final allHistory = await getNoteHistory(noteId);

    return {
      'total': allHistory.length,
      'modified': allHistory
          .where((h) => h.action == ActionInHistory.modified)
          .length,
      'deleted': allHistory
          .where((h) => h.action == ActionInHistory.deleted)
          .length,
    };
  }

  /// Получить общую статистику истории
  Future<Map<String, dynamic>> getOverallStats() async {
    final totalCount = await (selectOnly(
      attachedDatabase.noteHistories,
    )..addColumns([attachedDatabase.noteHistories.id.count()])).getSingle();

    final modifiedCount =
        await (selectOnly(attachedDatabase.noteHistories)
              ..addColumns([attachedDatabase.noteHistories.id.count()])
              ..where(
                attachedDatabase.noteHistories.action.equals(
                  ActionInHistory.modified.name,
                ),
              ))
            .getSingle();

    final deletedCount =
        await (selectOnly(attachedDatabase.noteHistories)
              ..addColumns([attachedDatabase.noteHistories.id.count()])
              ..where(
                attachedDatabase.noteHistories.action.equals(
                  ActionInHistory.deleted.name,
                ),
              ))
            .getSingle();

    final latestAction =
        await (select(attachedDatabase.noteHistories)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.actionAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    final oldestAction =
        await (select(attachedDatabase.noteHistories)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.actionAt,
                  mode: OrderingMode.asc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return {
      'total': totalCount.read(attachedDatabase.noteHistories.id.count()) ?? 0,
      'modified':
          modifiedCount.read(attachedDatabase.noteHistories.id.count()) ?? 0,
      'deleted':
          deletedCount.read(attachedDatabase.noteHistories.id.count()) ?? 0,
      'latestAction': latestAction?.actionAt,
      'oldestAction': oldestAction?.actionAt,
    };
  }

  /// Поиск в истории по тексту
  Future<List<NoteHistory>> searchNoteHistory(
    String query, {
    String? noteId,
    int limit = 50,
  }) {
    final searchQuery = select(attachedDatabase.noteHistories);

    searchQuery.where(
      (tbl) => tbl.title.contains(query) | tbl.content.contains(query),
    );

    if (noteId != null) {
      searchQuery.where((tbl) => tbl.originalNoteId.equals(noteId));
    }

    searchQuery
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    return searchQuery.get();
  }

  /// Получить записи истории по диапазону дат
  Future<List<NoteHistory>> getNoteHistoryByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? noteId,
  }) {
    final query = select(attachedDatabase.noteHistories);

    query.where(
      (tbl) =>
          tbl.actionAt.isBiggerOrEqualValue(startDate) &
          tbl.actionAt.isSmallerOrEqualValue(endDate),
    );

    if (noteId != null) {
      query.where((tbl) => tbl.originalNoteId.equals(noteId));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
    ]);

    return query.get();
  }

  /// Получить историю избранных заметок
  Future<List<NoteHistory>> getFavoriteNotesHistory({
    int limit = 50,
    int offset = 0,
  }) {
    return (select(attachedDatabase.noteHistories)
          ..where((tbl) => tbl.wasFavorite.equals(true))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Получить историю закрепленных заметок
  Future<List<NoteHistory>> getPinnedNotesHistory({
    int limit = 50,
    int offset = 0,
  }) {
    return (select(attachedDatabase.noteHistories)
          ..where((tbl) => tbl.wasPinned.equals(true))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Очистить историю старше указанной даты
  Future<int> clearHistoryOlderThan(DateTime date) {
    return (delete(
      attachedDatabase.noteHistories,
    )..where((tbl) => tbl.actionAt.isSmallerThanValue(date))).go();
  }

  /// Очистить всю историю для конкретной заметки
  Future<int> clearNoteHistory(String noteId) {
    return (delete(
      attachedDatabase.noteHistories,
    )..where((tbl) => tbl.originalNoteId.equals(noteId))).go();
  }

  /// Очистить всю историю
  Future<int> clearAllHistory() {
    return delete(attachedDatabase.noteHistories).go();
  }

  /// Получить количество записей истории для заметки
  Future<int> getNoteHistoryCount(String noteId) async {
    final result =
        await (selectOnly(attachedDatabase.noteHistories)
              ..addColumns([attachedDatabase.noteHistories.id.count()])
              ..where(
                attachedDatabase.noteHistories.originalNoteId.equals(noteId),
              ))
            .getSingle();

    return result.read(attachedDatabase.noteHistories.id.count()) ?? 0;
  }

  /// Ручное создание записи истории (если нужно обойти триггеры)
  Future<String> createHistoryEntry(NoteHistoriesCompanion entry) async {
    final id = await into(attachedDatabase.noteHistories).insert(entry);
    return entry.id.value;
  }

  /// Получить запись истории по ID
  Future<NoteHistory?> getHistoryById(String id) {
    return (select(
      attachedDatabase.noteHistories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Получить уникальные ID заметок, для которых есть история
  Future<List<String>> getNotesWithHistory() async {
    final result = await (selectOnly(
      attachedDatabase.noteHistories,
      distinct: true,
    )..addColumns([attachedDatabase.noteHistories.originalNoteId])).get();

    return result
        .map((row) => row.read(attachedDatabase.noteHistories.originalNoteId)!)
        .toList();
  }

  /// Получить историю по категории
  Future<List<NoteHistory>> getNoteHistoryByCategory(String categoryId) {
    return (select(attachedDatabase.noteHistories)
          ..where((tbl) => tbl.categoryId.equals(categoryId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Получить статистику по типам действий
  Future<Map<ActionInHistory, int>> getActionTypeStats() async {
    final result =
        await (selectOnly(attachedDatabase.noteHistories)
              ..addColumns([
                attachedDatabase.noteHistories.action,
                attachedDatabase.noteHistories.id.count(),
              ])
              ..groupBy([attachedDatabase.noteHistories.action]))
            .get();

    return {
      for (final row in result)
        ActionInHistory.values.firstWhere(
          (action) =>
              action.name == row.read(attachedDatabase.noteHistories.action),
        ): row.read(attachedDatabase.noteHistories.id.count()) ?? 0,
    };
  }
}
