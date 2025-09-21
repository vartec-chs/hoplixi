import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/otp_histories.dart';

part 'totp_histories_dao.g.dart';

/// DAO для работы с историей TOTP
@DriftAccessor(tables: [TotpHistories])
class TotpHistoriesDao extends DatabaseAccessor<HoplixiStore>
    with _$TotpHistoriesDaoMixin {
  TotpHistoriesDao(super.db);

  /// Получить всю историю для конкретного TOTP
  Future<List<TotpHistory>> getTotpHistory(String totpId) {
    return (select(attachedDatabase.totpHistories)
          ..where((tbl) => tbl.originalTotpId.equals(totpId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Получить историю с пагинацией
  Future<List<TotpHistory>> getTotpHistoryWithPagination(
    String totpId, {
    int limit = 20,
    int offset = 0,
  }) {
    return (select(attachedDatabase.totpHistories)
          ..where((tbl) => tbl.originalTotpId.equals(totpId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Получить последнюю запись истории для TOTP
  Future<TotpHistory?> getLastTotpHistory(String totpId) {
    return (select(attachedDatabase.totpHistories)
          ..where((tbl) => tbl.originalTotpId.equals(totpId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Получить всю историю (все TOTP) с фильтрацией по действию
  Future<List<TotpHistory>> getAllTotpHistory({
    String? action,
    int limit = 100,
    int offset = 0,
  }) {
    final query = select(attachedDatabase.totpHistories);

    if (action != null) {
      query.where((tbl) => tbl.action.equals(action));
    }

    query
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
      ])
      ..limit(limit, offset: offset);

    return query.get();
  }

  /// Получить статистику истории для TOTP
  Future<Map<String, int>> getTotpHistoryStats(String totpId) async {
    final allHistory = await getTotpHistory(totpId);

    return {
      'total': allHistory.length,
      'modified': allHistory.where((h) => h.action == 'modified').length,
      'deleted': allHistory.where((h) => h.action == 'deleted').length,
    };
  }

  /// Получить общую статистику истории
  Future<Map<String, dynamic>> getOverallStats() async {
    final totalCount = await (selectOnly(
      attachedDatabase.totpHistories,
    )..addColumns([attachedDatabase.totpHistories.id.count()])).getSingle();

    final modifiedCount =
        await (selectOnly(attachedDatabase.totpHistories)
              ..addColumns([attachedDatabase.totpHistories.id.count()])
              ..where(attachedDatabase.totpHistories.action.equals('modified')))
            .getSingle();

    final deletedCount =
        await (selectOnly(attachedDatabase.totpHistories)
              ..addColumns([attachedDatabase.totpHistories.id.count()])
              ..where(attachedDatabase.totpHistories.action.equals('deleted')))
            .getSingle();

    final latestAction =
        await (select(attachedDatabase.totpHistories)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.actionAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    final oldestAction =
        await (select(attachedDatabase.totpHistories)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.actionAt,
                  mode: OrderingMode.asc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return {
      'total': totalCount.read(attachedDatabase.totpHistories.id.count()) ?? 0,
      'modified':
          modifiedCount.read(attachedDatabase.totpHistories.id.count()) ?? 0,
      'deleted':
          deletedCount.read(attachedDatabase.totpHistories.id.count()) ?? 0,
      'latestAction': latestAction?.actionAt,
      'oldestAction': oldestAction?.actionAt,
    };
  }

  /// Поиск в истории по тексту
  Future<List<TotpHistory>> searchTotpHistory(
    String query, {
    String? totpId,
    int limit = 50,
  }) {
    final searchQuery = select(attachedDatabase.totpHistories);

    searchQuery.where(
      (tbl) =>
          tbl.name.contains(query) |
          tbl.description.contains(query) |
          tbl.issuer.contains(query) |
          tbl.accountName.contains(query),
    );

    if (totpId != null) {
      searchQuery.where((tbl) => tbl.originalTotpId.equals(totpId));
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
  Future<List<TotpHistory>> getTotpHistoryByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? totpId,
  }) {
    final query = select(attachedDatabase.totpHistories);

    query.where(
      (tbl) =>
          tbl.actionAt.isBiggerOrEqualValue(startDate) &
          tbl.actionAt.isSmallerOrEqualValue(endDate),
    );

    if (totpId != null) {
      query.where((tbl) => tbl.originalTotpId.equals(totpId));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
    ]);

    return query.get();
  }

  /// Получить историю по типу OTP (TOTP/HOTP)
  Future<List<TotpHistory>> getTotpHistoryByType(
    String type, {
    int limit = 50,
    int offset = 0,
  }) {
    return (select(attachedDatabase.totpHistories)
          ..where((tbl) => tbl.type.equals(type))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Получить историю по издателю (issuer)
  Future<List<TotpHistory>> getTotpHistoryByIssuer(
    String issuer, {
    int limit = 50,
    int offset = 0,
  }) {
    return (select(attachedDatabase.totpHistories)
          ..where((tbl) => tbl.issuer.equals(issuer))
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
      attachedDatabase.totpHistories,
    )..where((tbl) => tbl.actionAt.isSmallerThanValue(date))).go();
  }

  /// Очистить всю историю для конкретного TOTP
  Future<int> clearTotpHistory(String totpId) {
    return (delete(
      attachedDatabase.totpHistories,
    )..where((tbl) => tbl.originalTotpId.equals(totpId))).go();
  }

  /// Очистить всю историю
  Future<int> clearAllHistory() {
    return delete(attachedDatabase.totpHistories).go();
  }

  /// Получить количество записей истории для TOTP
  Future<int> getTotpHistoryCount(String totpId) async {
    final result =
        await (selectOnly(attachedDatabase.totpHistories)
              ..addColumns([attachedDatabase.totpHistories.id.count()])
              ..where(
                attachedDatabase.totpHistories.originalTotpId.equals(totpId),
              ))
            .getSingle();

    return result.read(attachedDatabase.totpHistories.id.count()) ?? 0;
  }

  /// Ручное создание записи истории (если нужно обойти триггеры)
  Future<String> createHistoryEntry(TotpHistoriesCompanion entry) async {
    await into(attachedDatabase.totpHistories).insert(entry);
    return entry.id.value;
  }

  /// Получить запись истории по ID
  Future<TotpHistory?> getHistoryById(String id) {
    return (select(
      attachedDatabase.totpHistories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Получить уникальные ID TOTP, для которых есть история
  Future<List<String>> getTotpsWithHistory() async {
    final result = await (selectOnly(
      attachedDatabase.totpHistories,
      distinct: true,
    )..addColumns([attachedDatabase.totpHistories.originalTotpId])).get();

    return result
        .map((row) => row.read(attachedDatabase.totpHistories.originalTotpId)!)
        .toList();
  }

  /// Получить историю по категории
  Future<List<TotpHistory>> getTotpHistoryByCategory(String categoryId) {
    return (select(attachedDatabase.totpHistories)
          ..where((tbl) => tbl.categoryId.equals(categoryId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Получить статистику по алгоритмам
  Future<Map<String, int>> getAlgorithmStats() async {
    final result =
        await (selectOnly(attachedDatabase.totpHistories)
              ..addColumns([
                attachedDatabase.totpHistories.algorithm,
                attachedDatabase.totpHistories.id.count(),
              ])
              ..where(attachedDatabase.totpHistories.algorithm.isNotNull())
              ..groupBy([attachedDatabase.totpHistories.algorithm]))
            .get();

    return {
      for (final row in result)
        row.read(attachedDatabase.totpHistories.algorithm) ?? 'unknown':
            row.read(attachedDatabase.totpHistories.id.count()) ?? 0,
    };
  }

  /// Получить статистику по типам действий
  Future<Map<String, int>> getActionTypeStats() async {
    final result =
        await (selectOnly(attachedDatabase.totpHistories)
              ..addColumns([
                attachedDatabase.totpHistories.action,
                attachedDatabase.totpHistories.id.count(),
              ])
              ..groupBy([attachedDatabase.totpHistories.action]))
            .get();

    return {
      for (final row in result)
        row.read(attachedDatabase.totpHistories.action) ?? 'unknown':
            row.read(attachedDatabase.totpHistories.id.count()) ?? 0,
    };
  }

  /// Получить уникальных издателей из истории
  Future<List<String>> getUniqueIssuers() async {
    final result =
        await (selectOnly(attachedDatabase.totpHistories, distinct: true)
              ..addColumns([attachedDatabase.totpHistories.issuer])
              ..where(attachedDatabase.totpHistories.issuer.isNotNull()))
            .get();

    return result
        .map((row) => row.read(attachedDatabase.totpHistories.issuer)!)
        .toList();
  }
}
