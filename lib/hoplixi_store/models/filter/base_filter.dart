import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_filter.freezed.dart';

@freezed
abstract class BaseFilter with _$BaseFilter {
  const factory BaseFilter({
    @Default('') String query,
    @Default(<String>[]) List<String> categoryIds,
    @Default(<String>[]) List<String> tagIds,
    bool? isFavorite,
    bool? isArchived,
    bool? hasNotes,
    DateTime? createdAfter,
    DateTime? createdBefore,
    DateTime? modifiedAfter,
    DateTime? modifiedBefore,
    DateTime? lastAccessedAfter,
    DateTime? lastAccessedBefore,
    @Default(0) int? limit,
    @Default(0) int? offset,
  }) = _BaseFilter;
}
