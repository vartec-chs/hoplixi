import 'package:drift/drift.dart';
import '../hoplixi_store.dart';
import '../tables/icons.dart';
import '../dto/db_dto.dart';
import '../enums/entity_types.dart';
import '../utils/uuid_generator.dart';

part 'icons_dao.g.dart';

@DriftAccessor(tables: [Icons])
class IconsDao extends DatabaseAccessor<HoplixiStore> with _$IconsDaoMixin {
  IconsDao(super.db);

  /// Создание новой иконки
  Future<String> createIcon(CreateIconDto dto) async {
    final iconId = UuidGenerator.generate();

    final companion = IconsCompanion(
      id: Value(iconId),
      name: Value(dto.name),
      type: Value(dto.type), // Drift автоматически конвертирует enum в строку
      data: Value(dto.data),
    );

    await into(
      attachedDatabase.icons,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID
    return iconId;
  }

  /// Обновление иконки
  Future<bool> updateIcon(UpdateIconDto dto) async {
    final companion = IconsCompanion(
      id: Value(dto.id),
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      type: dto.type != null ? Value(dto.type!) : const Value.absent(),
      data: dto.data != null ? Value(dto.data!) : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await update(
      attachedDatabase.icons,
    ).replace(companion);
    return rowsAffected;
  }

  /// Удаление иконки по ID
  Future<bool> deleteIcon(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.icons,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение иконки по ID
  Future<IconData?> getIconById(String id) async {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех иконок
  Future<List<IconData>> getAllIcons() async {
    final query = select(attachedDatabase.icons)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Получение иконок по типу
  Future<List<IconData>> getIconsByType(IconType type) async {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.type.equals(type.name))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Получение иконки по имени
  Future<IconData?> getIconByName(String name) async {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.name.equals(name));
    return await query.getSingleOrNull();
  }

  /// Поиск иконок по имени
  Future<List<IconData>> searchIcons(String searchTerm) async {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.name.like('%$searchTerm%'))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return await query.get();
  }

  /// Проверка существования иконки с именем
  Future<bool> iconExists(String name, {String? excludeId}) async {
    var query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.name.equals(name));

    if (excludeId != null) {
      query = query..where((tbl) => tbl.id.equals(excludeId).not());
    }

    final result = await query.getSingleOrNull();
    return result != null;
  }

  /// Получение количества иконок
  Future<int> getIconsCount() async {
    final query = selectOnly(attachedDatabase.icons)
      ..addColumns([attachedDatabase.icons.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.icons.id.count()) ?? 0;
  }

  /// Получение количества иконок по типам
  Future<Map<String, int>> getIconsCountByType() async {
    final query = selectOnly(attachedDatabase.icons)
      ..addColumns([
        attachedDatabase.icons.type,
        attachedDatabase.icons.id.count(),
      ])
      ..groupBy([attachedDatabase.icons.type]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.icons.type)!:
            row.read(attachedDatabase.icons.id.count()) ?? 0,
    };
  }

  /// Получение размера всех иконок в байтах
  Future<int> getTotalIconsSize() async {
    final query = customSelect('''
      SELECT SUM(LENGTH(data)) as total_size 
      FROM icons
    ''');

    final result = await query.getSingle();
    return result.read<int?>('total_size') ?? 0;
  }

  // =============================================================================
  // МЕТОДЫ ДЛЯ ПАГИНАЦИИ
  // =============================================================================

  /// Получение иконок с пагинацией
  Future<List<IconData>> getIconsPaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
    IconType? typeFilter,
    IconSortBy sortBy = IconSortBy.name,
    bool ascending = true,
  }) async {
    final offset = page * pageSize;

    String whereClause = '';
    List<Variable> variables = [];

    // Построение WHERE клаузулы
    List<String> conditions = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('name LIKE ?');
      variables.add(Variable('%$searchQuery%'));
    }

    if (typeFilter != null) {
      conditions.add('type = ?');
      variables.add(Variable(typeFilter.name));
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    // Определение сортировки
    String orderClause = _buildOrderClause(sortBy, ascending);

    final query = customSelect(
      '''
      SELECT * FROM icons 
      $whereClause
      $orderClause
      LIMIT ? OFFSET ?
      ''',
      variables: [...variables, Variable(pageSize), Variable(offset)],
    );

    final results = await query.get();
    return results.map(_mapRowToIconData).toList();
  }

  /// Получение общего количества иконок с фильтрами
  Future<int> getIconsCountFiltered({
    String? searchQuery,
    IconType? typeFilter,
  }) async {
    String whereClause = '';
    List<Variable> variables = [];

    // Построение WHERE клаузулы
    List<String> conditions = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('name LIKE ?');
      variables.add(Variable('%$searchQuery%'));
    }

