import 'package:drift/drift.dart';
import '../utils/uuid_generator.dart';

@DataClassName('TotpHistory')
class TotpHistories extends Table {
  TextColumn get id =>
      text().clientDefault(() => UuidGenerator.generate())(); // UUID v4
  TextColumn get originalTotpId => text()(); // ID of original TOTP
  TextColumn get action =>
      text().withLength(min: 1, max: 50)(); // 'deleted', 'modified'
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get secretCipher =>
      text().nullable()(); // Encrypted TOTP secret (nullable for privacy)
  TextColumn get algorithm => text().nullable()();
  IntColumn get digits => integer().nullable()();
  IntColumn get period => integer().nullable()();
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
  String get tableName => 'totp_histories';
}
