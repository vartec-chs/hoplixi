import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/password_tags.dart';
import '../tables/passwords.dart';
import '../tables/tags.dart';

part 'password_tags_dao.g.dart';

@DriftAccessor(tables: [PasswordTags, Passwords, Tags])
class PasswordTagsDao extends DatabaseAccessor<HoplixiStore>
    with _$PasswordTagsDaoMixin {
  PasswordTagsDao(HoplixiStore db) : super(db);

  /// Добавление тега к паролю
  Future<void> addTagToPassword(String passwordId, String tagId) async {
    final companion = PasswordTagsCompanion(
      passwordId: Value(passwordId),
      tagId: Value(tagId),
    );

    await into(
      attachedDatabase.passwordTags,
    ).insert(companion, mode: InsertMode.insertOrIgnore);
  }

  /// Удаление тега у пароля
  Future<bool> removeTagFromPassword(String passwordId, String tagId) async {
    final rowsAffected =
        await (delete(attachedDatabase.passwordTags)..where(
              (tbl) =>
                  tbl.passwordId.equals(passwordId) & tbl.tagId.equals(tagId),
            ))
            .go();
    return rowsAffected > 0;
  }

  /// Получение всех тегов для пароля
  Future<List<Tag>> getTagsForPassword(String passwordId) async {
    final query = select(attachedDatabase.tags).join([
      innerJoin(
        attachedDatabase.passwordTags,
        attachedDatabase.passwordTags.tagId.equalsExp(attachedDatabase.tags.id),
      ),
    ])..where(attachedDatabase.passwordTags.passwordId.equals(passwordId));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.tags)).toList();
  }

  /// Получение всех паролей для тега
  Future<List<Password>> getPasswordsForTag(String tagId) async {
    final query = select(attachedDatabase.passwords).join([
      innerJoin(
        attachedDatabase.passwordTags,
        attachedDatabase.passwordTags.passwordId.equalsExp(
          attachedDatabase.passwords.id,
        ),
      ),
    ])..where(attachedDatabase.passwordTags.tagId.equals(tagId));

    final results = await query.get();
    return results
        .map((row) => row.readTable(attachedDatabase.passwords))
        .toList();
  }

  /// Получение паролей с тегами
  Future<List<PasswordWithTags>> getPasswordsWithTags() async {
    final passwordsQuery = select(attachedDatabase.passwords);
    final passwords = await passwordsQuery.get();

    final List<PasswordWithTags> result = [];

    for (final password in passwords) {
      final tags = await getTagsForPassword(password.id);
      result.add(PasswordWithTags(password: password, tags: tags));
    }

    return result;
  }

  /// Получение паролей по множественным тегам (AND условие)
  Future<List<Password>> getPasswordsByTags(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    // Строим запрос для поиска паролей, которые имеют ВСЕ указанные теги
    String placeholders = tagIds.map((_) => '?').join(',');

    final query = customSelect(
      '''
      SELECT p.* FROM passwords p
      WHERE p.id IN (
        SELECT pt.password_id
        FROM password_tags pt
        WHERE pt.tag_id IN ($placeholders)
        GROUP BY pt.password_id
        HAVING COUNT(DISTINCT pt.tag_id) = ?
      )
      ORDER BY p.modified_at DESC
    ''',
      variables: [...tagIds.map((id) => Variable(id)), Variable(tagIds.length)],
    );

    final results = await query.get();
    return results
        .map(
          (row) => Password(
            id: row.read<String>('id'),
            name: row.read<String>('name'),
            description: row.read<String?>('description'),
            password: row.read<String>('password'),
            url: row.read<String?>('url'),
            notes: row.read<String?>('notes'),
            login: row.read<String?>('login'),
            email: row.read<String?>('email'),
            categoryId: row.read<String?>('category_id'),
            isFavorite: row.read<bool>('is_favorite'),
            createdAt: row.read<DateTime>('created_at'),
            modifiedAt: row.read<DateTime>('modified_at'),
            lastAccessed: row.read<DateTime?>('last_accessed'),
          ),
        )
        .toList();
  }

  /// Получение паролей по любому из тегов (OR условие)
  Future<List<Password>> getPasswordsByAnyTag(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    final query = select(attachedDatabase.passwords).join([
      innerJoin(
        attachedDatabase.passwordTags,
        attachedDatabase.passwordTags.passwordId.equalsExp(
          attachedDatabase.passwords.id,
        ),
      ),
    ])..where(attachedDatabase.passwordTags.tagId.isIn(tagIds));

    final results = await query.get();
    return results
        .map((row) => row.readTable(attachedDatabase.passwords))
        .toList();
  }

  /// Замена всех тегов у пароля
  Future<void> replacePasswordTags(
    String passwordId,
    List<String> tagIds,
  ) async {
    await transaction(() async {
      // Удаляем все существующие теги
      await (delete(
        attachedDatabase.passwordTags,
      )..where((tbl) => tbl.passwordId.equals(passwordId))).go();

      // Добавляем новые теги
      for (final tagId in tagIds) {
        await addTagToPassword(passwordId, tagId);
      }
    });
  }

  /// Проверка наличия тега у пароля
  Future<bool> passwordHasTag(String passwordId, String tagId) async {
    final query = select(attachedDatabase.passwordTags)
      ..where(
        (tbl) => tbl.passwordId.equals(passwordId) & tbl.tagId.equals(tagId),
      );

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Получение количества паролей для каждого тега
  Future<Map<String, int>> getPasswordCountPerTag() async {
    final query = selectOnly(attachedDatabase.passwordTags)
      ..addColumns([
        attachedDatabase.passwordTags.tagId,
        attachedDatabase.passwordTags.passwordId.count(),
      ])
      ..groupBy([attachedDatabase.passwordTags.tagId]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.passwordTags.tagId)!:
            row.read(attachedDatabase.passwordTags.passwordId.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за тегами пароля
  Stream<List<Tag>> watchTagsForPassword(String passwordId) {
    final query = select(attachedDatabase.tags).join([
      innerJoin(
        attachedDatabase.passwordTags,
        attachedDatabase.passwordTags.tagId.equalsExp(attachedDatabase.tags.id),
      ),
    ])..where(attachedDatabase.passwordTags.passwordId.equals(passwordId));

    return query.watch().map(
      (rows) =>
          rows.map((row) => row.readTable(attachedDatabase.tags)).toList(),
    );
  }

  /// Stream для наблюдения за паролями тега
  Stream<List<Password>> watchPasswordsForTag(String tagId) {
    final query = select(attachedDatabase.passwords).join([
      innerJoin(
        attachedDatabase.passwordTags,
        attachedDatabase.passwordTags.passwordId.equalsExp(
          attachedDatabase.passwords.id,
        ),
      ),
    ])..where(attachedDatabase.passwordTags.tagId.equals(tagId));

    return query.watch().map(
      (rows) =>
          rows.map((row) => row.readTable(attachedDatabase.passwords)).toList(),
    );
  }

  /// Batch операции для множественного добавления тегов
  Future<void> addTagsToPasswordsBatch(
    List<String> passwordIds,
    List<String> tagIds,
  ) async {
    await batch((batch) {
      for (final passwordId in passwordIds) {
        for (final tagId in tagIds) {
          final companion = PasswordTagsCompanion(
            passwordId: Value(passwordId),
            tagId: Value(tagId),
          );
          batch.insert(
            attachedDatabase.passwordTags,
            companion,
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  /// Очистка всех связей для удаленных паролей или тегов
  Future<int> cleanupOrphanedRelations() async {
    final deletedCount = await customUpdate('''
      DELETE FROM password_tags
      WHERE password_id NOT IN (SELECT id FROM passwords)
         OR tag_id NOT IN (SELECT id FROM tags)
    ''');

    return deletedCount;
  }
}

/// Класс для пароля с тегами
class PasswordWithTags {
  final Password password;
  final List<Tag> tags;

  PasswordWithTags({required this.password, required this.tags});
}
