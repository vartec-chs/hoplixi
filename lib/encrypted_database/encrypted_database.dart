import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hoplixi/encrypted_database/dao/categories_dao.dart';
import 'tables/categories.dart';
import 'tables/database_meta.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

part 'encrypted_database.g.dart';

@DriftDatabase(tables: [DatabaseMeta, Categories], daos: [CategoriesDao])
class EncryptedDatabase extends _$EncryptedDatabase {
  EncryptedDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> updateModificationTime() async {
    await update(
      databaseMeta,
    ).write(DatabaseMetaCompanion(modifiedAt: Value(DateTime.now())));
  }

  Future<DatabaseMetaData> getDatabaseMeta() async {
    return await select(databaseMeta).getSingle();
  }

  Future<void> closeDatabase() async {
    await close();
  }
}
