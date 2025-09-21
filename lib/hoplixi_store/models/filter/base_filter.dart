import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_filter.freezed.dart';
part 'base_filter.g.dart';

enum SortDirection { asc, desc }

@freezed
abstract class BaseFilter with _$BaseFilter {
  const factory BaseFilter({
    @Default('') String query,
    @Default(<String>[]) List<String> categoryIds,
    @Default(<String>[]) List<String> tagIds,
    bool? isFavorite,
    bool? isArchived,
    bool? hasNotes,
    bool? isPinned, // для notes
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    DateTime? lastAccessedAfter,
    DateTime? lastAccessedBefore,
    @Default(0) int? limit,
    @Default(0) int? offset,
  }) = _BaseFilter;

  factory BaseFilter.create({
    String? query,
    List<String>? categoryIds,
    List<String>? tagIds,
    bool? isFavorite,
    bool? isArchived,
    bool? hasNotes,
    bool? isPinned,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    DateTime? lastAccessedAfter,
    DateTime? lastAccessedBefore,
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

    return BaseFilter(
      query: normalizedQuery,
      categoryIds: normalizedCategoryIds,
      tagIds: normalizedTagIds,
      isFavorite: isFavorite,
      isArchived: isArchived,
      hasNotes: hasNotes,
      isPinned: isPinned,
      createdAfter: createdAfter,
      createdBefore: createdBefore,
      modifiedAfter: modifiedAfter,
      modifiedBefore: modifiedBefore,
      lastAccessedAfter: lastAccessedAfter,
      lastAccessedBefore: lastAccessedBefore,
      limit: limit,
      offset: offset,
    );
  }

  factory BaseFilter.fromJson(Map<String, dynamic> json) =>
      _$BaseFilterFromJson(json);
}

extension BaseFilterHelpers on BaseFilter {
  bool get hasActiveConstraints {
    if (query.isNotEmpty) return true;
    if (categoryIds.isNotEmpty) return true;
    if (tagIds.isNotEmpty) return true;
    if (isFavorite != null) return true;
    if (isArchived != null) return true;
    if (hasNotes != null) return true;
    if (isPinned != null) return true;
    if (createdAfter != null || createdBefore != null) return true;
    if (modifiedAfter != null || modifiedBefore != null) return true;
    if (lastAccessedAfter != null || lastAccessedBefore != null) return true;
    return false;
  }
}