    if (typeFilter != null) {
      conditions.add('type = ?');
      variables.add(Variable(typeFilter.name));
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final query = customSelect('''
      SELECT COUNT(*) as count FROM icons 
      $whereClause
      ''', variables: variables);

    final result = await query.getSingle();
    return result.read<int>('count');
  }

  /// Получение информации о пагинации
  Future<PaginationInfo> getPaginationInfo({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
    IconType? typeFilter,
  }) async {
    final totalCount = await getIconsCountFiltered(
      searchQuery: searchQuery,
      typeFilter: typeFilter,
    );

    final totalPages = (totalCount / pageSize).ceil();
    final hasNextPage = page < totalPages - 1;
    final hasPreviousPage = page > 0;
    final isFirstPage = page == 0;
    final isLastPage = page >= totalPages - 1;

    return PaginationInfo(
      currentPage: page,
      pageSize: pageSize,
      totalItems: totalCount,
      totalPages: totalPages,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
      isFirstPage: isFirstPage,
      isLastPage: isLastPage,
      startIndex: page * pageSize,
      endIndex: ((page + 1) * pageSize - 1).clamp(0, totalCount - 1),
    );
  }

  /// Получение диапазона страниц для отображения в пагинаторе
  List<int> getPageRange({
    required int currentPage,
    required int totalPages,
    int maxVisiblePages = 5,
  }) {
    if (totalPages <= maxVisiblePages) {
      return List.generate(totalPages, (index) => index);
    }

    final half = maxVisiblePages ~/ 2;
    int start = currentPage - half;
    int end = currentPage + half;

    if (start < 0) {
      start = 0;
      end = maxVisiblePages - 1;
    } else if (end >= totalPages) {
      end = totalPages - 1;
      start = totalPages - maxVisiblePages;
    }

    return List.generate(end - start + 1, (index) => start + index);
  }

  /// Stream для наблюдения за иконками с пагинацией
  Stream<List<IconData>> watchIconsPaginated({
    int page = 0,
    int pageSize = 20,
    String? searchQuery,
    IconType? typeFilter,
    IconSortBy sortBy = IconSortBy.name,
    bool ascending = true,
  }) {
    final offset = page * pageSize;

    String whereClause = '';
    final conditions = <String>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('name LIKE \'%$searchQuery%\'');
    }

    if (typeFilter != null) {
      conditions.add('type = \'${typeFilter.name}\'');
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    // Определение сортировки
    String orderClause = _buildOrderClause(sortBy, ascending);

    final query = customSelect('''
      SELECT * FROM icons 
      $whereClause
      $orderClause
      LIMIT $pageSize OFFSET $offset
      ''');

    return query.watch().map(
      (results) => results.map(_mapRowToIconData).toList(),
    );
  }

  /// Быстрый переход к странице с определенной иконкой
  Future<int> getPageForIcon({
    required String iconId,
    int pageSize = 20,
    String? searchQuery,
    IconType? typeFilter,
    IconSortBy sortBy = IconSortBy.name,
    bool ascending = true,
  }) async {
    String whereClause = '';
    List<Variable> variables = [];

    // Построение WHERE клаузулы
    List<String> conditions = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('name LIKE ?');
      variables.add(Variable('%$searchQuery%'));
    }

    if (typeFilter != null) {
      conditions.add('type = ?');
      variables.add(Variable(typeFilter.name));
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    // Определение сортировки
    String orderClause = _buildOrderClause(sortBy, ascending);

    final query = customSelect('''
      SELECT COUNT(*) as position FROM icons 
      $whereClause
      AND ${_buildComparisonClause(sortBy, ascending, iconId)}
      $orderClause
      ''', variables: variables);

    final result = await query.getSingle();
    final position = result.read<int>('position');

    return position ~/ pageSize;
  }

  /// Получение соседних иконок (предыдущая и следующая)
  Future<AdjacentIcons> getAdjacentIcons({
    required String iconId,
    String? searchQuery,
    IconType? typeFilter,
    IconSortBy sortBy = IconSortBy.name,
    bool ascending = true,
  }) async {
    // Сначала находим текущую иконку
    final currentIcon = await getIconById(iconId);
    if (currentIcon == null) {
      return AdjacentIcons(previous: null, next: null);
    }

    String whereClause = '';
    List<Variable> baseVariables = [];

    // Построение базовой WHERE клаузулы
    List<String> conditions = [];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      conditions.add('name LIKE ?');
      baseVariables.add(Variable('%$searchQuery%'));
    }

