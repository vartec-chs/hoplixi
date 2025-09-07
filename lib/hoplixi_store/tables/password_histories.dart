import 'package:drift/drift.dart';

@DataClassName('PasswordHistory')
class PasswordHistories extends Table {
  TextColumn get id => text().clientDefault(() => '')(); // UUID v4
  TextColumn get originalPasswordId => text()(); // ID of original password
  TextColumn get action =>
      text().withLength(min: 1, max: 50)(); // 'deleted', 'modified'
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get password =>
      text().nullable()(); // Encrypted password (nullable for privacy)
  TextColumn get url => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get login => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName =>
      text().nullable()(); // Category name at time of action
  TextColumn get tags => text().nullable()(); // JSON array of tag names
  DateTimeColumn get originalCreatedAt => dateTime().nullable()();
  DateTimeColumn get originalModifiedAt => dateTime().nullable()();
  DateTimeColumn get actionAt => dateTime().clientDefault(
    () => DateTime.now(),
  )(); // When action was performed

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'password_histories';
}
