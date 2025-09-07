import 'package:drift/drift.dart';
import 'passwords.dart';
import 'categories.dart';
import '../utils/uuid_generator.dart';

@DataClassName('Totp')
class Totps extends Table {
  TextColumn get id =>
      text().clientDefault(() => UuidGenerator.generate())(); // UUID v4
  TextColumn get passwordId => text().nullable().references(
    Passwords,
    #id,
  )(); // Foreign key to passwords (optional)
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().nullable()();
  TextColumn get secretCipher => text()(); // Encrypted TOTP secret
  TextColumn get algorithm => text().withDefault(
    const Constant('SHA1'),
  )(); // HMAC algorithm (SHA1, SHA256, SHA512)
  IntColumn get digits => integer().withDefault(
    const Constant(6),
  )(); // Number of digits in TOTP code (usually 6 or 8)
  IntColumn get period => integer().withDefault(
    const Constant(30),
  )(); // Time period in seconds (usually 30)
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
  )(); // Foreign key to categories
  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))(); // Favorite flag
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get lastAccessed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'totps';
}
