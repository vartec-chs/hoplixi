import 'package:drift/drift.dart';
import '../utils/uuid_generator.dart';

@DataClassName('OtpHistory')
class OtpHistories extends Table {
  TextColumn get id =>
      text().clientDefault(() => UuidGenerator.generate())(); // UUID v4
  TextColumn get originalOtpId => text()(); // ID of original OTP
  TextColumn get action =>
      text().withLength(min: 1, max: 50)(); // 'deleted', 'modified'

  // OTP authentication fields
  TextColumn get type => text().nullable()(); // TOTP or HOTP
  TextColumn get issuer => text().nullable()(); // Service name
  TextColumn get accountName => text().nullable()(); // Account identifier

  // Secret encryption fields (nullable for privacy)
  TextColumn get secret => text()();
  TextColumn get notes => text().nullable()();

  // OTP configuration
  TextColumn get algorithm => text().nullable()();
  IntColumn get digits => integer().nullable()();
  IntColumn get period => integer().nullable()();
  IntColumn get counter => integer().nullable()(); // For HOTP

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
  String get tableName => 'otp_histories';
}
