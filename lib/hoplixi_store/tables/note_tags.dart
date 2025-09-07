import 'package:drift/drift.dart';
import 'notes.dart';
import 'tags.dart';

@DataClassName('NoteTag')
class NoteTags extends Table {
  TextColumn get noteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {noteId, tagId};

  @override
  String get tableName => 'note_tags';
}
