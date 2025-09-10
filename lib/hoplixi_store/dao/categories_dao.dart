import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/categories.dart';
import '../dto/db_dto.dart';
import '../enums/entity_types.dart';
import '../utils/uuid_generator.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<HoplixiStore>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// Создание новой категории
  Future<String> createCategory(CreateCategoryDto dto) async {
    // Генерируем UUID для новой записи
    final id = UuidGenerator.generate();

    final companion = CategoriesCompanion(
      id: Value(id),
      name: Value(dto.name),
      description: Value(dto.description),
      iconId: Value(dto.iconId),
      color: Value(dto.color),
      type: Value(dto.type),
    );

    await into(
      attachedDatabase.categories,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID
    return id;
  }

  /// Обновление категории
  Future<bool> updateCategory(UpdateCategoryDto dto) async {
    final companion = CategoriesCompanion(
      id: Value(dto.id),
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      iconId: dto.iconId != null ? Value(dto.iconId) : const Value.absent(),
      color: dto.color != null ? Value(dto.color!) : const Value.absent(),
      type: dto.type != null ? Value(dto.type!) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await update(
      attachedDatabase.categories,
    ).replace(companion);
    return rowsAffected;
  }

  /// Удаление категории по ID
  Future<bool> deleteCategory(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.categories,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение категории по ID
  Future<Category?> getCategoryById(String id) async {
    final query = select(attachedDatabase.categories)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех категорий
  Future<List<Category>> getAllCategories() async {
    final query = select(attachedDatabase.categories)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Получение категорий по типу
  Future<List<Category>> getCategoriesByType(CategoryType type) async {
    final query = select(attachedDatabase.categories)
      ..where((tbl) => tbl.type.equals(type.name) | tbl.type.equals('mixed'))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Получение категории по имени
  Future<Category?> getCategoryByName(String name) async {
    final query = select(attachedDatabase.categories)
      ..where((tbl) => tbl.name.equals(name));
    return await query.getSingleOrNull();
  }

  /// Поиск категорий по имени
  Future<List<Category>> searchCategories(String searchTerm) async {
    final query = select(attachedDatabase.categories)
      ..where(
        (tbl) =>
            tbl.name.like('%$searchTerm%') |
            tbl.description.like('%$searchTerm%'),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Проверка существования категории с именем
  Future<bool> categoryExists(String name, {String? excludeId}) async {
    var query = select(attachedDatabase.categories)
      ..where((tbl) => tbl.name.equals(name));

    if (excludeId != null) {
      query = query..where((tbl) => tbl.id.equals(excludeId).not());
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Получение количества категорий
  Future<int> getCategoriesCount() async {
    final query = selectOnly(attachedDatabase.categories)
      ..addColumns([attachedDatabase.categories.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.categories.id.count()) ?? 0;
  }

  /// Получение количества категорий по типам
  Future<Map<String, int>> getCategoriesCountByType() async {
    final query = selectOnly(attachedDatabase.categories)
      ..addColumns([
        attachedDatabase.categories.type,
        attachedDatabase.categories.id.count(),
      ])
      ..groupBy([attachedDatabase.categories.type]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.categories.type)!:
            row.read(attachedDatabase.categories.id.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за всеми категориями
  Stream<List<Category>> watchAllCategories() {
    final query = select(attachedDatabase.categories)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Stream для наблюдения за категориями по типу
  Stream<List<Category>> watchCategoriesByType(CategoryType type) {
    final query = select(attachedDatabase.categories)
      ..where((tbl) => tbl.type.equals(type.name) | tbl.type.equals('mixed'))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Batch операции для создания множественных категорий
  Future<void> createCategoriesBatch(List<CreateCategoryDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = CategoriesCompanion(
          name: Value(dto.name),
          description: Value(dto.description),
          iconId: Value(dto.iconId),
          color: Value(dto.color),
          type: Value(dto.type),
        );
        batch.insert(attachedDatabase.categories, companion);
      }
    });
  }

  /// Получение категорий с подсчетом связанных элементов
  Future<List<CategoryWithItemCount>> getCategoriesWithItemCount(
    CategoryType type,
  ) async {
    // Этот метод требует кастомного запроса для подсчета связанных элементов
    // Возвращает категории с количеством паролей/заметок/TOTP в каждой

    String tableName;
    switch (type) {
      case CategoryType.password:
        tableName = 'passwords';
        break;
      case CategoryType.notes:
        tableName = 'notes';
        break;
      case CategoryType.totp:
        tableName = 'totps';
        break;
      case CategoryType.mixed:
        // Для mixed нужен более сложный запрос
        return await _getCategoriesWithMixedItemCount();
    }

    final query = customSelect(
      '''
      SELECT c.*, COALESCE(COUNT(i.id), 0) as item_count 
      FROM categories c 
      LEFT JOIN $tableName i ON c.id = i.category_id 
      WHERE c.type = ? OR c.type = 'mixed'
      GROUP BY c.id 
      ORDER BY c.name
    ''',
      variables: [Variable(type.name)],
    );

    final results = await query.get();
    return results
        .map(
          (row) => CategoryWithItemCount(
            category: Category(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              description: row.read<String?>('description'),
              iconId: row.read<String?>('icon_id'),
              color: row.read<String>('color'),
              type: CategoryType.values.firstWhere(
                (e) => e.name == row.read<String>('type'),
              ),
              createdAt: row.read<DateTime>('created_at'),
              modifiedAt: row.read<DateTime>('modified_at'),
            ),
            itemCount: row.read<int>('item_count'),
          ),
        )
        .toList();
  }

  /// Получение mixed категорий с подсчетом всех типов элементов
  Future<List<CategoryWithItemCount>> _getCategoriesWithMixedItemCount() async {
    final query = customSelect('''
      SELECT c.*, 
             COALESCE(p.count, 0) + COALESCE(n.count, 0) + COALESCE(t.count, 0) as item_count
      FROM categories c 
      LEFT JOIN (SELECT category_id, COUNT(*) as count FROM passwords GROUP BY category_id) p ON c.id = p.category_id
      LEFT JOIN (SELECT category_id, COUNT(*) as count FROM notes GROUP BY category_id) n ON c.id = n.category_id
      LEFT JOIN (SELECT category_id, COUNT(*) as count FROM totps GROUP BY category_id) t ON c.id = t.category_id
      WHERE c.type = 'mixed'
      ORDER BY c.name
    ''');

    final results = await query.get();
    return results
        .map(
          (row) => CategoryWithItemCount(
            category: Category(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              description: row.read<String?>('description'),
              iconId: row.read<String?>('icon_id'),
              color: row.read<String>('color'),
              type: CategoryType.mixed,
              createdAt: row.read<DateTime>('created_at'),
              modifiedAt: row.read<DateTime>('modified_at'),
            ),
            itemCount: row.read<int>('item_count'),
          ),
        )
        .toList();
  }
}

/// Класс для категории с подсчетом элементов
class CategoryWithItemCount {
  final Category category;
  final int itemCount;

  CategoryWithItemCount({required this.category, required this.itemCount});
}
