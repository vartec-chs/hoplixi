import 'package:drift/drift.dart';
import 'categories.dart';

@DataClassName('Password')
class Passwords extends Table {
  TextColumn get id => text().clientDefault(() => '')(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get password => text()(); // Encrypted password
  TextColumn get url => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get login => text().nullable()(); // Username
  TextColumn get email => text().nullable()(); // Email
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
  )(); // Foreign key to categories
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastAccessed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'passwords';

  @override
  List<String> get tableConstraints => [
    // Constraint: must have either login OR email OR both
    'CHECK (login IS NOT NULL OR email IS NOT NULL)',
  ];
}
