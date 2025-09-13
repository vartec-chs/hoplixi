import 'package:drift/drift.dart';
import 'package:hoplixi/hoplixi_store/utils/uuid_generator.dart';
import '../hoplixi_store.dart';
import '../tables/passwords.dart';
import '../tables/categories.dart';
import '../tables/tags.dart';
import '../tables/password_tags.dart';
import '../dto/db_dto.dart';
import '../models/password_filter.dart';

part 'passwords_dao.g.dart';

@DriftAccessor(tables: [Passwords, Categories, Tags, PasswordTags])
class PasswordsDao extends DatabaseAccessor<HoplixiStore>
    with _$PasswordsDaoMixin {
  PasswordsDao(super.db);

  /// Создание нового пароля
  Future<String> createPassword(CreatePasswordDto dto) async {
    final id = UuidGenerator.generate();
    final companion = PasswordsCompanion(
      id: Value(id),
      name: Value(dto.name),
      description: Value(dto.description),
      password: Value(dto.password),
      url: Value(dto.url),
      notes: Value(dto.notes),
      login: Value(dto.login),
      email: Value(dto.email),
      categoryId: Value(dto.categoryId),
      isFavorite: Value(dto.isFavorite),
    );

    final result = await into(
      attachedDatabase.passwords,
    ).insert(companion, mode: InsertMode.insertOrIgnore);

    // Возвращаем сгенерированный UUID из companion
    return id;
  }

  /// Обновление пароля
  Future<bool> updatePassword(UpdatePasswordDto dto) async {
    final companion = PasswordsCompanion(
      id: Value(dto.id),
      name: dto.name != null ? Value(dto.name!) : const Value.absent(),
      description: dto.description != null
          ? Value(dto.description)
          : const Value.absent(),
      password: dto.password != null
          ? Value(dto.password!)
          : const Value.absent(),
      url: dto.url != null ? Value(dto.url) : const Value.absent(),
      notes: dto.notes != null ? Value(dto.notes) : const Value.absent(),
      login: dto.login != null ? Value(dto.login) : const Value.absent(),
      email: dto.email != null ? Value(dto.email) : const Value.absent(),
      categoryId: dto.categoryId != null
          ? Value(dto.categoryId)
          : const Value.absent(),
      isFavorite: dto.isFavorite != null
          ? Value(dto.isFavorite!)
          : const Value.absent(),
      lastAccessed: dto.lastAccessed != null
          ? Value(dto.lastAccessed)
          : const Value.absent(),
      modifiedAt: Value(DateTime.now()),
    );

    final rowsAffected = await update(
      attachedDatabase.passwords,
    ).replace(companion);
    return rowsAffected;
  }

  /// Удаление пароля по ID
  Future<bool> deletePassword(String id) async {
    final rowsAffected = await (delete(
      attachedDatabase.passwords,
    )..where((tbl) => tbl.id.equals(id))).go();
    return rowsAffected > 0;
  }

  /// Получение пароля по ID
  Future<Password?> getPasswordById(String id) async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.id.equals(id));
    return await query.getSingleOrNull();
  }

  /// Получение всех паролей
  Future<List<Password>> getAllPasswords() async {
    return await select(attachedDatabase.passwords).get();
  }

  /// Получение паролей по категории
  Future<List<Password>> getPasswordsByCategory(String categoryId) async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.categoryId.equals(categoryId));
    return await query.get();
  }

  /// Получение избранных паролей
  Future<List<Password>> getFavoritePasswords() async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Поиск паролей по имени или URL
  Future<List<Password>> searchPasswords(String searchTerm) async {
    final query = select(attachedDatabase.passwords)
      ..where(
        (tbl) =>
            tbl.name.like('%$searchTerm%') |
            tbl.url.like('%$searchTerm%') |
            tbl.login.like('%$searchTerm%') |
            tbl.email.like('%$searchTerm%'),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return await query.get();
  }

  /// Получение недавно использованных паролей
  Future<List<Password>> getRecentlyAccessedPasswords({int limit = 10}) async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.lastAccessed.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.lastAccessed)])
      ..limit(limit);
    return await query.get();
  }

  /// Обновление времени последнего доступа
  Future<void> updateLastAccessed(String id) async {
    await (update(
      attachedDatabase.passwords,
    )..where((tbl) => tbl.id.equals(id))).write(
      PasswordsCompanion(
        lastAccessed: Value(DateTime.now()),
        modifiedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Получение количества паролей
  Future<int> getPasswordsCount() async {
    final query = selectOnly(attachedDatabase.passwords)
      ..addColumns([attachedDatabase.passwords.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.passwords.id.count()) ?? 0;
  }

  /// Получение количества паролей по категориям
  Future<Map<String?, int>> getPasswordsCountByCategory() async {
    final query = selectOnly(attachedDatabase.passwords)
      ..addColumns([
        attachedDatabase.passwords.categoryId,
        attachedDatabase.passwords.id.count(),
      ])
      ..groupBy([attachedDatabase.passwords.categoryId]);

    final results = await query.get();
    return {
      for (final row in results)
        row.read(attachedDatabase.passwords.categoryId):
            row.read(attachedDatabase.passwords.id.count()) ?? 0,
    };
  }

  /// Stream для наблюдения за всеми паролями
  Stream<List<Password>> watchAllPasswords() {
    return select(attachedDatabase.passwords).watch();
  }

  /// Stream для наблюдения за паролями по категории
  Stream<List<Password>> watchPasswordsByCategory(String categoryId) {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.categoryId.equals(categoryId));
    return query.watch();
  }

  /// Stream для наблюдения за избранными паролями
  Stream<List<Password>> watchFavoritePasswords() {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.isFavorite.equals(true))
      ..orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    return query.watch();
  }

  /// Batch операции для создания множественных паролей
  Future<void> createPasswordsBatch(List<CreatePasswordDto> dtos) async {
    await batch((batch) {
      for (final dto in dtos) {
        final companion = PasswordsCompanion(
          name: Value(dto.name),
          description: Value(dto.description),
          password: Value(dto.password),
          url: Value(dto.url),
          notes: Value(dto.notes),
          login: Value(dto.login),
          email: Value(dto.email),
          categoryId: Value(dto.categoryId),
          isFavorite: Value(dto.isFavorite),
        );
        batch.insert(attachedDatabase.passwords, companion);
      }
    });
  }

  Future<void> incrementUsedCount(String passwordId) async {
    await (update(attachedDatabase.passwords)..where(
          (tbl) =>
              tbl.id.equals(passwordId) & tbl.usedCount.isSmallerThanValue(100),
        ))
        .write(
          PasswordsCompanion(
            usedCount: const Value(1),
            modifiedAt: Value(DateTime.now()),
          ),
        );
  }

  /// For coping password general info
  Future<Password?> getPassword(String passwordId) async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.id.equals(passwordId));
    return query.getSingle();
  }

  Future<String> getLoginOrEmail(String passwordId) async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.id.equals(passwordId));
    final password = await query.getSingle();
    return password.login ?? password.email as String;
  }

  Future<String?> getUrl(String passwordId) async {
    final query = select(attachedDatabase.passwords)
      ..where((tbl) => tbl.id.equals(passwordId));
    final password = await query.getSingle();
    return password.url;
  }

  // ==================== ФИЛЬТРАЦИЯ ПАРОЛЕЙ ====================

  /// Главный метод для получения отфильтрованных паролей
  Future<List<Password>> getFilteredPasswords(PasswordFilter filter) async {
    // Если нет активных ограничений, возвращаем все пароли с сортировкой
    if (!filter.hasActiveConstraints) {
      final query = _applySorting(
        select(attachedDatabase.passwords),
        filter.sortField,
        filter.sortDirection,
      );
      if (filter.limit != null) {
        query.limit(filter.limit!, offset: filter.offset ?? 0);
      }
      return await query.get();
    }

    // Строим базовый запрос
    var query = select(attachedDatabase.passwords);

    // Добавляем JOIN для категорий и тегов если нужно
    List<Join> joins = [];

    if (filter.categoryIds.isNotEmpty || filter.tagIds.isNotEmpty) {
      if (filter.tagIds.isNotEmpty) {
        joins.add(
          leftOuterJoin(
            attachedDatabase.passwordTags,
            attachedDatabase.passwordTags.passwordId.equalsExp(
              attachedDatabase.passwords.id,
            ),
          ),
        );
        joins.add(
          leftOuterJoin(
            attachedDatabase.tags,
            attachedDatabase.tags.id.equalsExp(
              attachedDatabase.passwordTags.tagId,
            ),
          ),
        );
      }
    }

    // Применяем JOIN если есть
    JoinedSelectStatement? joinedQuery;
    if (joins.isNotEmpty) {
      joinedQuery = query.join(joins);
    }

    // Применяем фильтры WHERE
    final conditions = _buildWhereConditions(filter);
    if (conditions.isNotEmpty) {
      final combinedCondition = conditions.reduce((a, b) => a & b);
      if (joinedQuery != null) {
        joinedQuery.where(combinedCondition);
      } else {
        query.where((tbl) => combinedCondition);
      }
    }

    // Для сложных фильтров с тегами используем кастомный SQL
    if (filter.tagIds.isNotEmpty) {
      return await _getPasswordsWithTagFilter(filter);
    }

    // Обычный запрос без тегов
    if (joinedQuery != null) {
      final results = await joinedQuery.get();
      var passwords = results
          .map((row) => row.readTable(attachedDatabase.passwords))
          .toSet() // убираем дубли
          .toList();

      // Применяем сортировку и пагинацию
      passwords = _applySortingToList(
        passwords,
        filter.sortField,
        filter.sortDirection,
      );

      if (filter.limit != null) {
        final offset = filter.offset ?? 0;
        final end = offset + filter.limit!;
        passwords = passwords.sublist(
          offset.clamp(0, passwords.length),
          end.clamp(0, passwords.length),
        );
      }

      return passwords;
    } else {
      // Применяем сортировку и пагинацию к обычному запросу
      final sortedQuery = _applySorting(
        query,
        filter.sortField,
        filter.sortDirection,
      );
      if (filter.limit != null) {
        sortedQuery.limit(filter.limit!, offset: filter.offset ?? 0);
      }
      return await sortedQuery.get();
    }
  }

  /// Подсчет количества отфильтрованных паролей
  Future<int> countFilteredPasswords(PasswordFilter filter) async {
    if (!filter.hasActiveConstraints) {
      final query = selectOnly(attachedDatabase.passwords)
        ..addColumns([attachedDatabase.passwords.id.count()]);
      final result = await query.getSingle();
      return result.read(attachedDatabase.passwords.id.count()) ?? 0;
    }

    // Для сложных фильтров с тегами
    if (filter.tagIds.isNotEmpty) {
      return await _countPasswordsWithTagFilter(filter);
    }

    // Обычный подсчет
    final query = selectOnly(attachedDatabase.passwords);

    // Применяем условия WHERE
    final conditions = _buildWhereConditions(filter);
    if (conditions.isNotEmpty) {
      final combinedCondition = conditions.reduce((a, b) => a & b);
      query.where(combinedCondition);
    }

    query.addColumns([attachedDatabase.passwords.id.count()]);
    final result = await query.getSingle();
    return result.read(attachedDatabase.passwords.id.count()) ?? 0;
  }

  /// Stream для наблюдения за отфильтрованными паролями
  Stream<List<Password>> watchFilteredPasswords(PasswordFilter filter) {
    if (!filter.hasActiveConstraints) {
      final query = _applySorting(
        select(attachedDatabase.passwords),
        filter.sortField,
        filter.sortDirection,
      );
      if (filter.limit != null) {
        query.limit(filter.limit!, offset: filter.offset ?? 0);
      }
      return query.watch();
    }

    // Для сложных случаев возвращаем периодически обновляемый stream
    return Stream.periodic(
      const Duration(seconds: 1),
    ).asyncMap((_) => getFilteredPasswords(filter)).distinct();
  }

  // ==================== ПРИВАТНЫЕ МЕТОДЫ ====================

  /// Построение условий WHERE на основе фильтра
  List<Expression<bool>> _buildWhereConditions(PasswordFilter filter) {
    final conditions = <Expression<bool>>[];
    final passwords = attachedDatabase.passwords;

    // Поиск по тексту
    if (filter.query.isNotEmpty) {
      final searchTerm = '%${filter.query.toLowerCase()}%';
      conditions.add(
        passwords.name.lower().like(searchTerm) |
            passwords.url.lower().like(searchTerm) |
            passwords.login.lower().like(searchTerm) |
            passwords.email.lower().like(searchTerm) |
            passwords.notes.lower().like(searchTerm),
      );
    }

    // Фильтр по категориям (простой случай без many-to-many)
    if (filter.categoryIds.isNotEmpty) {
      conditions.add(passwords.categoryId.isIn(filter.categoryIds));
    }

    // Флаги
    if (filter.isFavorite != null) {
      conditions.add(passwords.isFavorite.equals(filter.isFavorite!));
    }

    if (filter.isArchived != null) {
      conditions.add(passwords.isArchived.equals(filter.isArchived!));
    }

    if (filter.hasNotes != null) {
      if (filter.hasNotes!) {
        conditions.add(
          passwords.notes.isNotNull() & passwords.notes.isNotValue(''),
        );
      } else {
        conditions.add(passwords.notes.isNull() | passwords.notes.equals(''));
      }
    }

    // Диапазоны дат
    if (filter.createdAfter != null) {
      conditions.add(
        passwords.createdAt.isBiggerOrEqualValue(filter.createdAfter!),
      );
    }
    if (filter.createdBefore != null) {
      conditions.add(
        passwords.createdAt.isSmallerOrEqualValue(filter.createdBefore!),
      );
    }

    if (filter.modifiedAfter != null) {
      conditions.add(
        passwords.modifiedAt.isBiggerOrEqualValue(filter.modifiedAfter!),
      );
    }
    if (filter.modifiedBefore != null) {
      conditions.add(
        passwords.modifiedAt.isSmallerOrEqualValue(filter.modifiedBefore!),
      );
    }

    if (filter.lastAccessedAfter != null) {
      conditions.add(
        passwords.lastAccessed.isBiggerOrEqualValue(filter.lastAccessedAfter!),
      );
    }
    if (filter.lastAccessedBefore != null) {
      conditions.add(
        passwords.lastAccessed.isSmallerOrEqualValue(
          filter.lastAccessedBefore!,
        ),
      );
    }

    // Часто используемые пароли
    if (filter.isFrequent != null) {
      if (filter.isFrequent!) {
        conditions.add(
          passwords.usedCount.isBiggerOrEqualValue(kFrequentUsedThreshold),
        );
      } else {
        conditions.add(
          passwords.usedCount.isSmallerThanValue(kFrequentUsedThreshold),
        );
      }
    }

    return conditions;
  }

  /// Получение паролей с фильтром по тегам (использует кастомный SQL)
  Future<List<Password>> _getPasswordsWithTagFilter(
    PasswordFilter filter,
  ) async {
    // Базовые условия WHERE для паролей
    final baseConditions = _buildWhereConditions(
      filter.copyWith(tagIds: []), // убираем теги из базовых условий
    );

    String baseWhereClause = '';
    final baseVariables = <Variable>[];

    if (baseConditions.isNotEmpty) {
      // Это упрощенная реализация - в реальности нужно правильно парсить Expression
      baseWhereClause = _expressionsToSql(baseConditions, baseVariables);
    }

    // SQL для фильтрации по тегам
    String tagCondition = '';
    final tagVariables = <Variable>[];

    if (filter.tagIds.isNotEmpty) {
      final tagPlaceholders = filter.tagIds.map((_) => '?').join(',');
      tagVariables.addAll(filter.tagIds.map((id) => Variable(id)));

      if (filter.tagsMatch == MatchMode.all) {
        // Все теги (AND)
        tagCondition =
            '''
          p.id IN (
            SELECT pt.password_id
            FROM password_tags pt
            WHERE pt.tag_id IN ($tagPlaceholders)
            GROUP BY pt.password_id
            HAVING COUNT(DISTINCT pt.tag_id) = ?
          )
        ''';
        tagVariables.add(Variable(filter.tagIds.length));
      } else {
        // Любой тег (OR)
        tagCondition =
            '''
          p.id IN (
            SELECT DISTINCT pt.password_id
            FROM password_tags pt
            WHERE pt.tag_id IN ($tagPlaceholders)
          )
        ''';
      }
    }

    // Объединяем условия
    String whereClause = '';
    if (baseWhereClause.isNotEmpty && tagCondition.isNotEmpty) {
      whereClause = 'WHERE ($baseWhereClause) AND ($tagCondition)';
    } else if (baseWhereClause.isNotEmpty) {
      whereClause = 'WHERE $baseWhereClause';
    } else if (tagCondition.isNotEmpty) {
      whereClause = 'WHERE $tagCondition';
    }

    // Сортировка
    final orderBy = _getSortingClause(filter.sortField, filter.sortDirection);

    // Пагинация
    String limitClause = '';
    final limitVariables = <Variable>[];
    if (filter.limit != null) {
      limitClause = 'LIMIT ? OFFSET ?';
      limitVariables.add(Variable(filter.limit!));
      limitVariables.add(Variable(filter.offset ?? 0));
    }

    final sql =
        '''
      SELECT DISTINCT p.* FROM passwords p
      $whereClause
      $orderBy
      $limitClause
    ''';

    final allVariables = [...baseVariables, ...tagVariables, ...limitVariables];

    final results = await customSelect(sql, variables: allVariables).get();

    return results
        .map(
          (row) => Password(
            id: row.read<String>('id'),
            name: row.read<String>('name'),
            description: row.read<String?>('description'),
            password: row.read<String>('password'),
            url: row.read<String?>('url'),
            notes: row.read<String?>('notes'),
            login: row.read<String?>('login'),
            email: row.read<String?>('email'),
            isArchived: row.read<bool>('is_archived'),
            usedCount: row.read<int>('used_count'),
            categoryId: row.read<String?>('category_id'),
            isFavorite: row.read<bool>('is_favorite'),
            createdAt: row.read<DateTime>('created_at'),
            modifiedAt: row.read<DateTime>('modified_at'),
            lastAccessed: row.read<DateTime?>('last_accessed'),
          ),
        )
        .toList();
  }

  /// Подсчет паролей с фильтром по тегам
  Future<int> _countPasswordsWithTagFilter(PasswordFilter filter) async {
    final baseConditions = _buildWhereConditions(filter.copyWith(tagIds: []));

    String baseWhereClause = '';
    final baseVariables = <Variable>[];

    if (baseConditions.isNotEmpty) {
      baseWhereClause = _expressionsToSql(baseConditions, baseVariables);
    }

    String tagCondition = '';
    final tagVariables = <Variable>[];

    if (filter.tagIds.isNotEmpty) {
      final tagPlaceholders = filter.tagIds.map((_) => '?').join(',');
      tagVariables.addAll(filter.tagIds.map((id) => Variable(id)));

      if (filter.tagsMatch == MatchMode.all) {
        tagCondition =
            '''
          p.id IN (
            SELECT pt.password_id
            FROM password_tags pt
            WHERE pt.tag_id IN ($tagPlaceholders)
            GROUP BY pt.password_id
            HAVING COUNT(DISTINCT pt.tag_id) = ?
          )
        ''';
        tagVariables.add(Variable(filter.tagIds.length));
      } else {
        tagCondition =
            '''
          p.id IN (
            SELECT DISTINCT pt.password_id
            FROM password_tags pt
            WHERE pt.tag_id IN ($tagPlaceholders)
          )
        ''';
      }
    }

    String whereClause = '';
    if (baseWhereClause.isNotEmpty && tagCondition.isNotEmpty) {
      whereClause = 'WHERE ($baseWhereClause) AND ($tagCondition)';
    } else if (baseWhereClause.isNotEmpty) {
      whereClause = 'WHERE $baseWhereClause';
    } else if (tagCondition.isNotEmpty) {
      whereClause = 'WHERE $tagCondition';
    }

    final sql =
        '''
      SELECT COUNT(DISTINCT p.id) as count FROM passwords p
      $whereClause
    ''';

    final allVariables = [...baseVariables, ...tagVariables];
    final result = await customSelect(sql, variables: allVariables).getSingle();

    return result.read<int>('count');
  }

  /// Применение сортировки к запросу
  SimpleSelectStatement<$PasswordsTable, Password> _applySorting(
    SimpleSelectStatement<$PasswordsTable, Password> query,
    PasswordSortField? sortField,
    SortDirection direction,
  ) {
    switch (sortField) {
      case PasswordSortField.name:
        query.orderBy([
          (t) => direction == SortDirection.asc
              ? OrderingTerm.asc(t.name)
              : OrderingTerm.desc(t.name),
        ]);
        break;
      case PasswordSortField.createdAt:
        query.orderBy([
          (t) => direction == SortDirection.asc
              ? OrderingTerm.asc(t.createdAt)
              : OrderingTerm.desc(t.createdAt),
        ]);
        break;
      case PasswordSortField.modifiedAt:
        query.orderBy([
          (t) => direction == SortDirection.asc
              ? OrderingTerm.asc(t.modifiedAt)
              : OrderingTerm.desc(t.modifiedAt),
        ]);
        break;
      case PasswordSortField.lastAccessed:
        query.orderBy([
          (t) => direction == SortDirection.asc
              ? OrderingTerm.asc(t.lastAccessed)
              : OrderingTerm.desc(t.lastAccessed),
        ]);
        break;
      case PasswordSortField.usedCount:
        query.orderBy([
          (t) => direction == SortDirection.asc
              ? OrderingTerm.asc(t.usedCount)
              : OrderingTerm.desc(t.usedCount),
        ]);
        break;
      default:
        query.orderBy([(t) => OrderingTerm.desc(t.modifiedAt)]);
    }
    return query;
  }

  /// Применение сортировки к списку (для случаев когда нельзя использовать ORDER BY в SQL)
  List<Password> _applySortingToList(
    List<Password> passwords,
    PasswordSortField? sortField,
    SortDirection direction,
  ) {
    switch (sortField) {
      case PasswordSortField.name:
        passwords.sort(
          (a, b) => direction == SortDirection.asc
              ? a.name.compareTo(b.name)
              : b.name.compareTo(a.name),
        );
        break;
      case PasswordSortField.createdAt:
        passwords.sort(
          (a, b) => direction == SortDirection.asc
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt),
        );
        break;
      case PasswordSortField.modifiedAt:
        passwords.sort(
          (a, b) => direction == SortDirection.asc
              ? a.modifiedAt.compareTo(b.modifiedAt)
              : b.modifiedAt.compareTo(a.modifiedAt),
        );
        break;
      case PasswordSortField.lastAccessed:
        passwords.sort((a, b) {
          final aAccessed =
              a.lastAccessed ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bAccessed =
              b.lastAccessed ?? DateTime.fromMillisecondsSinceEpoch(0);
          return direction == SortDirection.asc
              ? aAccessed.compareTo(bAccessed)
              : bAccessed.compareTo(aAccessed);
        });
        break;
      case PasswordSortField.usedCount:
        passwords.sort(
          (a, b) => direction == SortDirection.asc
              ? a.usedCount.compareTo(b.usedCount)
              : b.usedCount.compareTo(a.usedCount),
        );
        break;
      default:
        passwords.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    }
    return passwords;
  }

  /// Получение клаузулы сортировки для кастомного SQL
  String _getSortingClause(
    PasswordSortField? sortField,
    SortDirection direction,
  ) {
    final dirStr = direction == SortDirection.asc ? 'ASC' : 'DESC';

    switch (sortField) {
      case PasswordSortField.name:
        return 'ORDER BY p.name $dirStr';
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

  /// Упрощенное преобразование условий в SQL (заглушка)
  /// В реальной реализации нужно более сложную логику
  String _expressionsToSql(
    List<Expression<bool>> conditions,
    List<Variable> variables,
  ) {
    // Это упрощенная заглушка
    // В реальности нужно парсить Expression объекты и генерировать правильный SQL
    final conditionStrings = <String>[];

    for (int i = 0; i < conditions.length; i++) {
      // Здесь должна быть логика парсинга Expression
      // Пока используем простую заглушку
      conditionStrings.add('1=1');
    }

    return conditionStrings.join(' AND ');
  }
}
