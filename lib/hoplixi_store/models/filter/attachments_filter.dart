import 'package:freezed_annotation/freezed_annotation.dart';
import 'base_filter.dart';

part 'attachments_filter.freezed.dart';
part 'attachments_filter.g.dart';

enum AttachmentType { password, totp, note }

enum AttachmentsSortField { name, fileSize, createdAt, modifiedAt, mimeType }

@freezed
abstract class AttachmentsFilter with _$AttachmentsFilter {
  const factory AttachmentsFilter({
    required BaseFilter base,
    String? name, // фильтр по имени файла
    String? description, // фильтр по описанию
    List<String>?
    mimeTypes, // фильтр по MIME типам (image/png, application/pdf и т.д.)
    int? minFileSize, // минимальный размер файла в байтах
    int? maxFileSize, // максимальный размер файла в байтах
    AttachmentType? attachedToType, // к чему прикреплено (password/totp/note)
    String? attachedToId, // конкретный ID родительского объекта
    bool? hasChecksum, // есть ли контрольная сумма
    String? fileExtension, // фильтр по расширению файла
    AttachmentsSortField? sortField,
    @Default(SortDirection.desc) SortDirection sortDirection,
  }) = _AttachmentsFilter;

  factory AttachmentsFilter.create({
    BaseFilter? base,
    String? name,
    String? description,
    List<String>? mimeTypes,
    int? minFileSize,
    int? maxFileSize,
    AttachmentType? attachedToType,
    String? attachedToId,
    bool? hasChecksum,
    String? fileExtension,
    AttachmentsSortField? sortField,
    SortDirection? sortDirection,
  }) {
    final normalizedName = name?.trim();
    final normalizedDescription = description?.trim();
    final normalizedMimeTypes = mimeTypes
        ?.where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim().toLowerCase())
        .toSet()
        .toList();
    final normalizedExtension = fileExtension?.trim().toLowerCase();

    // Валидация размера файла
    int? validMinSize = minFileSize;
    int? validMaxSize = maxFileSize;

    if (minFileSize != null && minFileSize < 0) {
      validMinSize = 0;
    }

    if (maxFileSize != null && maxFileSize < 0) {
      validMaxSize = null;
    }

    if (validMinSize != null &&
        validMaxSize != null &&
        validMinSize > validMaxSize) {
      validMaxSize = null;
    }

    return AttachmentsFilter(
      base: base ?? const BaseFilter(),
      name: normalizedName?.isEmpty == true ? null : normalizedName,
      description: normalizedDescription?.isEmpty == true
          ? null
          : normalizedDescription,
      mimeTypes: normalizedMimeTypes?.isEmpty == true
          ? null
          : normalizedMimeTypes,
      minFileSize: validMinSize,
      maxFileSize: validMaxSize,
      attachedToType: attachedToType,
      attachedToId: attachedToId?.trim().isEmpty == true
          ? null
          : attachedToId?.trim(),
      hasChecksum: hasChecksum,
      fileExtension: normalizedExtension?.isEmpty == true
          ? null
          : normalizedExtension,
      sortField: sortField,
      sortDirection: sortDirection ?? SortDirection.desc,
    );
  }

  factory AttachmentsFilter.fromJson(Map<String, dynamic> json) =>
      _$AttachmentsFilterFromJson(json);
}

extension AttachmentsFilterHelpers on AttachmentsFilter {
  bool get hasActiveConstraints {
    if (base.hasActiveConstraints) return true;
    if (name != null) return true;
    if (description != null) return true;
    if (mimeTypes != null && mimeTypes!.isNotEmpty) return true;
    if (minFileSize != null) return true;
    if (maxFileSize != null) return true;
    if (attachedToType != null) return true;
    if (attachedToId != null) return true;
    if (hasChecksum != null) return true;
    if (fileExtension != null) return true;
    return false;
  }

  /// Проверка валидности диапазона размера файла
  bool get isValidFileSizeRange {
    if (minFileSize != null && maxFileSize != null) {
      return minFileSize! <= maxFileSize!;
    }
    return true;
  }

  /// Генерация SQL условия для размера файла
  String fileSizeSqlCondition(String fileSizeColumn) {
    final conditions = <String>[];

    if (minFileSize != null) {
      conditions.add('$fileSizeColumn >= $minFileSize');
    }

    if (maxFileSize != null) {
      conditions.add('$fileSizeColumn <= $maxFileSize');
    }

    if (conditions.isEmpty) {
      return '1=1';
    }

    return conditions.join(' AND ');
  }

  /// Проверка является ли файл изображением
  bool get isImageFilter {
    return mimeTypes?.any((type) => type.startsWith('image/')) == true;
  }

  /// Проверка является ли файл документом
  bool get isDocumentFilter {
    const documentTypes = [
      'application/pdf',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
      'text/csv',
    ];
    return mimeTypes?.any((type) => documentTypes.contains(type)) == true;
  }

  /// Получение читаемого размера файла для фильтра
  String getReadableFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }
}
