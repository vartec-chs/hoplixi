import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/password_histories.dart';
import '../enums/entity_types.dart';

part 'password_histories_dao.g.dart';

/// DAO для работы с историей паролей
@DriftAccessor(tables: [PasswordHistories])
class PasswordHistoriesDao extends DatabaseAccessor<HoplixiStore>
    with _$PasswordHistoriesDaoMixin {
  PasswordHistoriesDao(super.db);

  /// Получить всю историю для конкретного пароля
  Future<List<PasswordHistory>> getPasswordHistory(String passwordId) {
    return (select(attachedDatabase.passwordHistories)
          ..where((tbl) => tbl.originalPasswordId.equals(passwordId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Получить историю с пагинацией
  Future<List<PasswordHistory>> getPasswordHistoryWithPagination(
    String passwordId, {
    int limit = 20,
    int offset = 0,
  }) {
    return (select(attachedDatabase.passwordHistories)
          ..where((tbl) => tbl.originalPasswordId.equals(passwordId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Получить последнюю запись истории для пароля
  Future<PasswordHistory?> getLastPasswordHistory(String passwordId) {
    return (select(attachedDatabase.passwordHistories)
          ..where((tbl) => tbl.originalPasswordId.equals(passwordId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Получить всю историю (все пароли) с фильтрацией по действию
  Future<List<PasswordHistory>> getAllPasswordHistory({
    ActionInHistory? action,
    int limit = 100,
    int offset = 0,
  }) {
    final query = select(attachedDatabase.passwordHistories);

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

  /// Получить статистику истории для пароля
  Future<Map<String, int>> getPasswordHistoryStats(String passwordId) async {
    final allHistory = await getPasswordHistory(passwordId);

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
      attachedDatabase.passwordHistories,
    )..addColumns([attachedDatabase.passwordHistories.id.count()])).getSingle();

    final modifiedCount =
        await (selectOnly(attachedDatabase.passwordHistories)
              ..addColumns([attachedDatabase.passwordHistories.id.count()])
              ..where(
                attachedDatabase.passwordHistories.action.equals(
                  ActionInHistory.modified.name,
                ),
              ))
            .getSingle();

    final deletedCount =
        await (selectOnly(attachedDatabase.passwordHistories)
              ..addColumns([attachedDatabase.passwordHistories.id.count()])
              ..where(
                attachedDatabase.passwordHistories.action.equals(
                  ActionInHistory.deleted.name,
                ),
              ))
            .getSingle();

    final latestAction =
        await (select(attachedDatabase.passwordHistories)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.actionAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    final oldestAction =
        await (select(attachedDatabase.passwordHistories)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.actionAt,
                  mode: OrderingMode.asc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return {
      'total':
          totalCount.read(attachedDatabase.passwordHistories.id.count()) ?? 0,
      'modified':
          modifiedCount.read(attachedDatabase.passwordHistories.id.count()) ??
          0,
      'deleted':
          deletedCount.read(attachedDatabase.passwordHistories.id.count()) ?? 0,
      'latestAction': latestAction?.actionAt,
      'oldestAction': oldestAction?.actionAt,
    };
  }

  /// Поиск в истории по тексту
  Future<List<PasswordHistory>> searchPasswordHistory(
    String query, {
    String? passwordId,
    int limit = 50,
  }) {
    final searchQuery = select(attachedDatabase.passwordHistories);

    searchQuery.where(
      (tbl) =>
          tbl.name.contains(query) |
          tbl.description.contains(query) |
          tbl.url.contains(query) |
          tbl.notes.contains(query) |
          tbl.login.contains(query) |
          tbl.email.contains(query),
    );

    if (passwordId != null) {
      searchQuery.where((tbl) => tbl.originalPasswordId.equals(passwordId));
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
  Future<List<PasswordHistory>> getPasswordHistoryByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? passwordId,
  }) {
    final query = select(attachedDatabase.passwordHistories);

    query.where(
      (tbl) =>
          tbl.actionAt.isBiggerOrEqualValue(startDate) &
          tbl.actionAt.isSmallerOrEqualValue(endDate),
    );

    if (passwordId != null) {
      query.where((tbl) => tbl.originalPasswordId.equals(passwordId));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
    ]);

    return query.get();
  }

  /// Очистить историю старше указанной даты
  Future<int> clearHistoryOlderThan(DateTime date) {
    return (delete(
      attachedDatabase.passwordHistories,
    )..where((tbl) => tbl.actionAt.isSmallerThanValue(date))).go();
  }

  /// Очистить всю историю для конкретного пароля
  Future<int> clearPasswordHistory(String passwordId) {
    return (delete(
      attachedDatabase.passwordHistories,
    )..where((tbl) => tbl.originalPasswordId.equals(passwordId))).go();
  }

  /// Очистить всю историю
  Future<int> clearAllHistory() {
    return delete(attachedDatabase.passwordHistories).go();
  }

  /// Получить количество записей истории для пароля
  Future<int> getPasswordHistoryCount(String passwordId) async {
    final result =
        await (selectOnly(attachedDatabase.passwordHistories)
              ..addColumns([attachedDatabase.passwordHistories.id.count()])
              ..where(
                attachedDatabase.passwordHistories.originalPasswordId.equals(
                  passwordId,
                ),
              ))
            .getSingle();

    return result.read(attachedDatabase.passwordHistories.id.count()) ?? 0;
  }

  /// Ручное создание записи истории (если нужно обойти триггеры)
  Future<String> createHistoryEntry(PasswordHistoriesCompanion entry) async {
    final id = await into(attachedDatabase.passwordHistories).insert(entry);
    return entry.id.value;
  }

  /// Получить запись истории по ID
  Future<PasswordHistory?> getHistoryById(String id) {
    return (select(
      attachedDatabase.passwordHistories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Получить уникальные ID паролей, для которых есть история
  Future<List<String>> getPasswordsWithHistory() async {
    final result =
        await (selectOnly(attachedDatabase.passwordHistories, distinct: true)
              ..addColumns([
                attachedDatabase.passwordHistories.originalPasswordId,
              ]))
            .get();

    return result
        .map(
          (row) =>
              row.read(attachedDatabase.passwordHistories.originalPasswordId)!,
        )
        .toList();
  }

  /// Удалить запись истории по ID
  Future<int> deleteHistoryEntry(String historyId) {
    return (delete(
      attachedDatabase.passwordHistories,
    )..where((tbl) => tbl.id.equals(historyId))).go();
  }
}
