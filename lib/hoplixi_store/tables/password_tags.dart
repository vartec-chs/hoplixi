import 'package:drift/drift.dart';
import 'passwords.dart';
import 'tags.dart';

@DataClassName('PasswordTag')
class PasswordTags extends Table {
  TextColumn get passwordId => text().references(Passwords, #id)();
  TextColumn get tagId => text().references(Tags, #id)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {passwordId, tagId};

  @override
  String get tableName => 'password_tags';
}
