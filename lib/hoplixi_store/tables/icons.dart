import 'package:drift/drift.dart';

@DataClassName('IconData')
class Icons extends Table {
  TextColumn get id => text().clientDefault(() => '')(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get type =>
      text().withLength(min: 1, max: 100)(); // MIME type: png, jpg, svg, etc.
  BlobColumn get data => blob()(); // Binary image data
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'icons';
}
