import 'package:freezed_annotation/freezed_annotation.dart';
import 'base_filter.dart';

part 'notes_filter.freezed.dart';
part 'notes_filter.g.dart';

enum NotesSortField {
  title,
  createdAt,
  modifiedAt,
  lastAccessed,
  contentLength,
}

@freezed
abstract class NotesFilter with _$NotesFilter {
  const factory NotesFilter({
    required BaseFilter base,
    String? title, // фильтр по заголовку
    String? content, // фильтр по содержимому
    bool? isPined,
    bool? hasContent, // есть ли содержимое
    int? minContentLength, // минимальная длина содержимого
    int? maxContentLength, // максимальная длина содержимого
    bool? hasAttachments, // есть ли вложения
    NotesSortField? sortField,
  }) = _NotesFilter;

  factory NotesFilter.create({
    BaseFilter? base,
    String? title,
    String? content,
    bool? isPinned,
    bool? hasContent,
    int? minContentLength,
    int? maxContentLength,
    bool? hasAttachments,
    NotesSortField? sortField,
  }) {
    final normalizedTitle = title?.trim();
    final normalizedContent = content?.trim();

    // Валидация длины содержимого
    int? validMinLength = minContentLength;
    int? validMaxLength = maxContentLength;

    if (minContentLength != null && minContentLength < 0) {
      validMinLength = 0;
    }

    if (maxContentLength != null && maxContentLength < 0) {
      validMaxLength = null;
    }

    if (validMinLength != null &&
        validMaxLength != null &&
        validMinLength > validMaxLength) {
      // Если минимум больше максимума, сбрасываем максимум
      validMaxLength = null;
    }

    return NotesFilter(
      base: base ?? const BaseFilter(),
      title: normalizedTitle?.isEmpty == true ? null : normalizedTitle,
      content: normalizedContent?.isEmpty == true ? null : normalizedContent,
      hasContent: hasContent,
      isPined: isPinned,
      minContentLength: validMinLength,
      maxContentLength: validMaxLength,
      hasAttachments: hasAttachments,
      sortField: sortField,
  
    );
  }

  factory NotesFilter.fromJson(Map<String, dynamic> json) =>
      _$NotesFilterFromJson(json);
}

extension NotesFilterHelpers on NotesFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (title != null) return true;
    if (isPined != null) return true;
    if (content != null) return true;
    if (hasContent != null) return true;
    if (minContentLength != null) return true;
    if (maxContentLength != null) return true;
    if (hasAttachments != null) return true;
    return false;
  }

  /// Проверка валидности диапазона длины содержимого
  bool get isValidContentLengthRange {
    if (minContentLength != null && maxContentLength != null) {
      return minContentLength! <= maxContentLength!;
    }
    return true;
  }

  /// Генерация SQL условия для длины содержимого
  String contentLengthSqlCondition(String contentColumn) {
    final conditions = <String>[];

    if (minContentLength != null) {
      conditions.add('LENGTH($contentColumn) >= $minContentLength');
    }

    if (maxContentLength != null) {
      conditions.add('LENGTH($contentColumn) <= $maxContentLength');
    }

    if (conditions.isEmpty) {
      return '1=1';
    }

    return conditions.join(' AND ');
  }
}
