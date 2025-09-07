import 'package:drift/drift.dart';
import 'passwords.dart';
import 'categories.dart';
import '../utils/uuid_generator.dart';
import '../enums/entity_types.dart';

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

  // OTP authentication fields
  TextColumn get type => textEnum<OtpType>().withDefault(
    const Constant('totp'),
  )(); // Type: TOTP or HOTP
  TextColumn get issuer =>
      text().nullable()(); // Service name (e.g., "Google", "GitHub")
  TextColumn get accountName =>
      text().nullable()(); // Account identifier (e.g., email, username)

  // Secret encryption fields (separated for better security)
  TextColumn get secretNonce => text()(); // Nonce for encryption
  TextColumn get secretCipher => text()(); // Encrypted TOTP/HOTP secret
  TextColumn get secretTag => text()(); // Authentication tag for encryption

  // OTP configuration
  TextColumn get algorithm => text().withDefault(
    const Constant('SHA1'),
  )(); // HMAC algorithm (SHA1, SHA256, SHA512)
  IntColumn get digits => integer().withDefault(
    const Constant(6),
  )(); // Number of digits in OTP code (usually 6 or 8)
  IntColumn get period => integer().withDefault(
    const Constant(30),
  )(); // Time period in seconds for TOTP (usually 30)
  IntColumn get counter =>
      integer().nullable()(); // Counter for HOTP (only used when type = HOTP)

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

  @override
  List<String> get customConstraints => [
    // Constraint: counter is required for HOTP, but should be null for TOTP
    'CHECK ((type = \'hotp\' AND counter IS NOT NULL) OR (type = \'totp\' AND counter IS NULL))',
  ];
}
