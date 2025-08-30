import 'package:drift/drift.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart';
import 'package:hoplixi/hoplixi_store/tables/categories.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<HoplixiStore>
    with _$CategoriesDaoMixin {
  CategoriesDao(HoplixiStore db) : super(db);

  Future<List<Category>> getAllCategories() async {
    final result = await select(categories).get();
    return result.cast<Category>();
  }

  Future<Category?> getCategoryById(int id) async {
    return await (select(
      categories,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<int> createCategory({
    required String name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final now = DateTime.now();
    final id = await into(categories).insert(
      CategoriesCompanion.insert(
        name: name,
        description: Value(description),
        icon: Value(icon),
        color: Value(color),
        createdAt: now,
        modifiedAt: now,
      ),
    );

    await db.updateModificationTime();
    return id;
  }

  Future<bool> updateCategory(
    int id, {
    String? name,
    String? description,
    String? icon,
    String? color,
  }) async {
    final updateCompanion = CategoriesCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      description: Value(description),
      icon: Value(icon),
      color: Value(color),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await (update(
      categories,
    )..where((tbl) => tbl.id.equals(id))).write(updateCompanion);

    if (rowsAffected > 0) {
      await db.updateModificationTime();
    }

    return rowsAffected > 0;
  }

  Future<bool> deleteCategory(int id) async {
    final rowsAffected = await (delete(
      categories,
    )..where((tbl) => tbl.id.equals(id))).go();

    if (rowsAffected > 0) {
      await db.updateModificationTime();
    }

    return rowsAffected > 0;
  }

  Future<List<Category>> searchCategories(String query) async {
    return await (select(categories)
          ..where((tbl) => tbl.name.like('%$query%'))
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]))
        .get();
  }
}
