import 'package:drift/drift.dart';
import 'package:hoplixi/hoplixi_store/utils/uuid_generator.dart';
import '../hoplixi_store.dart';
import '../tables/otps.dart';
import '../dto/db_dto.dart';
import '../enums/entity_types.dart';

part 'otps_dao.g.dart';

@DriftAccessor(tables: [Otps])
class OtpsDao extends DatabaseAccessor<HoplixiStore> with _$OtpsDaoMixin {
  OtpsDao(super.db);

  /// Создание нового TOTP
  Future<String> createTotp(CreateTotpDto dto) async {
    final id = UuidGenerator.generate();
    final companion = OtpsCompanion(
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
      attachedDatabase.otps,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID из companion
    return companion.id.value;
  }

  /// Обновление TOTP
  Future<bool> updateTotp(UpdateTotpDto dto) async {
    final companion = OtpsCompanion(
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
      attachedDatabase.otps,
    ).replace(companion);
    return rowsAffected;
  }

  /// Удаление TOTP по ID
  Future<bool> deleteTotp(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.otps,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение TOTP по ID
  Future<Otp?> getTotpById(String id) async {
    final query = select(attachedDatabase.otps)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех TOTP
  Future<List<Otp>> getAllTotps() async {
    final query = select(attachedDatabase.otps)
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение TOTP по категории
  Future<List<Otp>> getTotpsByCategory(String categoryId) async {
    final query = select(attachedDatabase.otps)
      ..where((tbl) => tbl.categoryId.equals(categoryId))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение TOTP по паролю
  Future<List<Otp>> getTotpsByPassword(String passwordId) async {
    final query = select(attachedDatabase.otps)
      ..where((tbl) => tbl.passwordId.equals(passwordId))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение избранных OTP
  Future<List<Otp>> getFavoriteOtps() async {
    final query = select(attachedDatabase.otps)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение OTP по типу (TOTP/HOTP)
  Future<List<Otp>> getOtpsByType(OtpType type) async {
    final query = select(attachedDatabase.otps)
      ..where((tbl) => tbl.type.equals(type.name))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Поиск OTP по имени, эмитенту или аккаунту
  Future<List<Otp>> searchOtps(String searchTerm) async {
    final query = select(attachedDatabase.otps)
      ..where(
        (tbl) =>
            tbl.issuer.like('%$searchTerm%') |
            tbl.accountName.like('%$searchTerm%') |
            tbl.notes.like('%$searchTerm%'),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение недавно использованных OTP
  Future<List<Otp>> getRecentlyAccessedOtps({int limit = 10}) async {
    final query = select(attachedDatabase.otps)
      ..where((tbl) => tbl.lastAccessed.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastAccessed)])
      ..limit(limit);
    return await query.get();
  }

  /// Обновление времени последнего доступа
  Future<void> updateLastAccessed(String id) async {
    await (update(
      attachedDatabase.otps,
    )..where((tbl) => tbl.id.equals(id))).write(
      OtpsCompanion(
        lastAccessed: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Обновление счетчика для HOTP
  Future<void> updateHotpCounter(String id, int newCounter) async {
    await (update(
      attachedDatabase.otps,
    )..where((tbl) => tbl.id.equals(id))).write(
      OtpsCompanion(
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
        attachedDatabase.otps,
      )..where((tbl) => tbl.id.equals(id))).write(
        OtpsCompanion(
          isFavorite: Value(!totp.isFavorite),
          modifiedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Получение количества OTP
  Future<int> getOtpsCount() async {
    final query = selectOnly(attachedDatabase.otps)
      ..addColumns([attachedDatabase.otps.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.otps.id.count()) ?? 0;
  }

  /// Получение количества OTP по категориям
  Future<Map<String?, int>> getOtpsCountByCategory() async {
    final query = selectOnly(attachedDatabase.otps)
      ..addColumns([
        attachedDatabase.otps.categoryId,
        attachedDatabase.otps.id.count(),
      ])
      ..groupBy([attachedDatabase.otps.categoryId]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.otps.categoryId):
            row.read(attachedDatabase.otps.id.count()) ?? 0,
    };
  }

  /// Получение количества OTP по типам
  Future<Map<String, int>> getOtpsCountByType() async {
    final query = selectOnly(attachedDatabase.otps)
      ..addColumns([
        attachedDatabase.otps.type,
        attachedDatabase.otps.id.count(),
      ])
      ..groupBy([attachedDatabase.otps.type]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.otps.type)!:
            row.read(attachedDatabase.otps.id.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за всеми OTP
  Stream<List<Otp>> watchAllOtps() {
    final query = select(attachedDatabase.otps)
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Stream для наблюдения за OTP по категории
  Stream<List<Otp>> watchOtpsByCategory(String categoryId) {
    final query = select(attachedDatabase.otps)
      ..where((tbl) => tbl.categoryId.equals(categoryId))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Stream для наблюдения за избранными OTP
  Stream<List<Otp>> watchFavoriteOtps() {
    final query = select(attachedDatabase.otps)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Stream для наблюдения за OTP по паролю
  Stream<List<Otp>> watchOtpsByPassword(String passwordId) {
    final query = select(attachedDatabase.otps)
      ..where((tbl) => tbl.passwordId.equals(passwordId))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Batch операции для создания множественных TOTP
  Future<void> createTotpsBatch(List<CreateTotpDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = OtpsCompanion(
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
        batch.insert(attachedDatabase.otps, companion);
      }
    });
  }
}
