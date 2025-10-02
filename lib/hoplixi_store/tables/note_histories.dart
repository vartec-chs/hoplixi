import 'package:drift/drift.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import '../utils/uuid_generator.dart';

@DataClassName('NoteHistory')
class NoteHistories extends Table {
  TextColumn get id =>
      text().clientDefault(() => UuidGenerator.generate())(); // UUID v4
  TextColumn get originalNoteId => text()(); // ID of original note
  TextColumn get action => textEnum<ActionInHistory>().withLength(
    min: 1,
    max: 50,
  )(); // 'deleted', 'modified'
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description =>
      text().nullable()(); // Description at time of action
  TextColumn get deltaJson =>
      text().nullable()(); // Quill Delta JSON at time of action
  TextColumn get content =>
      text().nullable()(); // Content (nullable for privacy)
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName =>
      text().nullable()(); // Category name at time of action
  TextColumn get tags => text().nullable()(); // JSON array of tag names
  BoolColumn get wasFavorite => boolean().nullable()();
  BoolColumn get wasPinned => boolean().nullable()();
  DateTimeColumn get originalCreatedAt => dateTime().nullable()();
  DateTimeColumn get originalModifiedAt => dateTime().nullable()();
  DateTimeColumn get actionAt => dateTime().clientDefault(
    () => DateTime.now(),
  )(); // When action was performed

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'note_histories';
}
