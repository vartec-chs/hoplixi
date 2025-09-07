import 'package:drift/drift.dart';
import 'icons.dart';
import '../enums/entity_types.dart';
import '../utils/uuid_generator.dart';

@DataClassName('Category')
class Categories extends Table {
  TextColumn get id =>
      text().clientDefault(() => UuidGenerator.generate())(); // UUID v4
  TextColumn get name => text().unique().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get iconId => text().nullable().references(
    Icons,
    #id,
    onDelete: KeyAction.setNull,
  )(); // Foreign key to icons table
  TextColumn get color =>
      text().withDefault(const Constant('FFFFFF'))(); // Hex color code
  TextColumn get type =>
      textEnum<CategoryType>()(); // notes, password, totp, mixed
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get modifiedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'categories';
}
