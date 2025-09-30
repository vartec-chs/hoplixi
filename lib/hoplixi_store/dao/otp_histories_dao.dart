import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/otp_histories.dart';

part 'otp_histories_dao.g.dart';

/// DAO для работы с историей TOTP
@DriftAccessor(tables: [OtpHistories])
class OtpHistoriesDao extends DatabaseAccessor<HoplixiStore>
    with _$OtpHistoriesDaoMixin {
  OtpHistoriesDao(super.db);

  /// Получить всю историю для конкретного TOTP
  Future<List<OtpHistory>> getTotpHistory(String totpId) {
    return (select(attachedDatabase.otpHistories)
          ..where((tbl) => tbl.originalOtpId.equals(totpId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Получить историю с пагинацией
  Future<List<OtpHistory>> getTotpHistoryWithPagination(
    String totpId, {
    int limit = 20,
    int offset = 0,
  }) {
    return (select(attachedDatabase.otpHistories)
          ..where((tbl) => tbl.originalOtpId.equals(totpId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Получить последнюю запись истории для TOTP
  Future<OtpHistory?> getLastTotpHistory(String totpId) {
    return (select(attachedDatabase.otpHistories)
          ..where((tbl) => tbl.originalOtpId.equals(totpId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Получить всю историю (все TOTP) с фильтрацией по действию
  Future<List<OtpHistory>> getAllTotpHistory({
    String? action,
    int limit = 100,
    int offset = 0,
  }) {
    final query = select(attachedDatabase.otpHistories);

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
      attachedDatabase.otpHistories,
    )..addColumns([attachedDatabase.otpHistories.id.count()])).getSingle();

    final modifiedCount =
        await (selectOnly(attachedDatabase.otpHistories)
              ..addColumns([attachedDatabase.otpHistories.id.count()])
              ..where(attachedDatabase.otpHistories.action.equals('modified')))
            .getSingle();

    final deletedCount =
        await (selectOnly(attachedDatabase.otpHistories)
              ..addColumns([attachedDatabase.otpHistories.id.count()])
              ..where(attachedDatabase.otpHistories.action.equals('deleted')))
            .getSingle();

    final latestAction =
        await (select(attachedDatabase.otpHistories)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.actionAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    final oldestAction =
        await (select(attachedDatabase.otpHistories)
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.actionAt,
                  mode: OrderingMode.asc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return {
      'total': totalCount.read(attachedDatabase.otpHistories.id.count()) ?? 0,
      'modified':
          modifiedCount.read(attachedDatabase.otpHistories.id.count()) ?? 0,
      'deleted':
          deletedCount.read(attachedDatabase.otpHistories.id.count()) ?? 0,
      'latestAction': latestAction?.actionAt,
      'oldestAction': oldestAction?.actionAt,
    };
  }

  /// Поиск в истории по тексту
  Future<List<OtpHistory>> searchTotpHistory(
    String query, {
    String? totpId,
    int limit = 50,
  }) {
    final searchQuery = select(attachedDatabase.otpHistories);

    searchQuery.where(
      (tbl) => tbl.issuer.contains(query) | tbl.accountName.contains(query),
    );

    if (totpId != null) {
      searchQuery.where((tbl) => tbl.originalOtpId.equals(totpId));
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
  Future<List<OtpHistory>> getTotpHistoryByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? totpId,
  }) {
    final query = select(attachedDatabase.otpHistories);

    query.where(
      (tbl) =>
          tbl.actionAt.isBiggerOrEqualValue(startDate) &
          tbl.actionAt.isSmallerOrEqualValue(endDate),
    );

    if (totpId != null) {
      query.where((tbl) => tbl.originalOtpId.equals(totpId));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
    ]);

    return query.get();
  }

  /// Получить историю по типу OTP (TOTP/HOTP)
  Future<List<OtpHistory>> getTotpHistoryByType(
    String type, {
    int limit = 50,
    int offset = 0,
  }) {
    return (select(attachedDatabase.otpHistories)
          ..where((tbl) => tbl.type.equals(type))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.actionAt, mode: OrderingMode.desc),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  /// Получить историю по издателю (issuer)
  Future<List<OtpHistory>> getTotpHistoryByIssuer(
    String issuer, {
    int limit = 50,
    int offset = 0,
  }) {
    return (select(attachedDatabase.otpHistories)
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
      attachedDatabase.otpHistories,
    )..where((tbl) => tbl.actionAt.isSmallerThanValue(date))).go();
  }

  /// Очистить всю историю для конкретного TOTP
  Future<int> clearTotpHistory(String totpId) {
    return (delete(
      attachedDatabase.otpHistories,
    )..where((tbl) => tbl.originalOtpId.equals(totpId))).go();
  }

  /// Очистить всю историю
  Future<int> clearAllHistory() {
    return delete(attachedDatabase.otpHistories).go();
  }

  /// Получить количество записей истории для TOTP
  Future<int> getTotpHistoryCount(String totpId) async {
    final result =
        await (selectOnly(attachedDatabase.otpHistories)
              ..addColumns([attachedDatabase.otpHistories.id.count()])
              ..where(
                attachedDatabase.otpHistories.originalOtpId.equals(totpId),
              ))
            .getSingle();

    return result.read(attachedDatabase.otpHistories.id.count()) ?? 0;
  }

  /// Ручное создание записи истории (если нужно обойти триггеры)
  Future<String> createHistoryEntry(OtpHistoriesCompanion entry) async {
    await into(attachedDatabase.otpHistories).insert(entry);
    return entry.id.value;
  }

  /// Получить запись истории по ID
  Future<OtpHistory?> getHistoryById(String id) {
    return (select(
      attachedDatabase.otpHistories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  /// Получить уникальные ID TOTP, для которых есть история
  Future<List<String>> getTotpsWithHistory() async {
    final result = await (selectOnly(
      attachedDatabase.otpHistories,
      distinct: true,
    )..addColumns([attachedDatabase.otpHistories.originalOtpId])).get();

    return result
        .map((row) => row.read(attachedDatabase.otpHistories.originalOtpId)!)
        .toList();
  }

  /// Получить историю по категории
  Future<List<OtpHistory>> getTotpHistoryByCategory(String categoryId) {
    return (select(attachedDatabase.otpHistories)
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
        await (selectOnly(attachedDatabase.otpHistories)
              ..addColumns([
                attachedDatabase.otpHistories.algorithm,
                attachedDatabase.otpHistories.id.count(),
              ])
              ..where(attachedDatabase.otpHistories.algorithm.isNotNull())
              ..groupBy([attachedDatabase.otpHistories.algorithm]))
            .get();

    return {
      for (final row in result)
        row.read(attachedDatabase.otpHistories.algorithm) ?? 'unknown':
            row.read(attachedDatabase.otpHistories.id.count()) ?? 0,
    };
  }

  /// Получить статистику по типам действий
  Future<Map<String, int>> getActionTypeStats() async {
    final result =
        await (selectOnly(attachedDatabase.otpHistories)
              ..addColumns([
                attachedDatabase.otpHistories.action,
                attachedDatabase.otpHistories.id.count(),
              ])
              ..groupBy([attachedDatabase.otpHistories.action]))
            .get();

    return {
      for (final row in result)
        row.read(attachedDatabase.otpHistories.action) ?? 'unknown':
            row.read(attachedDatabase.otpHistories.id.count()) ?? 0,
    };
  }

  /// Получить уникальных издателей из истории
  Future<List<String>> getUniqueIssuers() async {
    final result =
        await (selectOnly(attachedDatabase.otpHistories, distinct: true)
              ..addColumns([attachedDatabase.otpHistories.issuer])
              ..where(attachedDatabase.otpHistories.issuer.isNotNull()))
            .get();

    return result
        .map((row) => row.read(attachedDatabase.otpHistories.issuer)!)
        .toList();
  }
}
