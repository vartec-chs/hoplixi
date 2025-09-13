import 'package:freezed_annotation/freezed_annotation.dart';
part 'password_filter.freezed.dart';
part 'password_filter.g.dart';

/// Порог, после которого пароль считается "часто используемым".
/// (по вашей архитектуре: usedCount >= 100)
const int kFrequentUsedThreshold = 100;

/// Как объединять список фильтров (теги/категории)
enum MatchMode { any, all }

enum PasswordSortField { name, createdAt, modifiedAt, lastAccessed, usedCount }

enum SortDirection { asc, desc }

@freezed
abstract class PasswordFilter with _$PasswordFilter {
  const factory PasswordFilter({
    /// Поисковая строка (по умолчанию пустая — без поиска).
    @Default('') String query,

    /// Список id категорий (UUID). Пустой = не фильтровать по категориям.
    @Default(<String>[]) List<String> categoryIds,

    /// Список тегов (строки). Пустой = не фильтровать по тегам.
    @Default(<String>[]) List<String> tagIds,

    /// Как объединять категории: any = хоть одна, all = все (применимо для many-to-many).
    @Default(MatchMode.any) MatchMode categoriesMatch,

    /// Как объединять теги: any = хоть один, all = все.
    @Default(MatchMode.any) MatchMode tagsMatch,

    /// Флаги/ограничения.
    bool?
    isFavorite, // null = не учитывать, true = только избранные, false = только не избранные
    bool?
    isArchived, // null = не учитывать, true = только архив, false = только не-архив
    /// Есть заметки (notes) или нет.
    bool? hasNotes,

    /// Диапазоны по дате создания/обновления/последнего доступа.
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    DateTime? lastAccessedAfter,
    DateTime? lastAccessedBefore,

    /// Флаг "часто используемые" (null = не учитывать, true = только часто используемые, false = исключить часто используемые)
    bool? isFrequent,

    /// Сортировка и пагинация
    PasswordSortField? sortField,
    @Default(SortDirection.desc) SortDirection sortDirection,
    int? limit,
    int? offset,
  }) = _PasswordFilter;

  /// Фабричный конструктор для нормализации входных данных: убирает дубли в списках,
  /// тримит query и т.п.
  factory PasswordFilter.create({
    String? query,
    List<String>? categoryIds,
    List<String>? tagIds,
    MatchMode? categoriesMatch,
    MatchMode? tagsMatch,
    bool? isFavorite,
    bool? isArchived,
    bool? hasNotes,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    DateTime? lastAccessedAfter,
    DateTime? lastAccessedBefore,
    bool? isFrequent,
    PasswordSortField? sortField,
    SortDirection? sortDirection,
    int? limit,
    int? offset,
  }) {
    final normalizedQuery = (query ?? '').trim();
    final normalizedCategoryIds = (categoryIds ?? <String>[])
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();
    final normalizedTagIds = (tagIds ?? <String>[])
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .toList();

    return PasswordFilter(
      query: normalizedQuery,
      categoryIds: normalizedCategoryIds,
      tagIds: normalizedTagIds,
      categoriesMatch: categoriesMatch ?? MatchMode.any,
      tagsMatch: tagsMatch ?? MatchMode.any,
      isFavorite: isFavorite,
      isArchived: isArchived,
      hasNotes: hasNotes,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      modifiedAfter: modifiedAfter,
      modifiedBefore: modifiedBefore,
      lastAccessedAfter: lastAccessedAfter,
      lastAccessedBefore: lastAccessedBefore,
      isFrequent: isFrequent,
      sortField: sortField,
      sortDirection: sortDirection ?? SortDirection.desc,
      limit: limit,
      offset: offset,
    );
  }

  factory PasswordFilter.fromJson(Map<String, dynamic> json) =>
      _$PasswordFilterFromJson(json);
}

extension PasswordFilterHelpers on PasswordFilter {
  /// Есть ли активные ограничения (помогает понять, применять ли WHERE вообще).
  bool get hasActiveConstraints {
    if (query.isNotEmpty) return true;
    if (categoryIds.isNotEmpty) return true;
    if (tagIds.isNotEmpty) return true;
    if (isFavorite != null) return true;
    if (isArchived != null) return true;
    if (hasNotes != null) return true;
    if (createdAfter != null || createdBefore != null) return true;
    if (modifiedAfter != null || modifiedBefore != null) return true;
    if (lastAccessedAfter != null || lastAccessedBefore != null) return true;
    if (isFrequent != null) return true;
    return false;
  }

  /// Генератор SQL-условия для частых (пример логики — используется при построении WHERE).
  /// Интерпретация: часто = usedCount >= kFrequentUsedThreshold.
  String frequentSqlCondition(String usedCountColumn) {
    // Возвращаем SQL-фрагмент для вставки в WHERE (псевдо-заменитель параметров).
    if (isFrequent == null) {
      return '1=1';
    } else if (isFrequent == true) {
      return '$usedCountColumn >= $kFrequentUsedThreshold';
    } else {
      return '$usedCountColumn < $kFrequentUsedThreshold';
    }
  }
}
