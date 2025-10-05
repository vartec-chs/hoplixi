import 'package:drift/drift.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/filter/password_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import '../../hoplixi_store.dart';
import '../../tables/passwords.dart';
import '../../tables/categories.dart';
import '../../tables/tags.dart';
import '../../tables/password_tags.dart';

part 'password_filter_dao.g.dart';

/// Порог для часто используемых паролей
const int kFrequentUsedThreshold = 100;

/// Вспомогательный класс для данных пароля из строки результата
class _PasswordRowData {
  final String id;
  final String name;
  final String? description;
  final String? login;
  final String? email;
  final String? url;
  final String? categoryId;
  final bool isFavorite;
  final int usedCount;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? lastAccessed;

  const _PasswordRowData({
    required this.id,
    required this.name,
    this.description,
    this.login,
    this.email,
    this.url,
    this.categoryId,
    required this.isFavorite,
    required this.usedCount,
    required this.isArchived,
    required this.createdAt,
    required this.modifiedAt,
    this.lastAccessed,
  });
}

@DriftAccessor(tables: [Passwords, Categories, Tags, PasswordTags])
class PasswordFilterDao extends DatabaseAccessor<HoplixiStore>
    with _$PasswordFilterDaoMixin {
  PasswordFilterDao(super.db);

  /// Главный метод для получения отфильтрованных паролей
  /// Возвращает Future<List<CardPasswordDto>> согласно требованиям
  Future<List<CardPasswordDto>> getFilteredPasswords(
    PasswordFilter filter,
  ) async {
    try {
      // Если нет активных ограничений, возвращаем все пароли с базовой сортировкой
      if (!filter.hasActiveConstraints) {
        return await _getAllPasswordsWithBasicFilter(filter.base);
      }

      // Определяем нужны ли сложные JOIN'ы
      final needsTagJoin = filter.base.tagIds.isNotEmpty;

      // Для сложных фильтров с тегами используем кастомный SQL
      if (needsTagJoin) {
        return await _getPasswordsWithTagFilter(filter);
      }

      // Для простых фильтров используем стандартные Drift запросы
      return await _getPasswordsWithSimpleFilter(filter);
    } catch (e) {
      logError(
        'Ошибка получения отфильтрованных паролей',
        error: e,
        tag: 'PasswordFilterDao',
      );
      // В случае ошибки возвращаем пустой список
      return <CardPasswordDto>[];
    }
  }

  /// Подсчет количества отфильтрованных паролей
  Future<int> countFilteredPasswords(PasswordFilter filter) async {
    try {
      if (!filter.hasActiveConstraints) {
        return await _countAllPasswords();
      }

      if (filter.base.tagIds.isNotEmpty) {
        return await _countPasswordsWithTagFilter(filter);
      }

      return await _countPasswordsWithSimpleFilter(filter);
    } catch (e) {
      return 0;
    }
  }

  /// Stream для наблюдения за отфильтрованными паролями
  Stream<List<CardPasswordDto>> watchFilteredPasswords(PasswordFilter filter) {
    // Для простых случаев используем стандартные Drift streams
    if (!filter.hasActiveConstraints) {
      return _watchAllPasswordsWithBasicFilter(filter.base);
    }

    // Для сложных случаев возвращаем периодически обновляемый stream
    return Stream.periodic(
      const Duration(milliseconds: 500),
    ).asyncMap((_) => getFilteredPasswords(filter)).distinct();
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Получение всех паролей с базовой фильтрацией
  Future<List<CardPasswordDto>> _getAllPasswordsWithBasicFilter(
    BaseFilter baseFilter,
  ) async {
    final query = selectOnly(attachedDatabase.passwords)
      ..addColumns([
        attachedDatabase.passwords.id,
        attachedDatabase.passwords.name,
        attachedDatabase.passwords.description,
        attachedDatabase.passwords.login,
        attachedDatabase.passwords.email,
        attachedDatabase.passwords.url,
        attachedDatabase.passwords.categoryId,
        attachedDatabase.passwords.isFavorite,
        attachedDatabase.passwords.usedCount,
        attachedDatabase.passwords.isArchived,
        attachedDatabase.passwords.createdAt,
        attachedDatabase.passwords.modifiedAt,
        attachedDatabase.passwords.lastAccessed,
      ]);

    // Применяем базовые фильтры
    _applyBaseFilters(query, baseFilter);

    // Применяем сортировку
    _applySorting(query, null, baseFilter.sortDirection);

    // Применяем пагинацию
    if (baseFilter.limit != null && baseFilter.limit! > 0) {
      query.limit(baseFilter.limit!, offset: baseFilter.offset ?? 0);
    }

    final results = await query.get();
    return await _convertResultsToCardDtos(results);
  }

  /// Получение паролей с простой фильтрацией (без тегов)
  Future<List<CardPasswordDto>> _getPasswordsWithSimpleFilter(
    PasswordFilter filter,
  ) async {
    final query = selectOnly(attachedDatabase.passwords)
      ..addColumns([
        attachedDatabase.passwords.id,
        attachedDatabase.passwords.name,
        attachedDatabase.passwords.description,
        attachedDatabase.passwords.login,
        attachedDatabase.passwords.email,
        attachedDatabase.passwords.url,
        attachedDatabase.passwords.categoryId,
        attachedDatabase.passwords.isFavorite,
        attachedDatabase.passwords.usedCount,
        attachedDatabase.passwords.isArchived,
        attachedDatabase.passwords.createdAt,
        attachedDatabase.passwords.modifiedAt,
        attachedDatabase.passwords.lastAccessed,
      ]);

    // Применяем все фильтры
    _applyAllFilters(query, filter);

    // Применяем сортировку
    _applySorting(query, filter.sortField, filter.base.sortDirection);

    // Применяем пагинацию
    if (filter.base.limit != null && filter.base.limit! > 0) {
      query.limit(filter.base.limit!, offset: filter.base.offset ?? 0);
    }

    final results = await query.get();
    return await _convertResultsToCardDtos(results);
  }

  /// Получение паролей с фильтрацией по тегам (кастомный SQL)
  Future<List<CardPasswordDto>> _getPasswordsWithTagFilter(
    PasswordFilter filter,
  ) async {
    final whereConditions = <String>[];
    final variables = <Variable>[];

    // Базовые условия
    _buildBaseWhereConditions(filter.base, whereConditions, variables);

    // Условия PasswordFilter
    _buildPasswordWhereConditions(filter, whereConditions, variables);

    // Условие для тегов
    if (filter.base.tagIds.isNotEmpty) {
      final tagPlaceholders = filter.base.tagIds.map((_) => '?').join(',');
      variables.addAll(filter.base.tagIds.map((id) => Variable(id)));

      whereConditions.add('''
        p.id IN (
          SELECT DISTINCT pt.password_id
          FROM password_tags pt
          WHERE pt.tag_id IN ($tagPlaceholders)
        )
      ''');
    }

    // Собираем WHERE клаузулу
    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    // Сортировка
    final orderBy = _buildOrderByClause(
      filter.sortField,
      filter.base.sortDirection,
    );

    // Пагинация
    String limitClause = '';
    if (filter.base.limit != null && filter.base.limit! > 0) {
      limitClause = 'LIMIT ? OFFSET ?';
      variables.add(Variable(filter.base.limit!));
      variables.add(Variable(filter.base.offset ?? 0));
    }

    final sql =
        '''
      SELECT DISTINCT p.id, p.name, p.description, p.login, p.email, 
             p.url, p.category_id, p.is_favorite, p.used_count, 
             p.is_archived, p.created_at, p.modified_at, p.last_accessed 
      FROM passwords p
      $whereClause
      $orderBy
      $limitClause
    ''';

    final results = await customSelect(sql, variables: variables).get();
    return await _convertCustomResultsToCardDtos(results);
  }

  /// Подсчет всех паролей
  Future<int> _countAllPasswords() async {
    final query = selectOnly(attachedDatabase.passwords)
      ..addColumns([attachedDatabase.passwords.id.count()]);

    final result = await query.getSingle();
    return result.read(attachedDatabase.passwords.id.count()) ?? 0;
  }

  /// Подсчет паролей с простой фильтрацией
  Future<int> _countPasswordsWithSimpleFilter(PasswordFilter filter) async {
    final query = selectOnly(attachedDatabase.passwords)
      ..addColumns([attachedDatabase.passwords.id.count()]);

    _applyAllFilters(query, filter);

    final result = await query.getSingle();
    return result.read(attachedDatabase.passwords.id.count()) ?? 0;
  }

  /// Подсчет паролей с фильтрацией по тегам
  Future<int> _countPasswordsWithTagFilter(PasswordFilter filter) async {
    final whereConditions = <String>[];
    final variables = <Variable>[];

    _buildBaseWhereConditions(filter.base, whereConditions, variables);
    _buildPasswordWhereConditions(filter, whereConditions, variables);

    if (filter.base.tagIds.isNotEmpty) {
      final tagPlaceholders = filter.base.tagIds.map((_) => '?').join(',');
      variables.addAll(filter.base.tagIds.map((id) => Variable(id)));

      whereConditions.add('''
        p.id IN (
          SELECT DISTINCT pt.password_id
          FROM password_tags pt
          WHERE pt.tag_id IN ($tagPlaceholders)
        )
      ''');
    }

    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    final sql =
        '''
      SELECT COUNT(DISTINCT p.id) as count 
      FROM passwords p
      $whereClause
    ''';

    final result = await customSelect(sql, variables: variables).getSingle();
    return result.read<int>('count');
  }

  /// Stream для наблюдения за всеми паролями с базовой фильтрацией
  Stream<List<CardPasswordDto>> _watchAllPasswordsWithBasicFilter(
    BaseFilter baseFilter,
  ) {
    final query = selectOnly(attachedDatabase.passwords)
      ..addColumns([
        attachedDatabase.passwords.id,
        attachedDatabase.passwords.name,
        attachedDatabase.passwords.description,
        attachedDatabase.passwords.login,
        attachedDatabase.passwords.email,
        attachedDatabase.passwords.url,
        attachedDatabase.passwords.categoryId,
        attachedDatabase.passwords.isFavorite,
        attachedDatabase.passwords.usedCount,
        attachedDatabase.passwords.isArchived,
        attachedDatabase.passwords.createdAt,
        attachedDatabase.passwords.modifiedAt,
        attachedDatabase.passwords.lastAccessed,
      ]);

    _applyBaseFilters(query, baseFilter);
    _applySorting(query, null, baseFilter.sortDirection);

    if (baseFilter.limit != null && baseFilter.limit! > 0) {
      query.limit(baseFilter.limit!, offset: baseFilter.offset ?? 0);
    }

    return query.watch().asyncMap(
      (results) => _convertResultsToCardDtos(results),
    );
  }

  // ==================== МЕТОДЫ ПОСТРОЕНИЯ ФИЛЬТРОВ ====================

  /// Применение базовых фильтров к запросу
  void _applyBaseFilters(JoinedSelectStatement query, BaseFilter filter) {
    final conditions = <Expression<bool>>[];

    // Поиск по тексту
    if (filter.query.isNotEmpty) {
      final searchTerm = '%${filter.query.toLowerCase()}%';
      conditions.add(
        attachedDatabase.passwords.name.lower().like(searchTerm) |
            attachedDatabase.passwords.url.lower().like(searchTerm) |
            attachedDatabase.passwords.login.lower().like(searchTerm) |
            attachedDatabase.passwords.email.lower().like(searchTerm),
      );
    }

    // Категории
    if (filter.categoryIds.isNotEmpty) {
      conditions.add(
        attachedDatabase.passwords.categoryId.isIn(filter.categoryIds),
      );
    }

    // Флаги
    if (filter.isFavorite != null) {
      conditions.add(
        attachedDatabase.passwords.isFavorite.equals(filter.isFavorite!),
      );
    }

    if (filter.isArchived != null) {
      conditions.add(
        attachedDatabase.passwords.isArchived.equals(filter.isArchived!),
      );
    }

    if (filter.hasNotes != null) {
      if (filter.hasNotes!) {
        conditions.add(
          attachedDatabase.passwords.notes.isNotNull() &
              attachedDatabase.passwords.notes.isNotValue(''),
        );
      } else {
        conditions.add(
          attachedDatabase.passwords.notes.isNull() |
              attachedDatabase.passwords.notes.equals(''),
        );
      }
    }

    // Диапазоны дат
    if (filter.createdAfter != null) {
      conditions.add(
        attachedDatabase.passwords.createdAt.isBiggerOrEqualValue(
          filter.createdAfter!,
        ),
      );
    }
    if (filter.createdBefore != null) {
      conditions.add(
        attachedDatabase.passwords.createdAt.isSmallerOrEqualValue(
          filter.createdBefore!,
        ),
      );
    }

    if (filter.modifiedAfter != null) {
      conditions.add(
        attachedDatabase.passwords.modifiedAt.isBiggerOrEqualValue(
          filter.modifiedAfter!,
        ),
      );
    }
    if (filter.modifiedBefore != null) {
      conditions.add(
        attachedDatabase.passwords.modifiedAt.isSmallerOrEqualValue(
          filter.modifiedBefore!,
        ),
      );
    }

    if (filter.lastAccessedAfter != null) {
      conditions.add(
        attachedDatabase.passwords.lastAccessed.isBiggerOrEqualValue(
          filter.lastAccessedAfter!,
        ),
      );
    }
    if (filter.lastAccessedBefore != null) {
      conditions.add(
        attachedDatabase.passwords.lastAccessed.isSmallerOrEqualValue(
          filter.lastAccessedBefore!,
        ),
      );
    }

    // Применяем условия
    if (conditions.isNotEmpty) {
      final combinedCondition = conditions.reduce((a, b) => a & b);
      query.where(combinedCondition);
    }
  }

  /// Применение всех фильтров к запросу
  void _applyAllFilters(JoinedSelectStatement query, PasswordFilter filter) {
    // Сначала применяем базовые фильтры
    _applyBaseFilters(query, filter.base);

    final conditions = <Expression<bool>>[];

    // Специфичные для паролей фильтры
    if (filter.name != null) {
      conditions.add(
        attachedDatabase.passwords.name.lower().like(
          '%${filter.name!.toLowerCase()}%',
        ),
      );
    }

    if (filter.url != null) {
      conditions.add(
        attachedDatabase.passwords.url.lower().like(
          '%${filter.url!.toLowerCase()}%',
        ),
      );
    }

    if (filter.username != null) {
      conditions.add(
        attachedDatabase.passwords.login.lower().like(
              '%${filter.username!.toLowerCase()}%',
            ) |
            attachedDatabase.passwords.email.lower().like(
              '%${filter.username!.toLowerCase()}%',
            ),
      );
    }

    if (filter.hasUrl != null) {
      if (filter.hasUrl!) {
        conditions.add(
          attachedDatabase.passwords.url.isNotNull() &
              attachedDatabase.passwords.url.isNotValue(''),
        );
      } else {
        conditions.add(
          attachedDatabase.passwords.url.isNull() |
              attachedDatabase.passwords.url.equals(''),
        );
      }
    }

    if (filter.hasUsername != null) {
      if (filter.hasUsername!) {
        conditions.add(
          (attachedDatabase.passwords.login.isNotNull() &
                  attachedDatabase.passwords.login.isNotValue('')) |
              (attachedDatabase.passwords.email.isNotNull() &
                  attachedDatabase.passwords.email.isNotValue('')),
        );
      } else {
        conditions.add(
          (attachedDatabase.passwords.login.isNull() |
                  attachedDatabase.passwords.login.equals('')) &
              (attachedDatabase.passwords.email.isNull() |
                  attachedDatabase.passwords.email.equals('')),
        );
      }
    }

    logDebug(
      'PasswordFilterDao: Применение фильтра isFrequent: ${filter.isFrequent}',
      tag: 'isFrequent',
    );

    if (filter.isFrequent != null) {
      if (filter.isFrequent!) {
        conditions.add(
          attachedDatabase.passwords.usedCount.isBiggerOrEqualValue(
            kFrequentUsedThreshold,
          ),
        );
      } else {
        conditions.add(
          attachedDatabase.passwords.usedCount.isSmallerThanValue(
            kFrequentUsedThreshold,
          ),
        );
      }
    }

    // Применяем дополнительные условия
    if (conditions.isNotEmpty) {
      final combinedCondition = conditions.reduce((a, b) => a & b);
      query.where(combinedCondition);
    }
  }

  /// Применение сортировки к запросу
  void _applySorting(
    JoinedSelectStatement query,
    PasswordSortField? sortField,
    SortDirection direction,
  ) {
    switch (sortField) {
      case PasswordSortField.name:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.passwords.name)
              : OrderingTerm.desc(attachedDatabase.passwords.name),
        ]);
        break;
      case PasswordSortField.url:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.passwords.url)
              : OrderingTerm.desc(attachedDatabase.passwords.url),
        ]);
        break;
      case PasswordSortField.username:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.passwords.login)
              : OrderingTerm.desc(attachedDatabase.passwords.login),
        ]);
        break;
      case PasswordSortField.createdAt:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.passwords.createdAt)
              : OrderingTerm.desc(attachedDatabase.passwords.createdAt),
        ]);
        break;
      case PasswordSortField.modifiedAt:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.passwords.modifiedAt)
              : OrderingTerm.desc(attachedDatabase.passwords.modifiedAt),
        ]);
        break;
      case PasswordSortField.lastAccessed:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.passwords.lastAccessed)
              : OrderingTerm.desc(attachedDatabase.passwords.lastAccessed),
        ]);
        break;
      case PasswordSortField.usedCount:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.passwords.usedCount)
              : OrderingTerm.desc(attachedDatabase.passwords.usedCount),
        ]);
        break;
      default:
        // По умолчанию сортируем по дате изменения
        query.orderBy([
          OrderingTerm.desc(attachedDatabase.passwords.modifiedAt),
        ]);
    }
  }

  /// Построение базовых WHERE условий для кастомного SQL
  void _buildBaseWhereConditions(
    BaseFilter filter,
    List<String> conditions,
    List<Variable> variables,
  ) {
    // Поиск по тексту
    if (filter.query.isNotEmpty) {
      conditions.add('''
        (LOWER(p.name) LIKE ? OR LOWER(p.url) LIKE ? OR 
         LOWER(p.login) LIKE ? OR LOWER(p.email) LIKE ?)
      ''');
      final searchTerm = '%${filter.query.toLowerCase()}%';
      variables.addAll([
        Variable(searchTerm),
        Variable(searchTerm),
        Variable(searchTerm),
        Variable(searchTerm),
      ]);
    }

    // Категории
    if (filter.categoryIds.isNotEmpty) {
      final placeholders = filter.categoryIds.map((_) => '?').join(',');
      conditions.add('p.category_id IN ($placeholders)');
      variables.addAll(filter.categoryIds.map((id) => Variable(id)));
    }

    // Флаги
    if (filter.isFavorite != null) {
      conditions.add('p.is_favorite = ?');
      variables.add(Variable(filter.isFavorite!));
    }

    if (filter.isArchived != null) {
      conditions.add('p.is_archived = ?');
      variables.add(Variable(filter.isArchived!));
    }

    if (filter.hasNotes != null) {
      if (filter.hasNotes!) {
        conditions.add('(p.notes IS NOT NULL AND p.notes != \'\')');
      } else {
        conditions.add('(p.notes IS NULL OR p.notes = \'\')');
      }
    }

    // Диапазоны дат
    if (filter.createdAfter != null) {
      conditions.add('p.created_at >= ?');
      variables.add(Variable(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      conditions.add('p.created_at <= ?');
      variables.add(Variable(filter.createdBefore!));
    }

    if (filter.modifiedAfter != null) {
      conditions.add('p.modified_at >= ?');
      variables.add(Variable(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      conditions.add('p.modified_at <= ?');
      variables.add(Variable(filter.modifiedBefore!));
    }

    if (filter.lastAccessedAfter != null) {
      conditions.add('p.last_accessed >= ?');
      variables.add(Variable(filter.lastAccessedAfter!));
    }
    if (filter.lastAccessedBefore != null) {
      conditions.add('p.last_accessed <= ?');
      variables.add(Variable(filter.lastAccessedBefore!));
    }
  }

  /// Построение WHERE условий для PasswordFilter в кастомном SQL
  void _buildPasswordWhereConditions(
    PasswordFilter filter,
    List<String> conditions,
    List<Variable> variables,
  ) {
    if (filter.name != null) {
      conditions.add('LOWER(p.name) LIKE ?');
      variables.add(Variable('%${filter.name!.toLowerCase()}%'));
    }

    if (filter.url != null) {
      conditions.add('LOWER(p.url) LIKE ?');
      variables.add(Variable('%${filter.url!.toLowerCase()}%'));
    }

    if (filter.username != null) {
      conditions.add('(LOWER(p.login) LIKE ? OR LOWER(p.email) LIKE ?)');
      final searchTerm = '%${filter.username!.toLowerCase()}%';
      variables.addAll([Variable(searchTerm), Variable(searchTerm)]);
    }

    if (filter.hasUrl != null) {
      if (filter.hasUrl!) {
        conditions.add('(p.url IS NOT NULL AND p.url != \'\')');
      } else {
        conditions.add('(p.url IS NULL OR p.url = \'\')');
      }
    }

    if (filter.hasUsername != null) {
      if (filter.hasUsername!) {
        conditions.add('''
          ((p.login IS NOT NULL AND p.login != '') OR 
           (p.email IS NOT NULL AND p.email != ''))
        ''');
      } else {
        conditions.add('''
          ((p.login IS NULL OR p.login = '') AND 
           (p.email IS NULL OR p.email = ''))
        ''');
      }
    }

    if (filter.isFrequent != null) {
      if (filter.isFrequent!) {
        conditions.add('p.used_count >= ?');
        variables.add(Variable(kFrequentUsedThreshold));
      } else {
        conditions.add('p.used_count < ?');
        variables.add(Variable(kFrequentUsedThreshold));
      }
    }
  }

  /// Построение ORDER BY клаузулы для кастомного SQL
  String _buildOrderByClause(
    PasswordSortField? sortField,
    SortDirection direction,
  ) {
    final dirStr = direction == SortDirection.asc ? 'ASC' : 'DESC';

    switch (sortField) {
      case PasswordSortField.name:
        return 'ORDER BY p.name $dirStr';
      case PasswordSortField.url:
        return 'ORDER BY p.url $dirStr';
      case PasswordSortField.username:
        return 'ORDER BY p.login $dirStr';
      case PasswordSortField.createdAt:
        return 'ORDER BY p.created_at $dirStr';
      case PasswordSortField.modifiedAt:
        return 'ORDER BY p.modified_at $dirStr';
      case PasswordSortField.lastAccessed:
        return 'ORDER BY p.last_accessed $dirStr';
      case PasswordSortField.usedCount:
        return 'ORDER BY p.used_count $dirStr';
      default:
        return 'ORDER BY p.modified_at DESC';
    }
  }

  // ==================== МЕТОДЫ КОНВЕРТАЦИИ ====================

  /// Конвертация результатов Drift запроса в CardPasswordDto
  Future<List<CardPasswordDto>> _convertResultsToCardDtos(
    List<TypedResult> results,
  ) async {
    final cardDtos = <CardPasswordDto>[];

    for (final row in results) {
      final passwordData = _PasswordRowData(
        id: row.read(attachedDatabase.passwords.id)!,
        name: row.read(attachedDatabase.passwords.name)!,
        description: row.read(attachedDatabase.passwords.description),
        login: row.read(attachedDatabase.passwords.login),
        email: row.read(attachedDatabase.passwords.email),
        url: row.read(attachedDatabase.passwords.url),
        categoryId: row.read(attachedDatabase.passwords.categoryId),
        isFavorite: row.read(attachedDatabase.passwords.isFavorite)!,
        usedCount: row.read(attachedDatabase.passwords.usedCount)!,
        isArchived: row.read(attachedDatabase.passwords.isArchived)!,
        createdAt: row.read(attachedDatabase.passwords.createdAt)!,
        modifiedAt: row.read(attachedDatabase.passwords.modifiedAt)!,
        lastAccessed: row.read(attachedDatabase.passwords.lastAccessed),
      );

      final cardDto = await _passwordDataToCardDto(passwordData);
      cardDtos.add(cardDto);
    }

    return cardDtos;
  }

  /// Конвертация результатов кастомного SQL в CardPasswordDto
  Future<List<CardPasswordDto>> _convertCustomResultsToCardDtos(
    List<QueryRow> results,
  ) async {
    final cardDtos = <CardPasswordDto>[];

    for (final row in results) {
      final passwordData = _PasswordRowData(
        id: row.read<String>('id'),
        name: row.read<String>('name'),
        description: row.read<String?>('description'),
        login: row.read<String?>('login'),
        email: row.read<String?>('email'),
        url: row.read<String?>('url'),
        categoryId: row.read<String?>('category_id'),
        isFavorite: row.read<bool>('is_favorite'),
        usedCount: row.read<int>('used_count'),
        isArchived: row.read<bool>('is_archived'),
        createdAt: row.read<DateTime>('created_at'),
        modifiedAt: row.read<DateTime>('modified_at'),
        lastAccessed: row.read<DateTime?>('last_accessed'),
      );

      final cardDto = await _passwordDataToCardDto(passwordData);
      cardDtos.add(cardDto);
    }

    return cardDtos;
  }

  /// Преобразование данных пароля в CardPasswordDto
  Future<CardPasswordDto> _passwordDataToCardDto(_PasswordRowData data) async {
    final category = await _getCategoryForPassword(data.categoryId);
    final tags = await _getTagsForPassword(data.id);

    return CardPasswordDto(
      id: data.id,
      name: data.name,
      description: data.description,
      login: data.login,
      email: data.email,
      usedCount: data.usedCount,
      categories: category != null ? [category] : null,
      tags: tags.isNotEmpty ? tags : null,
      isFavorite: data.isFavorite,
      isFrequentlyUsed: data.usedCount >= kFrequentUsedThreshold,
    );
  }

  /// Получение категории пароля для CardPasswordDto
  Future<CardPasswordCategoryDto?> _getCategoryForPassword(
    String? categoryId,
  ) async {
    if (categoryId == null) return null;

    final category = await (select(
      attachedDatabase.categories,
    )..where((tbl) => tbl.id.equals(categoryId))).getSingleOrNull();

    if (category == null) return null;

    return CardPasswordCategoryDto(name: category.name, color: category.color);
  }

  /// Получение тегов пароля для CardPasswordDto (максимум 4)
  Future<List<CardPasswordTagDto>> _getTagsForPassword(
    String passwordId,
  ) async {
    final query =
        select(attachedDatabase.tags).join([
            innerJoin(
              attachedDatabase.passwordTags,
              attachedDatabase.passwordTags.tagId.equalsExp(
                attachedDatabase.tags.id,
              ),
            ),
          ])
          ..where(attachedDatabase.passwordTags.passwordId.equals(passwordId))
          ..limit(4); // Ограничиваем количество тегов

    final results = await query.get();

    return results.map((row) {
      final tag = row.readTable(attachedDatabase.tags);
      return CardPasswordTagDto(name: tag.name, color: tag.color);
    }).toList();
  }
}
