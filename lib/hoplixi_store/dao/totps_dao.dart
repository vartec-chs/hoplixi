import 'package:drift/drift.dart';
import 'package:hoplixi/hoplixi_store/utils/uuid_generator.dart';
import '../hoplixi_store.dart';
import '../tables/totps.dart';
import '../dto/db_dto.dart';
import '../enums/entity_types.dart';

part 'totps_dao.g.dart';

@DriftAccessor(tables: [Totps])
class TotpsDao extends DatabaseAccessor<HoplixiStore> with _$TotpsDaoMixin {
  TotpsDao(super.db);

  /// Создание нового TOTP
  Future<String> createTotp(CreateTotpDto dto) async {
    final id = UuidGenerator.generate();
    final companion = TotpsCompanion(
      id: Value(id),
      passwordId: Value(dto.passwordId),
      type: Value(dto.type),
      issuer: Value(dto.issuer),
      accountName: Value(dto.accountName),
      secret: Value(dto.secret), // Будет заполнено в сервисе шифрования
      algorithm: Value(dto.algorithm),
      digits: Value(dto.digits),
      period: Value(dto.period),
      counter: Value(dto.counter),
      categoryId: Value(dto.categoryId),
      isFavorite: Value(dto.isFavorite),
    );

    await into(
      attachedDatabase.totps,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID из companion
    return companion.id.value;
  }

  /// Обновление TOTP
  Future<bool> updateTotp(UpdateTotpDto dto) async {
    final companion = TotpsCompanion(
      id: Value(dto.id),
      passwordId: dto.passwordId != null
          ? Value(dto.passwordId)
          : const Value.absent(),
      type: dto.type != null ? Value(dto.type!) : const Value.absent(),
      issuer: dto.issuer != null ? Value(dto.issuer) : const Value.absent(),
      accountName: dto.accountName != null
          ? Value(dto.accountName)
          : const Value.absent(),
      secret: dto.secret != null
          ? Value(dto.secret!)
          : const Value.absent(), // Будет зашифровано
      algorithm: dto.algorithm != null
          ? Value(dto.algorithm!)
          : const Value.absent(),
      digits: dto.digits != null ? Value(dto.digits!) : const Value.absent(),
      period: dto.period != null ? Value(dto.period!) : const Value.absent(),
      counter: dto.counter != null ? Value(dto.counter) : const Value.absent(),
      categoryId: dto.categoryId != null
          ? Value(dto.categoryId)
          : const Value.absent(),
      isFavorite: dto.isFavorite != null
          ? Value(dto.isFavorite!)
          : const Value.absent(),
      lastAccessed: dto.lastAccessed != null
          ? Value(dto.lastAccessed)
          : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await update(
      attachedDatabase.totps,
    ).replace(companion);
    return rowsAffected;
  }

  /// Удаление TOTP по ID
  Future<bool> deleteTotp(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.totps,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение TOTP по ID
  Future<Totp?> getTotpById(String id) async {
    final query = select(attachedDatabase.totps)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех TOTP
  Future<List<Totp>> getAllTotps() async {
    final query = select(attachedDatabase.totps)
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение TOTP по категории
  Future<List<Totp>> getTotpsByCategory(String categoryId) async {
    final query = select(attachedDatabase.totps)
      ..where((tbl) => tbl.categoryId.equals(categoryId))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение TOTP по паролю
  Future<List<Totp>> getTotpsByPassword(String passwordId) async {
    final query = select(attachedDatabase.totps)
      ..where((tbl) => tbl.passwordId.equals(passwordId))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение избранных TOTP
  Future<List<Totp>> getFavoriteTotps() async {
    final query = select(attachedDatabase.totps)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение TOTP по типу (TOTP/HOTP)
  Future<List<Totp>> getTotpsByType(OtpType type) async {
    final query = select(attachedDatabase.totps)
      ..where((tbl) => tbl.type.equals(type.name))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Поиск TOTP по имени, эмитенту или аккаунту
  Future<List<Totp>> searchTotps(String searchTerm) async {
    final query = select(attachedDatabase.totps)
      ..where(
        (tbl) =>
            tbl.issuer.like('%$searchTerm%') |
            tbl.accountName.like('%$searchTerm%') |
            tbl.notes.like('%$searchTerm%'),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение недавно использованных TOTP
  Future<List<Totp>> getRecentlyAccessedTotps({int limit = 10}) async {
    final query = select(attachedDatabase.totps)
      ..where((tbl) => tbl.lastAccessed.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastAccessed)])
      ..limit(limit);
    return await query.get();
  }

  /// Обновление времени последнего доступа
  Future<void> updateLastAccessed(String id) async {
    await (update(
      attachedDatabase.totps,
    )..where((tbl) => tbl.id.equals(id))).write(
      TotpsCompanion(
        lastAccessed: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Обновление счетчика для HOTP
  Future<void> updateHotpCounter(String id, int newCounter) async {
    await (update(
      attachedDatabase.totps,
    )..where((tbl) => tbl.id.equals(id))).write(
      TotpsCompanion(
        counter: Value(newCounter),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Добавление/удаление из избранного
  Future<void> toggleFavoriteTotp(String id) async {
    final totp = await getTotpById(id);
    if (totp != null) {
      await (update(
        attachedDatabase.totps,
      )..where((tbl) => tbl.id.equals(id))).write(
        TotpsCompanion(
          isFavorite: Value(!totp.isFavorite),
          modifiedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Получение количества TOTP
  Future<int> getTotpsCount() async {
    final query = selectOnly(attachedDatabase.totps)
      ..addColumns([attachedDatabase.totps.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.totps.id.count()) ?? 0;
  }

  /// Получение количества TOTP по категориям
  Future<Map<String?, int>> getTotpsCountByCategory() async {
    final query = selectOnly(attachedDatabase.totps)
      ..addColumns([
        attachedDatabase.totps.categoryId,
        attachedDatabase.totps.id.count(),
      ])
      ..groupBy([attachedDatabase.totps.categoryId]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.totps.categoryId):
            row.read(attachedDatabase.totps.id.count()) ?? 0,
    };
  }

  /// Получение количества TOTP по типам
  Future<Map<String, int>> getTotpsCountByType() async {
    final query = selectOnly(attachedDatabase.totps)
      ..addColumns([
        attachedDatabase.totps.type,
        attachedDatabase.totps.id.count(),
      ])
      ..groupBy([attachedDatabase.totps.type]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.totps.type)!:
            row.read(attachedDatabase.totps.id.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за всеми TOTP
  Stream<List<Totp>> watchAllTotps() {
    final query = select(attachedDatabase.totps)
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Stream для наблюдения за TOTP по категории
  Stream<List<Totp>> watchTotpsByCategory(String categoryId) {
    final query = select(attachedDatabase.totps)
      ..where((tbl) => tbl.categoryId.equals(categoryId))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Stream для наблюдения за избранными TOTP
  Stream<List<Totp>> watchFavoriteTotps() {
    final query = select(attachedDatabase.totps)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Stream для наблюдения за TOTP по паролю
  Stream<List<Totp>> watchTotpsByPassword(String passwordId) {
    final query = select(attachedDatabase.totps)
      ..where((tbl) => tbl.passwordId.equals(passwordId))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Batch операции для создания множественных TOTP
  Future<void> createTotpsBatch(List<CreateTotpDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = TotpsCompanion(
          passwordId: Value(dto.passwordId),
          type: Value(dto.type),
          issuer: Value(dto.issuer),
          accountName: Value(dto.accountName),
          secret: Value(dto.secret),
          algorithm: Value(dto.algorithm),
          digits: Value(dto.digits),
          period: Value(dto.period),
          counter: Value(dto.counter),
          categoryId: Value(dto.categoryId),
          isFavorite: Value(dto.isFavorite),
        );
        batch.insert(attachedDatabase.totps, companion);
      }
    });
  }
}
