import 'package:drift/drift.dart';

@DataClassName('Tag')
class Tags extends Table {
  TextColumn get id => text().clientDefault(() => '')(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get color => text().nullable()(); // Hex color code
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'tags';
}
