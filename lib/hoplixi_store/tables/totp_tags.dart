import 'package:drift/drift.dart';
import 'totps.dart';
import 'tags.dart';

@DataClassName('TotpTag')
class TotpTags extends Table {
  TextColumn get totpId =>
      text().references(Totps, #id, onDelete: KeyAction.cascade)();
  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {totpId, tagId};

  @override
  String get tableName => 'totp_tags';
}
