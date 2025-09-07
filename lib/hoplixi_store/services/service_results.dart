/// Результат операции с сущностями в сервисах
class ServiceResult<T> {
  final bool success;
  final String? message;
  final T? data;

  ServiceResult({
    required this.success,
    this.message,
    this.data,
  });

  ServiceResult.success({
    T? data,
    String? message,
  }) : success = true,
        message = message ?? 'Операция выполнена успешно',
        data = data;

  ServiceResult.error(String this.message)
      : success = false,
        data = null;
}

/// Результат операции с категорией
class CategoryResult extends ServiceResult<String> {
  final String? categoryId;

  CategoryResult({
    required bool success,
    String? message,
    this.categoryId,
  }) : super(success: success, message: message, data: categoryId);

  CategoryResult.success({
    String? categoryId,
    String? message,
  }) : categoryId = categoryId,
        super.success(data: categoryId, message: message);

  CategoryResult.error(String message)
      : categoryId = null,
        super.error(message);
}

/// Результат операции с иконкой
class IconResult extends ServiceResult<String> {
  final String? iconId;

  IconResult({
    required bool success,
    String? message,
    this.iconId,
  }) : super(success: success, message: message, data: iconId);

  IconResult.success({
    String? iconId,
    String? message,
  }) : iconId = iconId,
        super.success(data: iconId, message: message);

  IconResult.error(String message)
      : iconId = null,
        super.error(message);
}

/// Результат операции с тегом
class TagResult extends ServiceResult<String> {
  final String? tagId;

  TagResult({
    required bool success,
    String? message,
    this.tagId,
  }) : super(success: success, message: message, data: tagId);

  TagResult.success({
    String? tagId,
    String? message,
  }) : tagId = tagId,
        super.success(data: tagId, message: message);

  TagResult.error(String message)
      : tagId = null,
        super.error(message);
}
