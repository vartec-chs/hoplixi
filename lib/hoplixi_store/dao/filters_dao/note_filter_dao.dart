import 'package:drift/drift.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/models/filter/notes_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import '../../hoplixi_store.dart';
import '../../tables/notes.dart';
import '../../tables/categories.dart';
import '../../tables/tags.dart';
import '../../tables/note_tags.dart';

part 'note_filter_dao.g.dart';

/// Вспомогательный класс для данных заметки из строки результата
class _NoteRowData {
  final String id;
  final String title;
  final String? description;
  final String content;
  final String? categoryId;
  final bool isFavorite;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final DateTime? lastAccessed;

  const _NoteRowData({
    required this.id,
    required this.title,
    this.description,
    required this.content,
    this.categoryId,
    required this.isFavorite,
    required this.isPinned,
    required this.createdAt,
    required this.modifiedAt,
    this.lastAccessed,
  });
}

@DriftAccessor(tables: [Notes, Categories, Tags, NoteTags])
class NoteFilterDao extends DatabaseAccessor<HoplixiStore>
    with _$NoteFilterDaoMixin {
  NoteFilterDao(super.db);

  /// Главный метод для получения отфильтрованных заметок
  /// Возвращает Future<List<CardNoteDto>> согласно требованиям
  Future<List<CardNoteDto>> getFilteredNotes(NotesFilter filter) async {
    try {
      // Если нет активных ограничений, возвращаем все заметки с базовой сортировкой
      if (!filter.hasActiveConstraints) {
        return await _getAllNotesWithBasicFilter(filter.base);
      }

      // Определяем нужны ли сложные JOIN'ы
      final needsTagJoin = filter.base.tagIds.isNotEmpty;

      // Для сложных фильтров с тегами используем кастомный SQL
      if (needsTagJoin) {
        return await _getNotesWithTagFilter(filter);
      }

      // Для простых фильтров используем стандартные Drift запросы
      return await _getNotesWithSimpleFilter(filter);
    } catch (e) {
      logError(
        'Ошибка получения отфильтрованных заметок',
        error: e,
        tag: 'NoteFilterDao',
      );
      // В случае ошибки возвращаем пустой список
      return <CardNoteDto>[];
    }
  }

  /// Подсчет количества отфильтрованных заметок
  Future<int> countFilteredNotes(NotesFilter filter) async {
    try {
      if (!filter.hasActiveConstraints) {
        return await _countAllNotes();
      }

      if (filter.base.tagIds.isNotEmpty) {
        return await _countNotesWithTagFilter(filter);
      }

      return await _countNotesWithSimpleFilter(filter);
    } catch (e) {
      return 0;
    }
  }

  /// Stream для наблюдения за отфильтрованными заметками
  Stream<List<CardNoteDto>> watchFilteredNotes(NotesFilter filter) {
    // Для простых случаев используем стандартные Drift streams
    if (!filter.hasActiveConstraints) {
      return _watchAllNotesWithBasicFilter(filter.base);
    }

    // Для сложных случаев возвращаем периодически обновляемый stream
    return Stream.periodic(
      const Duration(milliseconds: 500),
    ).asyncMap((_) => getFilteredNotes(filter)).distinct();
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Получение всех заметок с базовой фильтрацией
  Future<List<CardNoteDto>> _getAllNotesWithBasicFilter(
    BaseFilter baseFilter,
  ) async {
    final query = selectOnly(attachedDatabase.notes)
      ..addColumns([
        attachedDatabase.notes.id,
        attachedDatabase.notes.title,
        attachedDatabase.notes.description,
        attachedDatabase.notes.content,
        attachedDatabase.notes.categoryId,
        attachedDatabase.notes.isFavorite,
        attachedDatabase.notes.isPinned,
        attachedDatabase.notes.createdAt,
        attachedDatabase.notes.modifiedAt,
        attachedDatabase.notes.lastAccessed,
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

  /// Получение заметок с простой фильтрацией (без тегов)
  Future<List<CardNoteDto>> _getNotesWithSimpleFilter(
    NotesFilter filter,
  ) async {
    final query = selectOnly(attachedDatabase.notes)
      ..addColumns([
        attachedDatabase.notes.id,
        attachedDatabase.notes.title,
        attachedDatabase.notes.description,
        attachedDatabase.notes.content,
        attachedDatabase.notes.categoryId,
        attachedDatabase.notes.isFavorite,
        attachedDatabase.notes.isPinned,
        attachedDatabase.notes.createdAt,
        attachedDatabase.notes.modifiedAt,
        attachedDatabase.notes.lastAccessed,
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

  /// Получение заметок с фильтрацией по тегам (кастомный SQL)
  Future<List<CardNoteDto>> _getNotesWithTagFilter(NotesFilter filter) async {
    final whereConditions = <String>[];
    final variables = <Variable>[];

    // Базовые условия
    _buildBaseWhereConditions(filter.base, whereConditions, variables);

    // Условия NotesFilter
    _buildNoteWhereConditions(filter, whereConditions, variables);

    // Условие для тегов
    if (filter.base.tagIds.isNotEmpty) {
      final tagPlaceholders = filter.base.tagIds.map((_) => '?').join(',');
      variables.addAll(filter.base.tagIds.map((id) => Variable(id)));

      whereConditions.add('''
        n.id IN (
          SELECT DISTINCT nt.note_id
          FROM note_tags nt
          WHERE nt.tag_id IN ($tagPlaceholders)
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
      SELECT DISTINCT n.id, n.title, n.description, n.content, 
             n.category_id, n.is_favorite, n.is_pinned, 
             n.created_at, n.modified_at, n.last_accessed 
      FROM notes n
      $whereClause
      $orderBy
      $limitClause
    ''';

    final results = await customSelect(sql, variables: variables).get();
    return await _convertCustomResultsToCardDtos(results);
  }

  /// Подсчет всех заметок
  Future<int> _countAllNotes() async {
    final query = selectOnly(attachedDatabase.notes)
      ..addColumns([attachedDatabase.notes.id.count()]);

    final result = await query.getSingle();
    return result.read(attachedDatabase.notes.id.count()) ?? 0;
  }

  /// Подсчет заметок с простой фильтрацией
  Future<int> _countNotesWithSimpleFilter(NotesFilter filter) async {
    final query = selectOnly(attachedDatabase.notes)
      ..addColumns([attachedDatabase.notes.id.count()]);

    _applyAllFilters(query, filter);

    final result = await query.getSingle();
    return result.read(attachedDatabase.notes.id.count()) ?? 0;
  }

  /// Подсчет заметок с фильтрацией по тегам
  Future<int> _countNotesWithTagFilter(NotesFilter filter) async {
    final whereConditions = <String>[];
    final variables = <Variable>[];

    _buildBaseWhereConditions(filter.base, whereConditions, variables);
    _buildNoteWhereConditions(filter, whereConditions, variables);

    if (filter.base.tagIds.isNotEmpty) {
      final tagPlaceholders = filter.base.tagIds.map((_) => '?').join(',');
      variables.addAll(filter.base.tagIds.map((id) => Variable(id)));

      whereConditions.add('''
        n.id IN (
          SELECT DISTINCT nt.note_id
          FROM note_tags nt
          WHERE nt.tag_id IN ($tagPlaceholders)
        )
      ''');
    }

    final whereClause = whereConditions.isNotEmpty
        ? 'WHERE ${whereConditions.join(' AND ')}'
        : '';

    final sql =
        '''
      SELECT COUNT(DISTINCT n.id) as count 
      FROM notes n
      $whereClause
    ''';

    final result = await customSelect(sql, variables: variables).getSingle();
    return result.read<int>('count');
  }

  /// Stream для наблюдения за всеми заметками с базовой фильтрацией
  Stream<List<CardNoteDto>> _watchAllNotesWithBasicFilter(
    BaseFilter baseFilter,
  ) {
    final query = selectOnly(attachedDatabase.notes)
      ..addColumns([
        attachedDatabase.notes.id,
        attachedDatabase.notes.title,
        attachedDatabase.notes.description,
        attachedDatabase.notes.content,
        attachedDatabase.notes.categoryId,
        attachedDatabase.notes.isFavorite,
        attachedDatabase.notes.isPinned,
        attachedDatabase.notes.createdAt,
        attachedDatabase.notes.modifiedAt,
        attachedDatabase.notes.lastAccessed,
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
        attachedDatabase.notes.title.lower().like(searchTerm) |
            attachedDatabase.notes.content.lower().like(searchTerm) |
            attachedDatabase.notes.description.lower().like(searchTerm),
      );
    }

    // Категории
    if (filter.categoryIds.isNotEmpty) {
      conditions.add(
        attachedDatabase.notes.categoryId.isIn(filter.categoryIds),
      );
    }

    // Флаги
    if (filter.isFavorite != null) {
      conditions.add(
        attachedDatabase.notes.isFavorite.equals(filter.isFavorite!),
      );
    }

    if (filter.isArchived != null) {
      // Заметки не имеют флага isArchived, пропускаем
      // Это условие оставлено для совместимости с BaseFilter
    }

    if (filter.hasNotes != null) {
      // Это условие не применимо для заметок, пропускаем
    }

    // Диапазоны дат
    if (filter.createdAfter != null) {
      conditions.add(
        attachedDatabase.notes.createdAt.isBiggerOrEqualValue(
          filter.createdAfter!,
        ),
      );
    }
    if (filter.createdBefore != null) {
      conditions.add(
        attachedDatabase.notes.createdAt.isSmallerOrEqualValue(
          filter.createdBefore!,
        ),
      );
    }

    if (filter.modifiedAfter != null) {
      conditions.add(
        attachedDatabase.notes.modifiedAt.isBiggerOrEqualValue(
          filter.modifiedAfter!,
        ),
      );
    }
    if (filter.modifiedBefore != null) {
      conditions.add(
        attachedDatabase.notes.modifiedAt.isSmallerOrEqualValue(
          filter.modifiedBefore!,
        ),
      );
    }

    if (filter.lastAccessedAfter != null) {
      conditions.add(
        attachedDatabase.notes.lastAccessed.isBiggerOrEqualValue(
          filter.lastAccessedAfter!,
        ),
      );
    }
    if (filter.lastAccessedBefore != null) {
      conditions.add(
        attachedDatabase.notes.lastAccessed.isSmallerOrEqualValue(
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
  void _applyAllFilters(JoinedSelectStatement query, NotesFilter filter) {
    // Сначала применяем базовые фильтры
    _applyBaseFilters(query, filter.base);

    final conditions = <Expression<bool>>[];

    // Специфичные для заметок фильтры
    if (filter.title != null) {
      conditions.add(
        attachedDatabase.notes.title.lower().like(
          '%${filter.title!.toLowerCase()}%',
        ),
      );
    }

    if (filter.content != null) {
      conditions.add(
        attachedDatabase.notes.content.lower().like(
          '%${filter.content!.toLowerCase()}%',
        ),
      );
    }

    if (filter.isPined != null) {
      conditions.add(attachedDatabase.notes.isPinned.equals(filter.isPined!));
    }

    if (filter.hasContent != null) {
      if (filter.hasContent!) {
        conditions.add(
          attachedDatabase.notes.content.isNotNull() &
              attachedDatabase.notes.content.isNotValue(''),
        );
      } else {
        conditions.add(
          attachedDatabase.notes.content.isNull() |
              attachedDatabase.notes.content.equals(''),
        );
      }
    }

    if (filter.minContentLength != null) {
      conditions.add(
        attachedDatabase.notes.content.length.isBiggerOrEqualValue(
          filter.minContentLength!,
        ),
      );
    }

    if (filter.maxContentLength != null) {
      conditions.add(
        attachedDatabase.notes.content.length.isSmallerOrEqualValue(
          filter.maxContentLength!,
        ),
      );
    }

    // hasAttachments не реализовано в текущей схеме заметок
    // Оставлено для будущего расширения

    // Применяем дополнительные условия
    if (conditions.isNotEmpty) {
      final combinedCondition = conditions.reduce((a, b) => a & b);
      query.where(combinedCondition);
    }
  }

  /// Применение сортировки к запросу
  void _applySorting(
    JoinedSelectStatement query,
    NotesSortField? sortField,
    SortDirection direction,
  ) {
    switch (sortField) {
      case NotesSortField.title:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.notes.title)
              : OrderingTerm.desc(attachedDatabase.notes.title),
        ]);
        break;
      case NotesSortField.createdAt:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.notes.createdAt)
              : OrderingTerm.desc(attachedDatabase.notes.createdAt),
        ]);
        break;
      case NotesSortField.modifiedAt:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.notes.modifiedAt)
              : OrderingTerm.desc(attachedDatabase.notes.modifiedAt),
        ]);
        break;
      case NotesSortField.lastAccessed:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.notes.lastAccessed)
              : OrderingTerm.desc(attachedDatabase.notes.lastAccessed),
        ]);
        break;
      case NotesSortField.contentLength:
        query.orderBy([
          direction == SortDirection.asc
              ? OrderingTerm.asc(attachedDatabase.notes.content.length)
              : OrderingTerm.desc(attachedDatabase.notes.content.length),
        ]);
        break;
      default:
        // По умолчанию сортируем по дате изменения (закрепленные вверху)
        query.orderBy([
          OrderingTerm.desc(attachedDatabase.notes.isPinned),
          OrderingTerm.desc(attachedDatabase.notes.modifiedAt),
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
        (LOWER(n.title) LIKE ? OR LOWER(n.content) LIKE ? OR 
         LOWER(n.description) LIKE ?)
      ''');
      final searchTerm = '%${filter.query.toLowerCase()}%';
      variables.addAll([
        Variable(searchTerm),
        Variable(searchTerm),
        Variable(searchTerm),
      ]);
    }

    // Категории
    if (filter.categoryIds.isNotEmpty) {
      final placeholders = filter.categoryIds.map((_) => '?').join(',');
      conditions.add('n.category_id IN ($placeholders)');
      variables.addAll(filter.categoryIds.map((id) => Variable(id)));
    }

    // Флаги
    if (filter.isFavorite != null) {
      conditions.add('n.is_favorite = ?');
      variables.add(Variable(filter.isFavorite!));
    }

    // isArchived не применим для заметок

    // Диапазоны дат
    if (filter.createdAfter != null) {
      conditions.add('n.created_at >= ?');
      variables.add(Variable(filter.createdAfter!));
    }
    if (filter.createdBefore != null) {
      conditions.add('n.created_at <= ?');
      variables.add(Variable(filter.createdBefore!));
    }

    if (filter.modifiedAfter != null) {
      conditions.add('n.modified_at >= ?');
      variables.add(Variable(filter.modifiedAfter!));
    }
    if (filter.modifiedBefore != null) {
      conditions.add('n.modified_at <= ?');
      variables.add(Variable(filter.modifiedBefore!));
    }

    if (filter.lastAccessedAfter != null) {
      conditions.add('n.last_accessed >= ?');
      variables.add(Variable(filter.lastAccessedAfter!));
    }
    if (filter.lastAccessedBefore != null) {
      conditions.add('n.last_accessed <= ?');
      variables.add(Variable(filter.lastAccessedBefore!));
    }
  }

  /// Построение WHERE условий для NotesFilter в кастомном SQL
  void _buildNoteWhereConditions(
    NotesFilter filter,
    List<String> conditions,
    List<Variable> variables,
  ) {
    if (filter.title != null) {
      conditions.add('LOWER(n.title) LIKE ?');
      variables.add(Variable('%${filter.title!.toLowerCase()}%'));
    }

    if (filter.content != null) {
      conditions.add('LOWER(n.content) LIKE ?');
      variables.add(Variable('%${filter.content!.toLowerCase()}%'));
    }

    if (filter.isPined != null) {
      conditions.add('n.is_pinned = ?');
      variables.add(Variable(filter.isPined!));
    }

    if (filter.hasContent != null) {
      if (filter.hasContent!) {
        conditions.add('(n.content IS NOT NULL AND n.content != \'\')');
      } else {
        conditions.add('(n.content IS NULL OR n.content = \'\')');
      }
    }

    if (filter.minContentLength != null) {
      conditions.add('LENGTH(n.content) >= ?');
      variables.add(Variable(filter.minContentLength!));
    }

    if (filter.maxContentLength != null) {
      conditions.add('LENGTH(n.content) <= ?');
      variables.add(Variable(filter.maxContentLength!));
    }

    // hasAttachments - будущее расширение
  }

  /// Построение ORDER BY клаузулы для кастомного SQL
  String _buildOrderByClause(
    NotesSortField? sortField,
    SortDirection direction,
  ) {
    final dirStr = direction == SortDirection.asc ? 'ASC' : 'DESC';

    switch (sortField) {
      case NotesSortField.title:
        return 'ORDER BY n.title $dirStr';
      case NotesSortField.createdAt:
        return 'ORDER BY n.created_at $dirStr';
      case NotesSortField.modifiedAt:
        return 'ORDER BY n.modified_at $dirStr';
      case NotesSortField.lastAccessed:
        return 'ORDER BY n.last_accessed $dirStr';
      case NotesSortField.contentLength:
        return 'ORDER BY LENGTH(n.content) $dirStr';
      default:
        // По умолчанию: закрепленные сверху, затем по дате изменения
        return 'ORDER BY n.is_pinned DESC, n.modified_at DESC';
    }
  }

  // ==================== МЕТОДЫ КОНВЕРТАЦИИ ====================

  /// Конвертация результатов Drift запроса в CardNoteDto
  Future<List<CardNoteDto>> _convertResultsToCardDtos(
    List<TypedResult> results,
  ) async {
    final cardDtos = <CardNoteDto>[];

    for (final row in results) {
      final noteData = _NoteRowData(
        id: row.read(attachedDatabase.notes.id)!,
        title: row.read(attachedDatabase.notes.title)!,
        description: row.read(attachedDatabase.notes.description),
        content: row.read(attachedDatabase.notes.content)!,
        categoryId: row.read(attachedDatabase.notes.categoryId),
        isFavorite: row.read(attachedDatabase.notes.isFavorite)!,
        isPinned: row.read(attachedDatabase.notes.isPinned)!,
        createdAt: row.read(attachedDatabase.notes.createdAt)!,
        modifiedAt: row.read(attachedDatabase.notes.modifiedAt)!,
        lastAccessed: row.read(attachedDatabase.notes.lastAccessed),
      );

      final cardDto = await _noteDataToCardDto(noteData);
      cardDtos.add(cardDto);
    }

    return cardDtos;
  }

  /// Конвертация результатов кастомного SQL в CardNoteDto
  Future<List<CardNoteDto>> _convertCustomResultsToCardDtos(
    List<QueryRow> results,
  ) async {
    final cardDtos = <CardNoteDto>[];

    for (final row in results) {
      final noteData = _NoteRowData(
        id: row.read<String>('id'),
        title: row.read<String>('title'),
        description: row.read<String?>('description'),
        content: row.read<String>('content'),
        categoryId: row.read<String?>('category_id'),
        isFavorite: row.read<bool>('is_favorite'),
        isPinned: row.read<bool>('is_pinned'),
        createdAt: row.read<DateTime>('created_at'),
        modifiedAt: row.read<DateTime>('modified_at'),
        lastAccessed: row.read<DateTime?>('last_accessed'),
      );

      final cardDto = await _noteDataToCardDto(noteData);
      cardDtos.add(cardDto);
    }

    return cardDtos;
  }

  /// Преобразование данных заметки в CardNoteDto
  Future<CardNoteDto> _noteDataToCardDto(_NoteRowData data) async {
    final category = await _getCategoryForNote(data.categoryId);
    final tags = await _getTagsForNote(data.id);

    // Создаем превью контента (максимум 200 символов)
    String? contentPreview;
    if (data.content.isNotEmpty) {
      contentPreview = data.content.length > 200
          ? '${data.content.substring(0, 200)}...'
          : data.content;
    }

    return CardNoteDto(
      id: data.id,
      title: data.title,
      description: data.description,
      content: contentPreview,
      category: category,
      tags: tags.isNotEmpty ? tags : null,
      isFavorite: data.isFavorite,
      isPinned: data.isPinned,
      lastAccessed: data.lastAccessed,
    );
  }

  /// Получение категории заметки для CardNoteDto
  Future<CardCategoryDto?> _getCategoryForNote(String? categoryId) async {
    if (categoryId == null) return null;

    final category = await (select(
      attachedDatabase.categories,
    )..where((tbl) => tbl.id.equals(categoryId))).getSingleOrNull();

    if (category == null) return null;

    return CardCategoryDto(name: category.name, color: category.color);
  }

  /// Получение тегов заметки для CardNoteDto (максимум 4)
  Future<List<CardTagDto>> _getTagsForNote(String noteId) async {
    final query =
        select(attachedDatabase.tags).join([
            innerJoin(
              attachedDatabase.noteTags,
              attachedDatabase.noteTags.tagId.equalsExp(
                attachedDatabase.tags.id,
              ),
            ),
          ])
          ..where(attachedDatabase.noteTags.noteId.equals(noteId))
          ..limit(4); // Ограничиваем количество тегов

    final results = await query.get();

    return results.map((row) {
      final tag = row.readTable(attachedDatabase.tags);
      return CardTagDto(name: tag.name, color: tag.color ?? 'FFFFFF');
    }).toList();
  }
}
