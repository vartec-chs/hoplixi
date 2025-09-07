import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/passwords.dart';
import '../dto/db_dto.dart';

part 'passwords_dao.g.dart';

@DriftAccessor(tables: [Passwords])
class PasswordsDao extends DatabaseAccessor<HoplixiStore>
    with _$PasswordsDaoMixin {
  PasswordsDao(super.db);

  /// Создание нового пароля
  Future<String> createPassword(CreatePasswordDto dto) async {
    final companion = PasswordsCompanion(
      name: Value(dto.name),
      description: Value(dto.description),
      password: Value(dto.password),
      url: Value(dto.url),
      notes: Value(dto.notes),
      login: Value(dto.login),
      email: Value(dto.email),
      categoryId: Value(dto.categoryId),
      isFavorite: Value(dto.isFavorite),
    );

    final result = await into(
      attachedDatabase.passwords,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID из companion
    return companion.id.value;
  }

  /// Обновление пароля
  Future<bool> updatePassword(UpdatePasswordDto dto) async {
    final companion = PasswordsCompanion(
      id: Value(dto.id),
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      password: dto.password != null
          ? Value(dto.password!)
          : const Value.absent(),
      url: dto.url != null ? Value(dto.url) : const Value.absent(),
      notes: dto.notes != null ? Value(dto.notes) : const Value.absent(),
      login: dto.login != null ? Value(dto.login) : const Value.absent(),
      email: dto.email != null ? Value(dto.email) : const Value.absent(),
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
      attachedDatabase.passwords,
    ).replace(companion);
    return rowsAffected;
  }

  /// Удаление пароля по ID
  Future<bool> deletePassword(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.passwords,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение пароля по ID
  Future<Password?> getPasswordById(String id) async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех паролей
  Future<List<Password>> getAllPasswords() async {
    return await select(attachedDatabase.passwords).get();
  }

  /// Получение паролей по категории
  Future<List<Password>> getPasswordsByCategory(String categoryId) async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.categoryId.equals(categoryId));
    return await query.get();
  }

  /// Получение избранных паролей
  Future<List<Password>> getFavoritePasswords() async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Поиск паролей по имени или URL
  Future<List<Password>> searchPasswords(String searchTerm) async {
    final query = select(attachedDatabase.passwords)
      ..where(
        (tbl) =>
            tbl.name.like('%$searchTerm%') |
            tbl.url.like('%$searchTerm%') |
            tbl.login.like('%$searchTerm%') |
            tbl.email.like('%$searchTerm%'),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение недавно использованных паролей
  Future<List<Password>> getRecentlyAccessedPasswords({int limit = 10}) async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.lastAccessed.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastAccessed)])
      ..limit(limit);
    return await query.get();
  }

  /// Обновление времени последнего доступа
  Future<void> updateLastAccessed(String id) async {
    await (update(
      attachedDatabase.passwords,
    )..where((tbl) => tbl.id.equals(id))).write(
      PasswordsCompanion(
        lastAccessed: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Получение количества паролей
  Future<int> getPasswordsCount() async {
    final query = selectOnly(attachedDatabase.passwords)
      ..addColumns([attachedDatabase.passwords.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.passwords.id.count()) ?? 0;
  }

  /// Получение количества паролей по категориям
  Future<Map<String?, int>> getPasswordsCountByCategory() async {
    final query = selectOnly(attachedDatabase.passwords)
      ..addColumns([
        attachedDatabase.passwords.categoryId,
        attachedDatabase.passwords.id.count(),
      ])
      ..groupBy([attachedDatabase.passwords.categoryId]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.passwords.categoryId):
            row.read(attachedDatabase.passwords.id.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за всеми паролями
  Stream<List<Password>> watchAllPasswords() {
    return select(attachedDatabase.passwords).watch();
  }

  /// Stream для наблюдения за паролями по категории
  Stream<List<Password>> watchPasswordsByCategory(String categoryId) {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.categoryId.equals(categoryId));
    return query.watch();
  }

  /// Stream для наблюдения за избранными паролями
  Stream<List<Password>> watchFavoritePasswords() {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Batch операции для создания множественных паролей
  Future<void> createPasswordsBatch(List<CreatePasswordDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = PasswordsCompanion(
          name: Value(dto.name),
          description: Value(dto.description),
          password: Value(dto.password),
          url: Value(dto.url),
          notes: Value(dto.notes),
          login: Value(dto.login),
          email: Value(dto.email),
          categoryId: Value(dto.categoryId),
          isFavorite: Value(dto.isFavorite),
        );
        batch.insert(attachedDatabase.passwords, companion);
      }
    });
  }
}
