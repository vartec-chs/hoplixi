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

  /// Получение категорий с пагинацией
  Future<PaginatedCategoriesResult> getCategoriesPaginated({
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    CategoryType? type,
    CategorySortBy sortBy = CategorySortBy.name,
    bool ascending = true,
  }) async {
    // Валидация параметров
    if (page < 1) page = 1;
    if (pageSize < 1) pageSize = 20;
    if (pageSize > 100) pageSize = 100; // Максимальный размер страницы

    final offset = (page - 1) * pageSize;

    // Построение WHERE условий
    final whereConditions = <String>[];
    final variables = <Variable>[];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      whereConditions.add('(name LIKE ? OR description LIKE ?)');
      variables.add(Variable('%$searchTerm%'));
      variables.add(Variable('%$searchTerm%'));
    }

    if (type != null) {
      whereConditions.add('(type = ? OR type = ?)');
      variables.add(Variable(type.name));
      variables.add(Variable('mixed'));
    }

    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    // Определение сортировки
    String orderByClause;
    switch (sortBy) {
      case CategorySortBy.name:
        orderByClause = ascending ? 'ORDER BY name ASC' : 'ORDER BY name DESC';
        break;
      case CategorySortBy.type:
        orderByClause = ascending
            ? 'ORDER BY type ASC, name ASC'
            : 'ORDER BY type DESC, name ASC';
        break;
      case CategorySortBy.createdAt:
        orderByClause = ascending
            ? 'ORDER BY created_at ASC'
            : 'ORDER BY created_at DESC';
        break;
      case CategorySortBy.modifiedAt:
        orderByClause = ascending
            ? 'ORDER BY modified_at ASC'
            : 'ORDER BY modified_at DESC';
        break;
    }

    // Получение общего количества записей
    final countQuery = customSelect(
      'SELECT COUNT(*) as total FROM categories $whereClause',
      variables: variables,
    );

    final countResult = await countQuery.getSingle();
    final totalItems = countResult.read<int>('total');

    // Получение данных для текущей страницы
    final dataQuery = customSelect(
      'SELECT * FROM categories $whereClause $orderByClause LIMIT ? OFFSET ?',
      variables: [...variables, Variable(pageSize), Variable(offset)],
    );

    final dataResults = await dataQuery.get();
    final categories = dataResults
        .map(
          (row) => Category(
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
        )
        .toList();

    // Расчет информации о пагинации
    final totalPages = (totalItems / pageSize).ceil();
    final hasNextPage = page < totalPages;
    final hasPreviousPage = page > 1;

    return PaginatedCategoriesResult(
      categories: categories,
      pagination: PaginationInfo(
        currentPage: page,
        pageSize: pageSize,
        totalItems: totalItems,
        totalPages: totalPages,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
        isFirstPage: page == 1,
        isLastPage: page == totalPages || totalPages == 0,
        startIndex: totalItems > 0 ? offset + 1 : 0,
        endIndex: totalItems > 0 ? (offset + categories.length) : 0,
      ),
    );
  }

  /// Поиск категорий с пагинацией
  Future<PaginatedCategoriesResult> searchCategoriesPaginated({
    required String searchTerm,
    int page = 1,
    int pageSize = 20,
    CategorySortBy sortBy = CategorySortBy.name,
    bool ascending = true,
  }) async {
    return getCategoriesPaginated(
      page: page,
      pageSize: pageSize,
      searchTerm: searchTerm,
      sortBy: sortBy,
      ascending: ascending,
    );
  }

  /// Получение категорий по типу с пагинацией
  Future<PaginatedCategoriesResult> getCategoriesByTypePaginated({
    required CategoryType type,
    int page = 1,
    int pageSize = 20,
    CategorySortBy sortBy = CategorySortBy.name,
    bool ascending = true,
  }) async {
    return getCategoriesPaginated(
      page: page,
      pageSize: pageSize,
      type: type,
      sortBy: sortBy,
      ascending: ascending,
    );
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

/// Enum для сортировки категорий
enum CategorySortBy { name, type, createdAt, modifiedAt }

/// Класс для информации о пагинации
class PaginationInfo {
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final bool isFirstPage;
  final bool isLastPage;
  final int startIndex;
  final int endIndex;

  const PaginationInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.isFirstPage,
    required this.isLastPage,
    required this.startIndex,
    required this.endIndex,
  });

  /// Создание информации о пагинации из параметров
  factory PaginationInfo.fromParams({
    required int currentPage,
    required int pageSize,
    required int totalItems,
  }) {
    final totalPages = (totalItems / pageSize).ceil();
    final hasNextPage = currentPage < totalPages;
    final hasPreviousPage = currentPage > 1;
    final offset = (currentPage - 1) * pageSize;

    return PaginationInfo(
      currentPage: currentPage,
      pageSize: pageSize,
      totalItems: totalItems,
      totalPages: totalPages,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
      isFirstPage: currentPage == 1,
      isLastPage: currentPage == totalPages || totalPages == 0,
      startIndex: totalItems > 0 ? offset + 1 : 0,
      endIndex: totalItems > 0
          ? offset +
                (currentPage * pageSize <= totalItems
                    ? pageSize
                    : totalItems % pageSize)
          : 0,
    );
  }

  @override
  String toString() {
    return 'PaginationInfo(currentPage: $currentPage, pageSize: $pageSize, totalItems: $totalItems, totalPages: $totalPages)';
  }
}

/// Результат пагинированного запроса категорий
class PaginatedCategoriesResult {
  final List<Category> categories;
  final PaginationInfo pagination;

  const PaginatedCategoriesResult({
    required this.categories,
    required this.pagination,
  });

  /// Проверка, есть ли данные
  bool get hasData => categories.isNotEmpty;

  /// Проверка, пустой ли результат
  bool get isEmpty => categories.isEmpty;

  @override
  String toString() {
    return 'PaginatedCategoriesResult(categories: ${categories.length}, pagination: $pagination)';
  }
}
