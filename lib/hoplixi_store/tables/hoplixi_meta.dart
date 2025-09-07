import 'package:drift/drift.dart';
import '../utils/uuid_generator.dart';

// Meta table for database information
@DataClassName('HoplixiMetaData')
class HoplixiMeta extends Table {
  TextColumn get id =>
      text().clientDefault(() => UuidGenerator.generate())(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description =>
      text().withLength(min: 0, max: 1024).nullable()();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  TextColumn get version => text().withDefault(const Constant('1.0.0'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'hoplixi_meta';
}
