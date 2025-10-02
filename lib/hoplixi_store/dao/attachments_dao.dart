import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:hoplixi/hoplixi_store/utils/uuid_generator.dart';
import '../hoplixi_store.dart';
import '../tables/attachments.dart';
import '../tables/passwords.dart';
import '../tables/otps.dart';
import '../tables/notes.dart';
import '../dto/attachment_dto.dart';

part 'attachments_dao.g.dart';

@DriftAccessor(tables: [Attachments, Passwords, Otps, Notes])
class AttachmentsDao extends DatabaseAccessor<HoplixiStore>
    with _$AttachmentsDaoMixin {
  AttachmentsDao(super.db);

  /// Создание attachment из файла на диске (с путем)
  Future<String> createAttachmentFromPath(CreateAttachmentFromPath dto) async {
    final id = UuidGenerator.generate();
    final companion = AttachmentsCompanion(
      id: Value(id),
      name: Value(dto.name),
      description: Value(dto.description),
      filePath: Value(dto.filePath),
      fileData: const Value.absent(), // NULL для attachments с путем
      mimeType: Value(dto.mimeType),
      fileSize: Value(dto.fileSize),
      checksum: Value(dto.checksum),
      passwordId: Value(dto.passwordId),
      otpId: Value(dto.otpId),
      noteId: Value(dto.noteId),
    );

    await into(
      attachedDatabase.attachments,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    return id;
  }

  /// Создание attachment из данных (маленький файл)
  Future<String> createAttachmentFromData(CreateAttachmentFromData dto) async {
    final id = UuidGenerator.generate();
    final companion = AttachmentsCompanion(
      id: Value(id),
      name: Value(dto.name),
      description: Value(dto.description),
      filePath: const Value.absent(), // NULL для attachments с данными
      fileData: Value(Uint8List.fromList(dto.fileData)),
      mimeType: Value(dto.mimeType),
      fileSize: Value(dto.fileSize),
      checksum: Value(dto.checksum),
      passwordId: Value(dto.passwordId),
      otpId: Value(dto.otpId),
      noteId: Value(dto.noteId),
    );

    await into(
      attachedDatabase.attachments,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    return id;
  }

  /// Обновление attachment из файла на диске
  Future<bool> updateAttachmentFromPath(UpdateAttachmentFromPath dto) async {
    final companion = AttachmentsCompanion(
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
          ? Value(dto.fileSize)
          : const Value.absent(),
      checksum: dto.checksum != null
          ? Value(dto.checksum)
          : const Value.absent(),
      passwordId: dto.passwordId != null
          ? Value(dto.passwordId)
          : const Value.absent(),
      otpId: dto.otpId != null ? Value(dto.otpId) : const Value.absent(),
      noteId: dto.noteId != null ? Value(dto.noteId) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await (update(
      attachedDatabase.attachments,
    )..where((t) => t.id.equals(dto.id))).write(companion);

    return rowsAffected > 0;
  }

  /// Обновление attachment из данных (маленький файл)
  Future<bool> updateAttachmentFromData(UpdateAttachmentFromData dto) async {
    final companion = AttachmentsCompanion(
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      fileData: dto.fileData != null
          ? Value(Uint8List.fromList(dto.fileData!))
          : const Value.absent(),
      mimeType: dto.mimeType != null
          ? Value(dto.mimeType!)
          : const Value.absent(),
      fileSize: dto.fileSize != null
          ? Value(dto.fileSize)
          : const Value.absent(),
      checksum: dto.checksum != null
          ? Value(dto.checksum)
          : const Value.absent(),
      passwordId: dto.passwordId != null
          ? Value(dto.passwordId)
          : const Value.absent(),
      otpId: dto.otpId != null ? Value(dto.otpId) : const Value.absent(),
      noteId: dto.noteId != null ? Value(dto.noteId) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await (update(
      attachedDatabase.attachments,
    )..where((t) => t.id.equals(dto.id))).write(companion);

    return rowsAffected > 0;
  }

  /// Удаление attachment по ID
  Future<bool> deleteAttachment(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.attachments,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение attachment по ID (возвращает сырой Attachment)
  Future<Attachment?> getAttachmentById(String id) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение attachment из файла на диске по ID
  Future<AttachmentFromPathDto?> getAttachmentFromPathById(String id) async {
    final attachment = await getAttachmentById(id);
    if (attachment == null || attachment.filePath == null) return null;

    return AttachmentFromPathDto(
      id: attachment.id,
      name: attachment.name,
      description: attachment.description,
      filePath: attachment.filePath!,
      mimeType: attachment.mimeType,
      fileSize: attachment.fileSize,
      checksum: attachment.checksum,
      passwordId: attachment.passwordId,
      otpId: attachment.otpId,
      noteId: attachment.noteId,
      createdAt: attachment.createdAt,
      modifiedAt: attachment.modifiedAt,
      lastAccessed: attachment.lastAccessed,
    );
  }

  /// Получение attachment из данных по ID
  Future<AttachmentFromDataDto?> getAttachmentFromDataById(String id) async {
    final attachment = await getAttachmentById(id);
    if (attachment == null || attachment.fileData == null) return null;

    return AttachmentFromDataDto(
      id: attachment.id,
      name: attachment.name,
      description: attachment.description,
      fileData: attachment.fileData!,
      mimeType: attachment.mimeType,
      fileSize: attachment.fileSize,
      checksum: attachment.checksum,
      passwordId: attachment.passwordId,
      otpId: attachment.otpId,
      noteId: attachment.noteId,
      createdAt: attachment.createdAt,
      modifiedAt: attachment.modifiedAt,
      lastAccessed: attachment.lastAccessed,
    );
  }

  /// Получение карточки attachment (без контента)
  Future<AttachmentCardDto?> getAttachmentCardById(String id) async {
    final attachment = await getAttachmentById(id);
    if (attachment == null) return null;

    return _attachmentToCardDto(attachment);
  }

  /// Получение всех attachments для пароля
  Future<List<AttachmentCardDto>> getAttachmentsByPasswordId(
    String passwordId,
  ) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.passwordId.equals(passwordId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final attachments = await query.get();
    return _attachmentsToCardDtos(attachments);
  }

  /// Получение всех attachments для TOTP
  Future<List<AttachmentCardDto>> getAttachmentsByOtpId(String otpId) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.otpId.equals(otpId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final attachments = await query.get();
    return _attachmentsToCardDtos(attachments);
  }

  /// Получение всех attachments для заметки
  Future<List<AttachmentCardDto>> getAttachmentsByNoteId(String noteId) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.noteId.equals(noteId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final attachments = await query.get();
    return _attachmentsToCardDtos(attachments);
  }

  /// Получение всех attachments
  Future<List<AttachmentCardDto>> getAllAttachments() async {
    final query = select(attachedDatabase.attachments)
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    final attachments = await query.get();
    return _attachmentsToCardDtos(attachments);
  }

  /// Поиск attachments по имени
  Future<List<AttachmentCardDto>> searchAttachments(String searchTerm) async {
    final query = select(attachedDatabase.attachments)
      ..where(
        (tbl) =>
            tbl.name.like('%$searchTerm%') |
            tbl.description.like('%$searchTerm%'),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    final attachments = await query.get();
    return _attachmentsToCardDtos(attachments);
  }

  /// Получение недавно просмотренных attachments
  Future<List<AttachmentCardDto>> getRecentlyAccessedAttachments({
    int limit = 10,
  }) async {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.lastAccessed.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastAccessed)])
      ..limit(limit);
    final attachments = await query.get();
    return _attachmentsToCardDtos(attachments);
  }

  /// Обновление времени последнего доступа
  Future<void> updateLastAccessed(String id) async {
    await (update(
      attachedDatabase.attachments,
    )..where((tbl) => tbl.id.equals(id))).write(
      AttachmentsCompanion(
        lastAccessed: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Получение количества attachments
  Future<int> getAttachmentsCount() async {
    final query = selectOnly(attachedDatabase.attachments)
      ..addColumns([attachedDatabase.attachments.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.attachments.id.count()) ?? 0;
  }

  /// Получение количества attachments для конкретного пароля
  Future<int> getAttachmentsCountByPasswordId(String passwordId) async {
    final query = selectOnly(attachedDatabase.attachments)
      ..addColumns([attachedDatabase.attachments.id.count()])
      ..where(attachedDatabase.attachments.passwordId.equals(passwordId));
    final result = await query.getSingle();
    return result.read(attachedDatabase.attachments.id.count()) ?? 0;
  }

  /// Получение количества attachments для конкретного OTP
  Future<int> getAttachmentsCountByOtpId(String otpId) async {
    final query = selectOnly(attachedDatabase.attachments)
      ..addColumns([attachedDatabase.attachments.id.count()])
      ..where(attachedDatabase.attachments.otpId.equals(otpId));
    final result = await query.getSingle();
    return result.read(attachedDatabase.attachments.id.count()) ?? 0;
  }

  /// Получение количества attachments для конкретной заметки
  Future<int> getAttachmentsCountByNoteId(String noteId) async {
    final query = selectOnly(attachedDatabase.attachments)
      ..addColumns([attachedDatabase.attachments.id.count()])
      ..where(attachedDatabase.attachments.noteId.equals(noteId));
    final result = await query.getSingle();
    return result.read(attachedDatabase.attachments.id.count()) ?? 0;
  }

  /// Получение attachments по типу (путь или данные)
  Future<List<AttachmentCardDto>> getAttachmentsByType(
    AttachmentType type,
  ) async {
    final query = type == AttachmentType.fromPath
        ? (select(attachedDatabase.attachments)
            ..where((tbl) => tbl.filePath.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]))
        : (select(attachedDatabase.attachments)
            ..where((tbl) => tbl.fileData.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]));

    final attachments = await query.get();
    return _attachmentsToCardDtos(attachments);
  }

  /// Stream для наблюдения за всеми attachments
  Stream<List<AttachmentCardDto>> watchAllAttachments() {
    final query = select(attachedDatabase.attachments)
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch().asyncMap(
      (attachments) => _attachmentsToCardDtos(attachments),
    );
  }

  /// Stream для наблюдения за attachments пароля
  Stream<List<AttachmentCardDto>> watchAttachmentsByPasswordId(
    String passwordId,
  ) {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.passwordId.equals(passwordId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().asyncMap(
      (attachments) => _attachmentsToCardDtos(attachments),
    );
  }

  /// Stream для наблюдения за attachments OTP
  Stream<List<AttachmentCardDto>> watchAttachmentsByOtpId(String otpId) {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.otpId.equals(otpId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().asyncMap(
      (attachments) => _attachmentsToCardDtos(attachments),
    );
  }

  /// Stream для наблюдения за attachments заметки
  Stream<List<AttachmentCardDto>> watchAttachmentsByNoteId(String noteId) {
    final query = select(attachedDatabase.attachments)
      ..where((tbl) => tbl.noteId.equals(noteId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().asyncMap(
      (attachments) => _attachmentsToCardDtos(attachments),
    );
  }

  /// Batch операции для создания множественных attachments из пути
  Future<void> createAttachmentsFromPathBatch(
    List<CreateAttachmentFromPath> dtos,
  ) async {
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
          otpId: Value(dto.otpId),
          noteId: Value(dto.noteId),
        );
        batch.insert(attachedDatabase.attachments, companion);
      }
    });
  }

  /// Batch операции для создания множественных attachments из данных
  Future<void> createAttachmentsFromDataBatch(
    List<CreateAttachmentFromData> dtos,
  ) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = AttachmentsCompanion(
          name: Value(dto.name),
          description: Value(dto.description),
          fileData: Value(Uint8List.fromList(dto.fileData)),
          mimeType: Value(dto.mimeType),
          fileSize: Value(dto.fileSize),
          checksum: Value(dto.checksum),
          passwordId: Value(dto.passwordId),
          otpId: Value(dto.otpId),
          noteId: Value(dto.noteId),
        );
        batch.insert(attachedDatabase.attachments, companion);
      }
    });
  }

  /// Удаление всех attachments для пароля
  Future<int> deleteAttachmentsByPasswordId(String passwordId) async {
    final rowsAffected = await (delete(
      attachedDatabase.attachments,
    )..where((tbl) => tbl.passwordId.equals(passwordId))).go();
    return rowsAffected;
  }

  /// Удаление всех attachments для OTP
  Future<int> deleteAttachmentsByOtpId(String otpId) async {
    final rowsAffected = await (delete(
      attachedDatabase.attachments,
    )..where((tbl) => tbl.otpId.equals(otpId))).go();
    return rowsAffected;
  }

  /// Удаление всех attachments для заметки
  Future<int> deleteAttachmentsByNoteId(String noteId) async {
    final rowsAffected = await (delete(
      attachedDatabase.attachments,
    )..where((tbl) => tbl.noteId.equals(noteId))).go();
    return rowsAffected;
  }

  // ==================== HELPER МЕТОДЫ ДЛЯ МАППИНГА ====================

  /// Преобразование Attachment в AttachmentCardDto
  AttachmentCardDto _attachmentToCardDto(Attachment attachment) {
    AttachmentType? type;
    if (attachment.filePath != null) {
      type = AttachmentType.fromPath;
    } else if (attachment.fileData != null) {
      type = AttachmentType.fromData;
    }

    return AttachmentCardDto(
      id: attachment.id,
      name: attachment.name,
      description: attachment.description,
      mimeType: attachment.mimeType,
      type: type,
      fileSize: attachment.fileSize,
      checksum: attachment.checksum,
      passwordId: attachment.passwordId,
      otpId: attachment.otpId,
      noteId: attachment.noteId,
      createdAt: attachment.createdAt,
      modifiedAt: attachment.modifiedAt,
      lastAccessed: attachment.lastAccessed,
    );
  }

  /// Batch преобразование List<Attachment> в List<AttachmentCardDto>
  Future<List<AttachmentCardDto>> _attachmentsToCardDtos(
    List<Attachment> attachments,
  ) async {
    return attachments.map(_attachmentToCardDto).toList();
  }
}