    if (typeFilter != null) {
      conditions.add('type = ?');
      baseVariables.add(Variable(typeFilter.name));
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    // Получение предыдущей иконки
    final prevQuery = customSelect('''
      SELECT * FROM icons 
      $whereClause
      ${whereClause.isEmpty ? 'WHERE' : 'AND'} ${_buildComparisonClause(sortBy, !ascending, iconId)}
      ${_buildOrderClause(sortBy, !ascending)}
      LIMIT 1
      ''', variables: baseVariables);

    // Получение следующей иконки
    final nextQuery = customSelect('''
      SELECT * FROM icons 
      $whereClause
      ${whereClause.isEmpty ? 'WHERE' : 'AND'} ${_buildComparisonClause(sortBy, ascending, iconId)}
      ${_buildOrderClause(sortBy, ascending)}
      LIMIT 1
      ''', variables: baseVariables);

    final prevResults = await prevQuery.get();
    final nextResults = await nextQuery.get();

    return AdjacentIcons(
      previous: prevResults.isNotEmpty
          ? _mapRowToIconData(prevResults.first)
          : null,
      next: nextResults.isNotEmpty
          ? _mapRowToIconData(nextResults.first)
          : null,
    );
  }

  // =============================================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ДЛЯ ПАГИНАЦИИ
  // =============================================================================

  String _buildOrderClause(IconSortBy sortBy, bool ascending) {
    final direction = ascending ? 'ASC' : 'DESC';

    switch (sortBy) {
      case IconSortBy.name:
        return 'ORDER BY name $direction';
      case IconSortBy.type:
        return 'ORDER BY type $direction, name ASC';
      case IconSortBy.size:
        return 'ORDER BY LENGTH(data) $direction, name ASC';
      case IconSortBy.createdAt:
        return 'ORDER BY created_at $direction, name ASC';
      case IconSortBy.modifiedAt:
        return 'ORDER BY modified_at $direction, name ASC';
    }
  }

  String _buildComparisonClause(
    IconSortBy sortBy,
    bool ascending,
    String iconId,
  ) {
    final operator = ascending ? '>' : '<';

    switch (sortBy) {
      case IconSortBy.name:
        return 'name $operator (SELECT name FROM icons WHERE id = \'$iconId\')';
      case IconSortBy.type:
        return '''(type $operator (SELECT type FROM icons WHERE id = '$iconId') 
                  OR (type = (SELECT type FROM icons WHERE id = '$iconId') 
                      AND name $operator (SELECT name FROM icons WHERE id = '$iconId')))''';
      case IconSortBy.size:
        return '''(LENGTH(data) $operator (SELECT LENGTH(data) FROM icons WHERE id = '$iconId') 
                  OR (LENGTH(data) = (SELECT LENGTH(data) FROM icons WHERE id = '$iconId') 
                      AND name $operator (SELECT name FROM icons WHERE id = '$iconId')))''';
      case IconSortBy.createdAt:
        return '''(created_at $operator (SELECT created_at FROM icons WHERE id = '$iconId') 
                  OR (created_at = (SELECT created_at FROM icons WHERE id = '$iconId') 
                      AND name $operator (SELECT name FROM icons WHERE id = '$iconId')))''';
      case IconSortBy.modifiedAt:
        return '''(modified_at $operator (SELECT modified_at FROM icons WHERE id = '$iconId') 
                  OR (modified_at = (SELECT modified_at FROM icons WHERE id = '$iconId') 
                      AND name $operator (SELECT name FROM icons WHERE id = '$iconId')))''';
    }
  }

  IconData _mapRowToIconData(QueryRow row) {
    return IconData(
      id: row.read<String>('id'),
      name: row.read<String>('name'),
      type: IconType.values.firstWhere(
        (e) => e.name == row.read<String>('type'),
      ),
      data: row.read<Uint8List>('data'),
      createdAt: row.read<DateTime>('created_at'),
      modifiedAt: row.read<DateTime>('modified_at'),
    );
  }

  /// Получение иконок с размером больше указанного (в байтах)
  Future<List<IconWithSize>> getIconsLargerThan(int sizeInBytes) async {
    final query = customSelect(
      '''
      SELECT *, LENGTH(data) as size 
      FROM icons 
      WHERE LENGTH(data) > ?
      ORDER BY size DESC
    ''',
      variables: [Variable(sizeInBytes)],
    );

    final results = await query.get();
    return results
        .map(
          (row) => IconWithSize(
            icon: IconData(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              type: IconType.values.firstWhere(
                (e) => e.name == row.read<String>('type'),
              ),
              data: row.read<Uint8List>('data'),
              createdAt: row.read<DateTime>('created_at'),
              modifiedAt: row.read<DateTime>('modified_at'),
            ),
            sizeInBytes: row.read<int>('size'),
          ),
        )
        .toList();
  }

