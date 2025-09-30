import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/otp_tags.dart';
import '../tables/otps.dart';
import '../tables/tags.dart';
import '../enums/entity_types.dart';

part 'otp_tags_dao.g.dart';

@DriftAccessor(tables: [OtpTags, Otps, Tags])
class OtpTagsDao extends DatabaseAccessor<HoplixiStore>
    with _$OtpTagsDaoMixin {
  OtpTagsDao(super.db);

  /// Добавление тега к TOTP
  Future<void> addTagToTotp(String totpId, String tagId) async {
    final companion = OtpTagsCompanion(
      otpId: Value(totpId),
      tagId: Value(tagId),
    );

    await into(
      attachedDatabase.otpTags,
    ).insert(companion, mode: InsertMode.insertOrIgnore);
  }

  /// Удаление тега у TOTP
  Future<bool> removeTagFromTotp(String totpId, String tagId) async {
    final rowsAffected =
        await (delete(attachedDatabase.otpTags)..where(
              (tbl) => tbl.otpId.equals(totpId) & tbl.tagId.equals(tagId),
            ))
            .go();
    return rowsAffected > 0;
  }

  /// Получение всех тегов для TOTP
  Future<List<Tag>> getTagsForTotp(String totpId) async {
    final query = select(attachedDatabase.tags).join([
      innerJoin(
        attachedDatabase.otpTags,
        attachedDatabase.otpTags.tagId.equalsExp(attachedDatabase.tags.id),
      ),
    ])..where(attachedDatabase.otpTags.otpId.equals(totpId));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.tags)).toList();
  }

  /// Получение всех TOTP для тега
  Future<List<Otp>> getTotpsForTag(String tagId) async {
    final query = select(attachedDatabase.otps).join([
      innerJoin(
        attachedDatabase.otpTags,
        attachedDatabase.otpTags.otpId.equalsExp(attachedDatabase.otps.id),
      ),
    ])..where(attachedDatabase.otpTags.tagId.equals(tagId));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.otps)).toList();
  }

  /// Получение OTP с тегами
  Future<List<OtpWithTags>> getOtpsWithTags() async {
    final otpsQuery = select(attachedDatabase.otps);
    final otps = await otpsQuery.get();

    final List<OtpWithTags> result = [];

    for (final otp in otps) {
      final tags = await getTagsForTotp(otp.id);
      result.add(OtpWithTags(otp: otp, tags: tags));
    }

    return result;
  }

  /// Получение TOTP по множественным тегам (AND условие)
  Future<List<Otp>> getTotpsByTags(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    String placeholders = tagIds.map((_) => '?').join(',');

    final query = customSelect(
      '''
      SELECT t.* FROM totps t
      WHERE t.id IN (
        SELECT tt.otp_id
        FROM totp_tags tt
        WHERE tt.tag_id IN ($placeholders)
        GROUP BY tt.otp_id
        HAVING COUNT(DISTINCT tt.tag_id) = ?
      )
      ORDER BY t.modified_at DESC
    ''',
      variables: [...tagIds.map((id) => Variable(id)), Variable(tagIds.length)],
    );

    final results = await query.get();
    return results
        .map(
          (row) => Otp(
            id: row.read<String>('id'),
            passwordId: row.read<String?>('password_id'),
            
            type: OtpType.values.firstWhere(
              (e) => e.name == row.read<String>('type'),
            ),
            issuer: row.read<String?>('issuer'),
            accountName: row.read<String?>('account_name'),
            secret: row.read<String>('secret'),
            algorithm: row.read<AlgorithmOtp>('algorithm'),
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

  /// Получение OTP по любому из тегов (OR условие)
  Future<List<Otp>> getOtpsByAnyTag(List<String> tagIds) async {
    if (tagIds.isEmpty) return [];

    final query = select(attachedDatabase.otps).join([
      innerJoin(
        attachedDatabase.otpTags,
        attachedDatabase.otpTags.otpId.equalsExp(attachedDatabase.otps.id),
      ),
    ])..where(attachedDatabase.otpTags.tagId.isIn(tagIds));

    final results = await query.get();
    return results.map((row) => row.readTable(attachedDatabase.otps)).toList();
  }

  /// Замена всех тегов у OTP
  Future<void> replaceTotpTags(String otpId, List<String> tagIds) async {
    await transaction(() async {
      // Удаляем все существующие теги
      await (delete(
        attachedDatabase.otpTags,
      )..where((tbl) => tbl.otpId.equals(otpId))).go();

      // Добавляем новые теги
      for (final tagId in tagIds) {
        await addTagToTotp(otpId, tagId);
      }
    });
  }

  /// Проверка наличия тега у TOTP
  Future<bool> totpHasTag(String totpId, String tagId) async {
    final query = select(attachedDatabase.otpTags)
      ..where((tbl) => tbl.otpId.equals(totpId) & tbl.tagId.equals(tagId));

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Получение количества TOTP для каждого тега
  Future<Map<String, int>> getTotpCountPerTag() async {
    final query = selectOnly(attachedDatabase.otpTags)
      ..addColumns([
        attachedDatabase.otpTags.tagId,
        attachedDatabase.otpTags.otpId.count(),
      ])
      ..groupBy([attachedDatabase.otpTags.tagId]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.otpTags.tagId)!:
            row.read(attachedDatabase.otpTags.otpId.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за тегами TOTP
  Stream<List<Tag>> watchTagsForTotp(String totpId) {
    final query = select(attachedDatabase.tags).join([
      innerJoin(
        attachedDatabase.otpTags,
        attachedDatabase.otpTags.tagId.equalsExp(attachedDatabase.tags.id),
      ),
    ])..where(attachedDatabase.otpTags.otpId.equals(totpId));

    return query.watch().map(
      (rows) =>
          rows.map((row) => row.readTable(attachedDatabase.tags)).toList(),
    );
  }

  /// Stream для наблюдения за TOTP тега
  Stream<List<Otp>> watchTotpsForTag(String tagId) {
    final query = select(attachedDatabase.otps).join([
      innerJoin(
        attachedDatabase.otpTags,
        attachedDatabase.otpTags.otpId.equalsExp(attachedDatabase.otps.id),
      ),
    ])..where(attachedDatabase.otpTags.tagId.equals(tagId));

    return query.watch().map(
      (rows) =>
          rows.map((row) => row.readTable(attachedDatabase.otps)).toList(),
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
          final companion = OtpTagsCompanion(
            otpId: Value(totpId),
            tagId: Value(tagId),
          );
          batch.insert(
            attachedDatabase.otpTags,
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
      WHERE otp_id NOT IN (SELECT id FROM totps)
         OR tag_id NOT IN (SELECT id FROM tags)
    ''');

    return deletedCount;
  }
}

/// Класс для OTP с тегами
class OtpWithTags {
  final Otp otp;
  final List<Tag> tags;

  OtpWithTags({required this.otp, required this.tags});
}
