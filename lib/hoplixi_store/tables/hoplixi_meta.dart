import 'package:drift/drift.dart';

// Meta table for database information
class HoplixiMeta extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description =>
      text().withLength(min: 0, max: 1024).nullable()();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get version => text().withDefault(const Constant('1.0.0'))();
}
