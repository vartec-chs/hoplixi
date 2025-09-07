import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/totp_tags.dart';
import '../tables/totps.dart';
import '../tables/tags.dart';
import '../enums/entity_types.dart';

part 'totp_tags_dao.g.dart';

@DriftAccessor(tables: [TotpTags, Totps, Tags])
class TotpTagsDao extends DatabaseAccessor<HoplixiStore>
    with _$TotpTagsDaoMixin {
  TotpTagsDao(super.db);

  /// Добавление тега к TOTP
  Future<void> addTagToTotp(String totpId, String tagId) async {
    final companion = TotpTagsCompanion(
      totpId: Value(totpId),
      tagId: Value(tagId),
    );

    await into(
      attachedDatabase.totpTags,
    ).insert(companion, mode: InsertMode.insertOrIgnore);
  }

  /// Удаление тега у TOTP
  Future<bool> removeTagFromTotp(String totpId, String tagId) async {
    final rowsAffected =
        await (delete(attachedDatabase.totpTags)..where(
              (tbl) => tbl.totpId.equals(totpId) & tbl.tagId.equals(tagId),
            ))
            .go();
    return rowsAffected > 0;
  }

  /// Получение всех тегов для TOTP
  Future<List<Tag>> getTagsForTotp(String totpId) async {
    final query = select(attachedDatabase.tags).join([
      innerJoin(
        attachedDatabase.totpTags,
        attachedDatabase.totpTags.tagId.equalsExp(attachedDatabase.tags.id),
      ),
    ])..where(attachedDatabase.totpTags.totpId.equals(totpId));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.tags)).toList();
  }

  /// Получение всех TOTP для тега
  Future<List<Totp>> getTotpsForTag(String tagId) async {
    final query = select(attachedDatabase.totps).join([
      innerJoin(
        attachedDatabase.totpTags,
        attachedDatabase.totpTags.totpId.equalsExp(attachedDatabase.totps.id),
      ),
    ])..where(attachedDatabase.totpTags.tagId.equals(tagId));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.totps)).toList();
  }

  /// Получение TOTP с тегами
  Future<List<TotpWithTags>> getTotpsWithTags() async {
    final totpsQuery = select(attachedDatabase.totps);
    final totps = await totpsQuery.get();

    final List<TotpWithTags> result = [];

    for (final totp in totps) {
      final tags = await getTagsForTotp(totp.id);
      result.add(TotpWithTags(totp: totp, tags: tags));
    }

    return result;
  }

  /// Получение TOTP по множественным тегам (AND условие)
  Future<List<Totp>> getTotpsByTags(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    String placeholders = tagIds.map((_) => '?').join(',');

    final query = customSelect(
      '''
      SELECT t.* FROM totps t
      WHERE t.id IN (
        SELECT tt.totp_id
        FROM totp_tags tt
        WHERE tt.tag_id IN ($placeholders)
        GROUP BY tt.totp_id
        HAVING COUNT(DISTINCT tt.tag_id) = ?
      )
      ORDER BY t.modified_at DESC
    ''',
      variables: [...tagIds.map((id) => Variable(id)), Variable(tagIds.length)],
    );

    final results = await query.get();
    return results
        .map(
          (row) => Totp(
            id: row.read<String>('id'),
            passwordId: row.read<String?>('password_id'),
            name: row.read<String>('name'),
            description: row.read<String?>('description'),
            type: OtpType.values.firstWhere(
              (e) => e.name == row.read<String>('type'),
            ),
            issuer: row.read<String?>('issuer'),
            accountName: row.read<String?>('account_name'),
            secretNonce: row.read<String>('secret_nonce'),
            secretCipher: row.read<String>('secret_cipher'),
            secretTag: row.read<String>('secret_tag'),
            algorithm: row.read<String>('algorithm'),
            digits: row.read<int>('digits'),
            period: row.read<int>('period'),
            counter: row.read<int?>('counter'),
            categoryId: row.read<String?>('category_id'),
            isFavorite: row.read<bool>('is_favorite'),
            createdAt: row.read<DateTime>('created_at'),
            modifiedAt: row.read<DateTime>('modified_at'),
            lastAccessed: row.read<DateTime?>('last_accessed'),
          ),
        )
        .toList();
  }

  /// Получение TOTP по любому из тегов (OR условие)
  Future<List<Totp>> getTotpsByAnyTag(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    final query = select(attachedDatabase.totps).join([
      innerJoin(
        attachedDatabase.totpTags,
        attachedDatabase.totpTags.totpId.equalsExp(attachedDatabase.totps.id),
      ),
    ])..where(attachedDatabase.totpTags.tagId.isIn(tagIds));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.totps)).toList();
  }

  /// Замена всех тегов у TOTP
  Future<void> replaceTotpTags(String totpId, List<String> tagIds) async {
    await transaction(() async {
      // Удаляем все существующие теги
      await (delete(
        attachedDatabase.totpTags,
      )..where((tbl) => tbl.totpId.equals(totpId))).go();

      // Добавляем новые теги
      for (final tagId in tagIds) {
        await addTagToTotp(totpId, tagId);
      }
    });
  }

  /// Проверка наличия тега у TOTP
  Future<bool> totpHasTag(String totpId, String tagId) async {
    final query = select(attachedDatabase.totpTags)
      ..where((tbl) => tbl.totpId.equals(totpId) & tbl.tagId.equals(tagId));

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Получение количества TOTP для каждого тега
  Future<Map<String, int>> getTotpCountPerTag() async {
    final query = selectOnly(attachedDatabase.totpTags)
      ..addColumns([
        attachedDatabase.totpTags.tagId,
        attachedDatabase.totpTags.totpId.count(),
      ])
      ..groupBy([attachedDatabase.totpTags.tagId]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.totpTags.tagId)!:
            row.read(attachedDatabase.totpTags.totpId.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за тегами TOTP
  Stream<List<Tag>> watchTagsForTotp(String totpId) {
    final query = select(attachedDatabase.tags).join([
      innerJoin(
        attachedDatabase.totpTags,
        attachedDatabase.totpTags.tagId.equalsExp(attachedDatabase.tags.id),
      ),
    ])..where(attachedDatabase.totpTags.totpId.equals(totpId));

    return query.watch().map(
      (rows) =>
          rows.map((row) => row.readTable(attachedDatabase.tags)).toList(),
    );
  }

  /// Stream для наблюдения за TOTP тега
  Stream<List<Totp>> watchTotpsForTag(String tagId) {
    final query = select(attachedDatabase.totps).join([
      innerJoin(
        attachedDatabase.totpTags,
        attachedDatabase.totpTags.totpId.equalsExp(attachedDatabase.totps.id),
      ),
    ])..where(attachedDatabase.totpTags.tagId.equals(tagId));

    return query.watch().map(
      (rows) =>
          rows.map((row) => row.readTable(attachedDatabase.totps)).toList(),
    );
  }

  /// Batch операции для множественного добавления тегов
  Future<void> addTagsToTotpsBatch(
    List<String> totpIds,
    List<String> tagIds,
  ) async {
    await batch((batch) {
      for (final totpId in totpIds) {
        for (final tagId in tagIds) {
          final companion = TotpTagsCompanion(
            totpId: Value(totpId),
            tagId: Value(tagId),
          );
          batch.insert(
            attachedDatabase.totpTags,
            companion,
            mode: InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  /// Очистка всех связей для удаленных TOTP или тегов
  Future<int> cleanupOrphanedRelations() async {
    final deletedCount = await customUpdate('''
      DELETE FROM totp_tags
      WHERE totp_id NOT IN (SELECT id FROM totps)
         OR tag_id NOT IN (SELECT id FROM tags)
    ''');

    return deletedCount;
  }
}

/// Класс для TOTP с тегами
class TotpWithTags {
  final Totp totp;
  final List<Tag> tags;

  TotpWithTags({required this.totp, required this.tags});
}
