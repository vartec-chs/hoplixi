import 'package:drift/drift.dart';
import 'passwords.dart';
import 'totps.dart';
import 'notes.dart';
import '../utils/uuid_generator.dart';

//TODO: attachments — CHECK и поведение при удалении родителя
// Проблема: в схеме CHECK требует ровно одного NOT NULL из (password_id, totp_id, note_id). Если при удалении родителя вы будете делать ON DELETE SET NULL — CHECK нарушится. Поэтому нужно либо удалять attachments вместе с родителем (ON DELETE CASCADE), либо менять логику CHECK.
// Рекомендация: сделать FK в attachments с ON DELETE CASCADE, чтобы вложения удалялись вместе с родителем.

@DataClassName('Attachment')
class Attachments extends Table {
  TextColumn get id =>
      text().clientDefault(() => UuidGenerator.generate())(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get filePath => text()(); // Path to the file on disk
  TextColumn get mimeType => text()(); // MIME type of the file
  IntColumn get fileSize => integer()(); // File size in bytes
  TextColumn get checksum =>
      text().nullable()(); // File checksum for integrity verification

  // Foreign keys - an attachment can belong to password, TOTP, or note (but only one)
  TextColumn get passwordId => text().nullable().references(
    Passwords,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get totpId =>
      text().nullable().references(Totps, #id, onDelete: KeyAction.cascade)();
  TextColumn get noteId =>
      text().nullable().references(Notes, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'attachments';

  @override
  List<String> get customConstraints => [
    // Constraint: attachment must belong to exactly one entity (password, totp, or note)
    'CHECK ((' +
        '(password_id IS NOT NULL AND totp_id IS NULL AND note_id IS NULL) OR ' +
        '(password_id IS NULL AND totp_id IS NOT NULL AND note_id IS NULL) OR ' +
        '(password_id IS NULL AND totp_id IS NULL AND note_id IS NOT NULL)' +
        '))',
  ];
}
