/// Результат операции с сущностями в сервисах
class ServiceResult<T> {
  final bool success;
  final String? message;
  final T? data;

  ServiceResult({required this.success, this.message, this.data});

  ServiceResult.success({T? data, String? message})
    : success = true,
      message = message ?? 'Операция выполнена успешно',
      data = data;

  ServiceResult.error(String this.message) : success = false, data = null;
}

/// Результат операции с категорией
class CategoryResult extends ServiceResult<String> {
  final String? categoryId;

  CategoryResult({required super.success, super.message, this.categoryId})
    : super(data: categoryId);

  CategoryResult.success({String? categoryId, super.message})
    : categoryId = categoryId,
      super.success(data: categoryId);

  CategoryResult.error(super.message) : categoryId = null, super.error();
}

/// Результат операции с иконкой
class IconResult extends ServiceResult<String> {
  final String? iconId;

  IconResult({required super.success, super.message, this.iconId})
    : super(data: iconId);

  IconResult.success({String? iconId, super.message})
    : iconId = iconId,
      super.success(data: iconId);

  IconResult.error(super.message) : iconId = null, super.error();
}

/// Результат операции с тегом
class TagResult extends ServiceResult<String> {
  final String? tagId;

  TagResult({required super.success, super.message, this.tagId})
    : super(data: tagId);

  TagResult.success({String? tagId, super.message})
    : tagId = tagId,
      super.success(data: tagId);

  TagResult.error(super.message) : tagId = null, super.error();
}

/// Результат операции с паролем
class PasswordResult extends ServiceResult<String> {
  final String? passwordId;

  PasswordResult({required super.success, super.message, this.passwordId})
    : super(data: passwordId);

  PasswordResult.success({String? passwordId, super.message})
    : passwordId = passwordId,
      super.success(data: passwordId);

  PasswordResult.error(super.message) : passwordId = null, super.error();
}