  /// Stream для наблюдения за всеми иконками
  Stream<List<IconData>> watchAllIcons() {
    final query = select(attachedDatabase.icons)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Stream для наблюдения за иконками по типу
  Stream<List<IconData>> watchIconsByType(IconType type) {
    final query = select(attachedDatabase.icons)
      ..where((tbl) => tbl.type.equals(type.name))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Batch операции для создания множественных иконок
  Future<void> createIconsBatch(List<CreateIconDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = IconsCompanion(
          name: Value(dto.name),
          type: Value(dto.type),
          data: Value(dto.data),
        );
        batch.insert(attachedDatabase.icons, companion);
      }
    });
  }

  /// Получение иконок с информацией об использовании
  Future<List<IconWithUsage>> getIconsWithUsage() async {
    final query = customSelect('''
      SELECT i.*, COUNT(c.icon_id) as usage_count
      FROM icons i
      LEFT JOIN categories c ON i.id = c.icon_id
      GROUP BY i.id
      ORDER BY usage_count DESC, i.name ASC
    ''');

    final results = await query.get();
    return results
        .map(
          (row) => IconWithUsage(
            icon: IconData(
              id: row.read<String>('id'),
              name: row.read<String>('name'),
              type: IconType.values.firstWhere(
                (e) => e.name == row.read<String>('type'),
              ),
              data: row.read<Uint8List>('data'),
              createdAt: row.read<DateTime>('created_at'),
              modifiedAt: row.read<DateTime>('modified_at'),
            ),
            usageCount: row.read<int>('usage_count'),
          ),
        )
        .toList();
  }

  /// Получение неиспользуемых иконок
  Future<List<IconData>> getUnusedIcons() async {
    final query = customSelect('''
      SELECT i.*
      FROM icons i
      LEFT JOIN categories c ON i.id = c.icon_id
      WHERE c.icon_id IS NULL
      ORDER BY i.name
    ''');

    final results = await query.get();
    return results
        .map(
          (row) => IconData(
            id: row.read<String>('id'),
            name: row.read<String>('name'),
            type: IconType.values.firstWhere(
              (e) => e.name == row.read<String>('type'),
            ),
            data: row.read<Uint8List>('data'),
            createdAt: row.read<DateTime>('created_at'),
            modifiedAt: row.read<DateTime>('modified_at'),
          ),
        )
        .toList();
  }

  /// Очистка неиспользуемых иконок
  Future<int> cleanupUnusedIcons() async {
    final result = await customUpdate('''
      DELETE FROM icons 
      WHERE id NOT IN (
        SELECT DISTINCT icon_id 
        FROM categories 
        WHERE icon_id IS NOT NULL
      )
    ''');

    return result;
  }
}

/// Класс для иконки с размером
class IconWithSize {
  final IconData icon;
  final int sizeInBytes;

  IconWithSize({required this.icon, required this.sizeInBytes});
}

/// Класс для иконки с информацией об использовании
class IconWithUsage {
  final IconData icon;
  final int usageCount;

  IconWithUsage({required this.icon, required this.usageCount});
}

/// Enum для сортировки иконок
enum IconSortBy { name, type, size, createdAt, modifiedAt }

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

  /// Получение номеров элементов на текущей странице
  String get itemsRange {
    if (totalItems == 0) return '0 из 0';
    final start = startIndex + 1;
    final end = (endIndex + 1).clamp(0, totalItems);
    return '$start-$end из $totalItems';
  }

  /// Процент заполнения текущей страницы
  double get pageFilledPercentage {
    if (pageSize == 0) return 0.0;
    final itemsOnPage = (endIndex - startIndex + 1).clamp(0, pageSize);
    return itemsOnPage / pageSize;
  }

  @override
  String toString() {
    return 'PaginationInfo(page: $currentPage, totalPages: $totalPages, '
        'items: $itemsRange)';
  }
}

/// Класс для соседних иконок (предыдущая и следующая)
class AdjacentIcons {
  final IconData? previous;
  final IconData? next;

  const AdjacentIcons({required this.previous, required this.next});

  bool get hasPrevious => previous != null;
  bool get hasNext => next != null;

  @override
  String toString() {
    return 'AdjacentIcons(hasPrevious: $hasPrevious, hasNext: $hasNext)';
  }
}
