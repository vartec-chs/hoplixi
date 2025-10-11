import 'package:drift/drift.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/filter_models/otp_filter.dart'
    hide OtpType; // Скрываем OtpType из модели фильтра
import 'package:hoplixi/hoplixi_store/models/filter_models/base_filter.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import '../../hoplixi_store.dart';
import '../../tables/otps.dart';
import '../../tables/categories.dart';
import '../../tables/tags.dart';
import '../../tables/otp_tags.dart';

part 'otp_filter_dao.g.dart';

/// Вспомогательный класс для данных OTP из строки результата
class _OtpRowData {
  final String id;
  final String? passwordId;
  final String type; // Изменено на String
  final String? issuer;
  final String? accountName;
  final String algorithm; // Изменено на String
  final int digits;
  final int period;
  final int? counter;
  final String? categoryId;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? lastAccessed;

  const _OtpRowData({
    required this.id,
    this.passwordId,
    required this.type,
    this.issuer,
    this.accountName,
    required this.algorithm,
    required this.digits,
    required this.period,
    this.counter,
    this.categoryId,
    required this.isFavorite,
    required this.createdAt,
    required this.modifiedAt,
    this.lastAccessed,
  });
}

@DriftAccessor(tables: [Otps, Categories, Tags, OtpTags])
class OtpFilterDao extends DatabaseAccessor<HoplixiStore>
    with _$OtpFilterDaoMixin {
  OtpFilterDao(super.db);

  /// Главный метод для получения отфильтрованных OTP кодов
  /// Возвращает Future<List<CardOtpDto>> согласно требованиям
  Future<List<CardOtpDto>> getFilteredOtps(OtpFilter filter) async {
    try {
      // Если нет активных ограничений, возвращаем все OTP с базовой сортировкой
      if (!filter.hasActiveConstraints) {
        return await _getAllOtpsWithBasicFilter(filter.base);
      }

      // Определяем нужны ли сложные JOIN'ы
      final needsTagJoin = filter.base.tagIds.isNotEmpty;

      // Для сложных фильтров с тегами используем кастомный SQL
      if (needsTagJoin) {
        return await _getOtpsWithTagFilter(filter);
      }

      // Для простых фильтров используем стандартные Drift запросы
      return await _getOtpsWithSimpleFilter(filter);
    } catch (e) {
      logError(
        'Ошибка получения отфильтрованных OTP кодов',
        error: e,
        tag: 'OtpFilterDao',
      );
      // В случае ошибки возвращаем пустой список
      return <CardOtpDto>[];
    }
  }

  /// Подсчет количества отфильтрованных OTP кодов
  Future<int> countFilteredOtps(OtpFilter filter) async {
    try {
      if (!filter.hasActiveConstraints) {
        return await _countAllOtps();
      }

      if (filter.base.tagIds.isNotEmpty) {
        return await _countOtpsWithTagFilter(filter);
      }

      return await _countOtpsWithSimpleFilter(filter);
    } catch (e) {
      return 0;
    }
  }

  /// Stream для наблюдения за отфильтрованными OTP кодами
  Stream<List<CardOtpDto>> watchFilteredOtps(OtpFilter filter) {
    // Для простых случаев используем стандартные Drift streams
    if (!filter.hasActiveConstraints) {
      return _watchAllOtpsWithBasicFilter(filter.base);
    }

    // Для сложных случаев возвращаем периодически обновляемый stream
    return Stream.periodic(
      const Duration(milliseconds: 500),
    ).asyncMap((_) => getFilteredOtps(filter)).distinct();
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Получение всех OTP с базовой фильтрацией
  Future<List<CardOtpDto>> _getAllOtpsWithBasicFilter(
    BaseFilter baseFilter,
  ) async {
    final query = selectOnly(attachedDatabase.otps)
      ..addColumns([
        attachedDatabase.otps.id,
        attachedDatabase.otps.passwordId,
        attachedDatabase.otps.type,
        attachedDatabase.otps.issuer,
        attachedDatabase.otps.accountName,
        attachedDatabase.otps.algorithm,
        attachedDatabase.otps.digits,
        attachedDatabase.otps.period,
        attachedDatabase.otps.counter,
        attachedDatabase.otps.categoryId,
        attachedDatabase.otps.isFavorite,
        attachedDatabase.otps.createdAt,
        attachedDatabase.otps.modifiedAt,
        attachedDatabase.otps.lastAccessed,
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

  /// Получение OTP с простой фильтрацией (без тегов)
  Future<List<CardOtpDto>> _getOtpsWithSimpleFilter(OtpFilter filter) async {
    final query = selectOnly(attachedDatabase.otps)
      ..addColumns([
        attachedDatabase.otps.id,
        attachedDatabase.otps.passwordId,
        attachedDatabase.otps.type,
        attachedDatabase.otps.issuer,
        attachedDatabase.otps.accountName,
        attachedDatabase.otps.algorithm,
        attachedDatabase.otps.digits,
        attachedDatabase.otps.period,
        attachedDatabase.otps.counter,
        attachedDatabase.otps.categoryId,
        attachedDatabase.otps.isFavorite,
        attachedDatabase.otps.createdAt,
        attachedDatabase.otps.modifiedAt,
        attachedDatabase.otps.lastAccessed,
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

  /// Получение OTP с фильтрацией по тегам (кастомный SQL)
  Future<List<CardOtpDto>> _getOtpsWithTagFilter(OtpFilter filter) async {
    final whereConditions = <String>[];
    final variables = <Variable>[];

    // Базовые условия
    _buildBaseWhereConditions(filter.base, whereConditions, variables);

    // Условия OtpFilter
    _buildOtpWhereConditions(filter, whereConditions, variables);

    // Условие для тегов
    if (filter.base.tagIds.isNotEmpty) {
      final tagPlaceholders = filter.base.tagIds.map((_) => '?').join(',');
      variables.addAll(filter.base.tagIds.map((id) => Variable(id)));

      whereConditions.add('''
        o.id IN (
          SELECT DISTINCT ot.otp_id
          FROM otp_tags ot
          WHERE ot.tag_id IN ($tagPlaceholders)
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
      SELECT DISTINCT o.id, o.password_id, o.type, o.issuer, o.account_name,
             o.algorithm, o.digits, o.period, o.counter, o.category_id, 
             o.is_favorite, o.created_at, o.modified_at, o.last_accessed
      FROM otps o
      $whereClause
      $orderBy
      $limitClause
    ''';

    final results = await customSelect(sql, variables: variables).get();
    return await _convertCustomResultsToCardDtos(results);
  }

  /// Подсчет всех OTP кодов
  Future<int> _countAllOtps() async {
    final query = selectOnly(attachedDatabase.otps)
      ..addColumns([attachedDatabase.otps.id.count()]);

    final result = await query.getSingle();
    return result.read(attachedDatabase.otps.id.count()) ?? 0;
  }

  /// Подсчет OTP с простой фильтрацией
  Future<int> _countOtpsWithSimpleFilter(OtpFilter filter) async {
    final query = selectOnly(attachedDatabase.otps)
      ..addColumns([attachedDatabase.otps.id.count()]);

    _applyAllFilters(query, filter);

    final result = await query.getSingle();
    return result.read(attachedDatabase.otps.id.count()) ?? 0;
  }

  /// Подсчет OTP с фильтрацией по тегам
  Future<int> _countOtpsWithTagFilter(OtpFilter filter) async {
    final whereConditions = <String>[];
    final variables = <Variable>[];

    _buildBaseWhereConditions(filter.base, whereConditions, variables);
    _buildOtpWhereConditions(filter, whereConditions, variables);

    if (filter.base.tagIds.isNotEmpty) {
      final tagPlaceholders = filter.base.tagIds.map((_) => '?').join(',');
      variables.addAll(filter.base.tagIds.map((id) => Variable(id)));

      whereConditions.add('''
        o.id IN (
          SELECT DISTINCT ot.otp_id
          FROM otp_tags ot
          WHERE ot.tag_id IN ($tagPlaceholders)
        )
      ''');
    }

    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    final sql =
        '''
      SELECT COUNT(DISTINCT o.id) as count 
      FROM otps o
      $whereClause
    ''';

    final result = await customSelect(sql, variables: variables).getSingle();
    return result.read<int>('count');
  }

  /// Stream для наблюдения за всеми OTP с базовой фильтрацией
  Stream<List<CardOtpDto>> _watchAllOtpsWithBasicFilter(BaseFilter baseFilter) {
    final query = selectOnly(attachedDatabase.otps)
      ..addColumns([
        attachedDatabase.otps.id,
        attachedDatabase.otps.passwordId,
        attachedDatabase.otps.type,
        attachedDatabase.otps.issuer,
        attachedDatabase.otps.accountName,
        attachedDatabase.otps.algorithm,
        attachedDatabase.otps.digits,
        attachedDatabase.otps.period,
        attachedDatabase.otps.counter,
        attachedDatabase.otps.categoryId,
        attachedDatabase.otps.isFavorite,
        attachedDatabase.otps.createdAt,
        attachedDatabase.otps.modifiedAt,
        attachedDatabase.otps.lastAccessed,
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
        attachedDatabase.otps.issuer.lower().like(searchTerm) |
            attachedDatabase.otps.accountName.lower().like(searchTerm),
      );
    }

    // Категории
    if (filter.categoryIds.isNotEmpty) {
      conditions.add(attachedDatabase.otps.categoryId.isIn(filter.categoryIds));
    }

    // Флаги
    if (filter.isFavorite != null) {
      conditions.add(
        attachedDatabase.otps.isFavorite.equals(filter.isFavorite!),
      );
    }

    // Диапазоны дат
    if (filter.createdAfter != null) {
      conditions.add(
        attachedDatabase.otps.createdAt.isBiggerOrEqualValue(
          filter.createdAfter!,
        ),
      );
    }
    if (filter.createdBefore != null) {
      conditions.add(
        attachedDatabase.otps.createdAt.isSmallerOrEqualValue(
          filter.createdBefore!,
        ),
      );
    }

    if (filter.modifiedAfter != null) {
      conditions.add(
        attachedDatabase.otps.modifiedAt.isBiggerOrEqualValue(
          filter.modifiedAfter!,
        ),
      );
    }
    if (filter.modifiedBefore != null) {
      conditions.add(
        attachedDatabase.otps.modifiedAt.isSmallerOrEqualValue(
          filter.modifiedBefore!,
        ),
      );
    }

    if (filter.lastAccessedAfter != null) {
      conditions.add(
        attachedDatabase.otps.lastAccessed.isBiggerOrEqualValue(
          filter.lastAccessedAfter!,
        ),
      );
    }
    if (filter.lastAccessedBefore != null) {
      conditions.add(
        attachedDatabase.otps.lastAccessed.isSmallerOrEqualValue(
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
  void _applyAllFilters(JoinedSelectStatement query, OtpFilter filter) {
    // Сначала применяем базовые фильтры
    _applyBaseFilters(query, filter.base);

    final conditions = <Expression<bool>>[];

    // Специфичные для OTP фильтры
    if (filter.type != null) {
      // Конвертируем OtpType из модели фильтра в текстовое значение
      final typeText = filter.type!.name; // 'totp' или 'hotp'
      conditions.add(attachedDatabase.otps.type.equals(typeText));
    }

    if (filter.issuer != null) {
      conditions.add(
        attachedDatabase.otps.issuer.lower().like(
          '%${filter.issuer!.toLowerCase()}%',
        ),
      );
    }

    if (filter.accountName != null) {
      conditions.add(
        attachedDatabase.otps.accountName.lower().like(
          '%${filter.accountName!.toLowerCase()}%',
        ),
      );
    }

    if (filter.algorithms != null && filter.algorithms!.isNotEmpty) {
      // Используем текстовые значения алгоритмов напрямую
      conditions.add(attachedDatabase.otps.algorithm.isIn(filter.algorithms!));
    }

    if (filter.digits != null) {
      conditions.add(attachedDatabase.otps.digits.equals(filter.digits!));
    }

    if (filter.period != null) {
      conditions.add(attachedDatabase.otps.period.equals(filter.period!));
    }

    if (filter.hasPasswordLink != null) {
      if (filter.hasPasswordLink!) {
        conditions.add(attachedDatabase.otps.passwordId.isNotNull());
      } else {
        conditions.add(attachedDatabase.otps.passwordId.isNull());
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
    OtpSortField? sortField,
    SortDirection direction,
  ) {
    switch (sortField) {
      case OtpSortField.issuer:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.otps.issuer)
              : OrderingTerm.desc(attachedDatabase.otps.issuer),
        ]);
        break;
      case OtpSortField.accountName:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.otps.accountName)
              : OrderingTerm.desc(attachedDatabase.otps.accountName),
        ]);
        break;
      case OtpSortField.createdAt:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.otps.createdAt)
              : OrderingTerm.desc(attachedDatabase.otps.createdAt),
        ]);
        break;
      case OtpSortField.modifiedAt:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.otps.modifiedAt)
              : OrderingTerm.desc(attachedDatabase.otps.modifiedAt),
        ]);
        break;
      case OtpSortField.lastAccessed:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.otps.lastAccessed)
              : OrderingTerm.desc(attachedDatabase.otps.lastAccessed),
        ]);
        break;
      default:
        // По умолчанию сортируем по дате изменения
        query.orderBy([OrderingTerm.desc(attachedDatabase.otps.modifiedAt)]);
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
        (LOWER(o.issuer) LIKE ? OR LOWER(o.account_name) LIKE ?)
      ''');
      final searchTerm = '%${filter.query.toLowerCase()}%';
      variables.addAll([Variable(searchTerm), Variable(searchTerm)]);
    }

    // Категории
    if (filter.categoryIds.isNotEmpty) {
      final placeholders = filter.categoryIds.map((_) => '?').join(',');
      conditions.add('o.category_id IN ($placeholders)');
      variables.addAll(filter.categoryIds.map((id) => Variable(id)));
    }

    // Флаги
    if (filter.isFavorite != null) {
      conditions.add('o.is_favorite = ?');
      variables.add(Variable(filter.isFavorite!));
    }

    // Диапазоны дат
    if (filter.createdAfter != null) {
      conditions.add('o.created_at >= ?');
      variables.add(Variable(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      conditions.add('o.created_at <= ?');
      variables.add(Variable(filter.createdBefore!));
    }

    if (filter.modifiedAfter != null) {
      conditions.add('o.modified_at >= ?');
      variables.add(Variable(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      conditions.add('o.modified_at <= ?');
      variables.add(Variable(filter.modifiedBefore!));
    }

    if (filter.lastAccessedAfter != null) {
      conditions.add('o.last_accessed >= ?');
      variables.add(Variable(filter.lastAccessedAfter!));
    }
    if (filter.lastAccessedBefore != null) {
      conditions.add('o.last_accessed <= ?');
      variables.add(Variable(filter.lastAccessedBefore!));
    }
  }

  /// Построение WHERE условий для OtpFilter в кастомном SQL
  void _buildOtpWhereConditions(
    OtpFilter filter,
    List<String> conditions,
    List<Variable> variables,
  ) {
    if (filter.type != null) {
      conditions.add('o.type = ?');
      variables.add(Variable(filter.type!.name));
    }

    if (filter.issuer != null) {
      conditions.add('LOWER(o.issuer) LIKE ?');
      variables.add(Variable('%${filter.issuer!.toLowerCase()}%'));
    }

    if (filter.accountName != null) {
      conditions.add('LOWER(o.account_name) LIKE ?');
      variables.add(Variable('%${filter.accountName!.toLowerCase()}%'));
    }

    if (filter.algorithms != null && filter.algorithms!.isNotEmpty) {
      final placeholders = filter.algorithms!.map((_) => '?').join(',');
      conditions.add('o.algorithm IN ($placeholders)');
      variables.addAll(filter.algorithms!.map((alg) => Variable(alg)));
    }

    if (filter.digits != null) {
      conditions.add('o.digits = ?');
      variables.add(Variable(filter.digits!));
    }

    if (filter.period != null) {
      conditions.add('o.period = ?');
      variables.add(Variable(filter.period!));
    }

    if (filter.hasPasswordLink != null) {
      if (filter.hasPasswordLink!) {
        conditions.add('o.password_id IS NOT NULL');
      } else {
        conditions.add('o.password_id IS NULL');
      }
    }
  }

  /// Построение ORDER BY клаузулы для кастомного SQL
  String _buildOrderByClause(OtpSortField? sortField, SortDirection direction) {
    final dirStr = direction == SortDirection.asc ? 'ASC' : 'DESC';

    switch (sortField) {
      case OtpSortField.issuer:
        return 'ORDER BY o.issuer $dirStr';
      case OtpSortField.accountName:
        return 'ORDER BY o.account_name $dirStr';
      case OtpSortField.createdAt:
        return 'ORDER BY o.created_at $dirStr';
      case OtpSortField.modifiedAt:
        return 'ORDER BY o.modified_at $dirStr';
      case OtpSortField.lastAccessed:
        return 'ORDER BY o.last_accessed $dirStr';
      default:
        return 'ORDER BY o.modified_at DESC';
    }
  }

  // ==================== МЕТОДЫ КОНВЕРТАЦИИ ====================

  /// Конвертация результатов Drift запроса в CardOtpDto
  Future<List<CardOtpDto>> _convertResultsToCardDtos(
    List<TypedResult> results,
  ) async {
    final cardDtos = <CardOtpDto>[];

    for (final row in results) {
      final otpData = _OtpRowData(
        id: row.read(attachedDatabase.otps.id)!,
        passwordId: row.read(attachedDatabase.otps.passwordId),
        type: row.read(attachedDatabase.otps.type)!,
        issuer: row.read(attachedDatabase.otps.issuer),
        accountName: row.read(attachedDatabase.otps.accountName),
        algorithm: row.read(attachedDatabase.otps.algorithm)!,
        digits: row.read(attachedDatabase.otps.digits)!,
        period: row.read(attachedDatabase.otps.period)!,
        counter: row.read(attachedDatabase.otps.counter),
        categoryId: row.read(attachedDatabase.otps.categoryId),
        isFavorite: row.read(attachedDatabase.otps.isFavorite)!,
        createdAt: row.read(attachedDatabase.otps.createdAt)!,
        modifiedAt: row.read(attachedDatabase.otps.modifiedAt)!,
        lastAccessed: row.read(attachedDatabase.otps.lastAccessed),
      );

      final cardDto = await _otpDataToCardDto(otpData);
      cardDtos.add(cardDto);
    }

    return cardDtos;
  }

  /// Конвертация результатов кастомного SQL в CardOtpDto
  Future<List<CardOtpDto>> _convertCustomResultsToCardDtos(
    List<QueryRow> results,
  ) async {
    final cardDtos = <CardOtpDto>[];

    for (final row in results) {
      final otpData = _OtpRowData(
        id: row.read<String>('id'),
        passwordId: row.read<String?>('password_id'),
        type: row.read<String>('type'),
        issuer: row.read<String?>('issuer'),
        accountName: row.read<String?>('account_name'),
        algorithm: row.read<String>('algorithm'),
        digits: row.read<int>('digits'),
        period: row.read<int>('period'),
        counter: row.read<int?>('counter'),
        categoryId: row.read<String?>('category_id'),
        isFavorite: row.read<bool>('is_favorite'),
        createdAt: row.read<DateTime>('created_at'),
        modifiedAt: row.read<DateTime>('modified_at'),
        lastAccessed: row.read<DateTime?>('last_accessed'),
      );

      final cardDto = await _otpDataToCardDto(otpData);
      cardDtos.add(cardDto);
    }

    return cardDtos;
  }

  /// Преобразование данных OTP в CardOtpDto
  Future<CardOtpDto> _otpDataToCardDto(_OtpRowData data) async {
    final category = await _getCategoryForOtp(data.categoryId);
    final tags = await _getTagsForOtp(data.id);

    // Конвертируем строковые значения в enum'ы
    final otpType = data.type == 'totp' ? OtpType.totp : OtpType.hotp;
    final algorithm = AlgorithmOtp.values.firstWhere(
      (e) => e.name == data.algorithm,
      orElse: () => AlgorithmOtp.SHA1,
    );

    return CardOtpDto(
      id: data.id,
      issuer: data.issuer,
      accountName: data.accountName,
      type: otpType,
      algorithm: algorithm,
      digits: data.digits,
      period: data.period,
      counter: data.counter,
      categories: category != null ? [category] : null,
      tags: tags.isNotEmpty ? tags : null,
      isFavorite: data.isFavorite,
      hasPasswordLink: data.passwordId != null,
    );
  }

  /// Получение категории OTP для CardOtpDto
  Future<CardOtpCategoryDto?> _getCategoryForOtp(String? categoryId) async {
    if (categoryId == null) return null;

    final category = await (select(
      attachedDatabase.categories,
    )..where((tbl) => tbl.id.equals(categoryId))).getSingleOrNull();

    if (category == null) return null;

    return CardOtpCategoryDto(name: category.name, color: category.color);
  }

  /// Получение тегов OTP для CardOtpDto (максимум 4)
  Future<List<CardOtpTagDto>> _getTagsForOtp(String otpId) async {
    final query =
        select(attachedDatabase.tags).join([
            innerJoin(
              attachedDatabase.otpTags,
              attachedDatabase.otpTags.tagId.equalsExp(
                attachedDatabase.tags.id,
              ),
            ),
          ])
          ..where(attachedDatabase.otpTags.otpId.equals(otpId))
          ..limit(4); // Ограничиваем количество тегов

    final results = await query.get();

    return results.map((row) {
      final tag = row.readTable(attachedDatabase.tags);
      return CardOtpTagDto(name: tag.name, color: tag.color);
    }).toList();
  }
}
