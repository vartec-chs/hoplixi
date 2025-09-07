import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/attachments.dart';
import '../dto/db_dto.dart';

part 'attachments_dao.g.dart';

@DriftAccessor(tables: [Attachments])
class AttachmentsDao extends DatabaseAccessor<HoplixiStore>
    with _$AttachmentsDaoMixin {
  AttachmentsDao(super.db);

  /// Создание нового вложения
  Future<String> createAttachment(CreateAttachmentDto dto) async {
    final companion = AttachmentsCompanion(
      name: Value(dto.name),
      description: Value(dto.description),
      filePath: Value(dto.filePath),
      mimeType: Value(dto.mimeType),
      fileSize: Value(dto.fileSize),
      checksum: Value(dto.checksum),
      passwordId: Value(dto.passwordId),
      totpId: Value(dto.totpId),
      noteId: Value(dto.noteId),
    );

    await into(
      attachedDatabase.attachments,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID из companion
    return companion.id.value;
  }

  /// Обновление вложения
  Future<bool> updateAttachment(UpdateAttachmentDto dto) async {
    final companion = AttachmentsCompanion(
      id: Value(dto.id),
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      filePath: dto.filePath != null
          ? Value(dto.filePath!)
          : const Value.absent(),
      mimeType: dto.mimeType != null
          ? Value(dto.mimeType!)
          : const Value.absent(),
      fileSize: dto.fileSize != null
          ? Value(dto.fileSize!)
          : const Value.absent(),
      checksum: dto.checksum != null
          ? Value(dto.checksum)
          : const Value.absent(),
      passwordId: dto.passwordId != null
          ? Value(dto.passwordId)
          : const Value.absent(),
      totpId: dto.totpId != null ? Value(dto.totpId) : const Value.absent(),
      noteId: dto.noteId != null ? Value(dto.noteId) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await update(
      attachedDatabase.attachments,
    ).replace(companion);
    return rowsAffected;
  }

  /// Удаление вложения по ID
  Future<bool> deleteAttachment(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.attachments,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение вложения по ID
  Future<Attachment?> getAttachmentById(String id) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех вложений
  Future<List<Attachment>> getAllAttachments() async {
    final query = select(attachedDatabase.attachments)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return await query.get();
  }

  /// Получение вложений для пароля
  Future<List<Attachment>> getAttachmentsForPassword(String passwordId) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.passwordId.equals(passwordId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return await query.get();
  }

  /// Получение вложений для TOTP
  Future<List<Attachment>> getAttachmentsForTotp(String totpId) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.totpId.equals(totpId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return await query.get();
  }

  /// Получение вложений для заметки
  Future<List<Attachment>> getAttachmentsForNote(String noteId) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.noteId.equals(noteId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return await query.get();
  }

  /// Получение вложений по MIME типу
  Future<List<Attachment>> getAttachmentsByMimeType(String mimeType) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.mimeType.equals(mimeType))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return await query.get();
  }

  /// Поиск вложений по имени
  Future<List<Attachment>> searchAttachments(String searchTerm) async {
    final query = select(attachedDatabase.attachments)
      ..where(
        (tbl) =>
            tbl.name.like('%$searchTerm%') |
            tbl.description.like('%$searchTerm%') |
            tbl.mimeType.like('%$searchTerm%'),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return await query.get();
  }

  /// Получение вложений размером больше указанного (в байтах)
  Future<List<Attachment>> getAttachmentsLargerThan(int sizeInBytes) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.fileSize.isBiggerThanValue(sizeInBytes))
      ..orderBy([(t) => OrderingTerm.desc(t.fileSize)]);
    return await query.get();
  }

  /// Получение общего размера всех вложений
  Future<int> getTotalAttachmentsSize() async {
    final query = selectOnly(attachedDatabase.attachments)
      ..addColumns([attachedDatabase.attachments.fileSize.sum()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.attachments.fileSize.sum()) ?? 0;
  }

  /// Получение количества вложений
  Future<int> getAttachmentsCount() async {
    final query = selectOnly(attachedDatabase.attachments)
      ..addColumns([attachedDatabase.attachments.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.attachments.id.count()) ?? 0;
  }

  /// Получение количества вложений по типу родителя
  Future<Map<String, int>> getAttachmentsCountByParentType() async {
    final passwordCount =
        await (selectOnly(attachedDatabase.attachments)
              ..addColumns([attachedDatabase.attachments.id.count()])
              ..where(attachedDatabase.attachments.passwordId.isNotNull()))
            .getSingle();

    final totpCount =
        await (selectOnly(attachedDatabase.attachments)
              ..addColumns([attachedDatabase.attachments.id.count()])
              ..where(attachedDatabase.attachments.totpId.isNotNull()))
            .getSingle();

    final noteCount =
        await (selectOnly(attachedDatabase.attachments)
              ..addColumns([attachedDatabase.attachments.id.count()])
              ..where(attachedDatabase.attachments.noteId.isNotNull()))
            .getSingle();

    return {
      'password':
          passwordCount.read(attachedDatabase.attachments.id.count()) ?? 0,
      'totp': totpCount.read(attachedDatabase.attachments.id.count()) ?? 0,
      'note': noteCount.read(attachedDatabase.attachments.id.count()) ?? 0,
    };
  }

  /// Получение количества вложений по MIME типам
  Future<Map<String, int>> getAttachmentsCountByMimeType() async {
    final query = selectOnly(attachedDatabase.attachments)
      ..addColumns([
        attachedDatabase.attachments.mimeType,
        attachedDatabase.attachments.id.count(),
      ])
      ..groupBy([attachedDatabase.attachments.mimeType]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.attachments.mimeType)!:
            row.read(attachedDatabase.attachments.id.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за всеми вложениями
  Stream<List<Attachment>> watchAllAttachments() {
    final query = select(attachedDatabase.attachments)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  /// Stream для наблюдения за вложениями пароля
  Stream<List<Attachment>> watchAttachmentsForPassword(String passwordId) {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.passwordId.equals(passwordId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  /// Stream для наблюдения за вложениями TOTP
  Stream<List<Attachment>> watchAttachmentsForTotp(String totpId) {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.totpId.equals(totpId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  /// Stream для наблюдения за вложениями заметки
  Stream<List<Attachment>> watchAttachmentsForNote(String noteId) {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.noteId.equals(noteId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  /// Batch операции для создания множественных вложений
  Future<void> createAttachmentsBatch(List<CreateAttachmentDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = AttachmentsCompanion(
          name: Value(dto.name),
          description: Value(dto.description),
          filePath: Value(dto.filePath),
          mimeType: Value(dto.mimeType),
          fileSize: Value(dto.fileSize),
          checksum: Value(dto.checksum),
          passwordId: Value(dto.passwordId),
          totpId: Value(dto.totpId),
          noteId: Value(dto.noteId),
        );
        batch.insert(attachedDatabase.attachments, companion);
      }
    });
  }

  /// Проверка целостности файла по контрольной сумме
  Future<bool> verifyFileIntegrity(
    String attachmentId,
    String actualChecksum,
  ) async {
    final attachment = await getAttachmentById(attachmentId);
    if (attachment == null) return false;

    return attachment.checksum == actualChecksum;
  }

  /// Получение вложений с проблемами (файл не найден, неверная контрольная сумма и т.д.)
  Future<List<AttachmentWithIssue>> getAttachmentsWithIssues() async {
    // Этот метод требует дополнительной логики для проверки файлов
    // Здесь показан базовый пример
    final attachments = await getAllAttachments();
    final List<AttachmentWithIssue> issueList = [];

    for (final attachment in attachments) {
      // Проверка существования файла должна быть реализована через файловый сервис
      // Здесь просто пример структуры
      if (attachment.checksum == null || attachment.checksum!.isEmpty) {
        issueList.add(
          AttachmentWithIssue(
            attachment: attachment,
            issueType: AttachmentIssueType.missingChecksum,
            issueDescription: 'Отсутствует контрольная сумма файла',
          ),
        );
      }
    }

    return issueList;
  }

  /// Очистка записей о вложениях без соответствующих файлов
  Future<int> cleanupOrphanedAttachments() async {
    // Этот метод требует интеграции с файловым сервисом
    // для проверки существования файлов
    // Здесь показана базовая структура

    final query = customSelect('''
      SELECT id, file_path 
      FROM attachments
    ''');

    final attachments = await query.get();
    int deletedCount = 0;

    for (final row in attachments) {
      final id = row.read<String>('id');
      final filePath = row.read<String>('file_path');

      // Здесь должна быть проверка существования файла
      // if (!fileExists(filePath)) {
      //   await deleteAttachment(id);
      //   deletedCount++;
      // }
    }

    return deletedCount;
  }
}

/// Типы проблем с вложениями
enum AttachmentIssueType {
  missingFile,
  corruptedFile,
  missingChecksum,
  checksumMismatch,
  permissionDenied,
}

/// Класс для вложения с проблемой
class AttachmentWithIssue {
  final Attachment attachment;
  final AttachmentIssueType issueType;
  final String issueDescription;

  AttachmentWithIssue({
    required this.attachment,
    required this.issueType,
    required this.issueDescription,
  });
}
