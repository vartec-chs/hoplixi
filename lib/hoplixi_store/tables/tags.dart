import 'package:drift/drift.dart';
import '../enums/entity_types.dart';
import '../utils/uuid_generator.dart';

@DataClassName('Tag')
class Tags extends Table {
  TextColumn get id =>
      text().clientDefault(() => UuidGenerator.generate())(); // UUID v4
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get color => text().nullable()(); // Hex color code
  TextColumn get type => textEnum<TagType>()(); // notes, password, totp, mixed
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'tags';
}
