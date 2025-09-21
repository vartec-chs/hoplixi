import 'package:hoplixi/features/password_manager/universal_filter/universal_filter_barrel.dart';
import 'package:hoplixi/hoplixi_store/models/filter/attachments_filter.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

/// Миксин с helper методами для универсального фильтра
mixin FilterHelperMixin {
  /// Получить заголовок модального окна
  String getModalTitle(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return 'Фильтры паролей';
      case UniversalEntityType.note:
        return 'Фильтры заметок';
      case UniversalEntityType.otp:
        return 'Фильтры OTP';
      case UniversalEntityType.attachment:
        return 'Фильтры вложений';
    }
  }

  /// Получить подсказку для поиска
  String getSearchHint(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return 'Поиск по названию, логину, URL, заметкам...';
      case UniversalEntityType.note:
        return 'Поиск по заголовку, содержимому...';
      case UniversalEntityType.otp:
        return 'Поиск по issuer, аккаунту...';
      case UniversalEntityType.attachment:
        return 'Поиск по имени файла, описанию...';
    }
  }

  /// Получить тип категории для сущности
  CategoryType getCategoryType(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return CategoryType.password;
      case UniversalEntityType.note:
        return CategoryType.notes;
      case UniversalEntityType.otp:
        return CategoryType.totp;
      case UniversalEntityType.attachment:
        return CategoryType.mixed;
    }
  }

  /// Получить тип тега для сущности
  TagType getTagType(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return TagType.password;
      case UniversalEntityType.note:
        return TagType.notes;
      case UniversalEntityType.otp:
        return TagType.totp;
      case UniversalEntityType.attachment:
        return TagType.mixed;
    }
  }

  /// Получить метку для типа вложения
  String getAttachmentTypeLabel(AttachmentType type) {
    switch (type) {
      case AttachmentType.password:
        return 'Пароль';
      case AttachmentType.totp:
        return 'TOTP';
      case AttachmentType.note:
        return 'Заметка';
    }
  }

  /// Получить опции сортировки для типа сущности
  List<Map<String, String>> getSortOptions(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return [
          {'value': 'name', 'label': 'Название'},
          {'value': 'createdAt', 'label': 'Дата создания'},
          {'value': 'modifiedAt', 'label': 'Дата изменения'},
          {'value': 'lastAccessed', 'label': 'Последний доступ'},
          {'value': 'usedCount', 'label': 'Частота использования'},
        ];
      case UniversalEntityType.note:
        return [
          {'value': 'title', 'label': 'Заголовок'},
          {'value': 'createdAt', 'label': 'Дата создания'},
          {'value': 'modifiedAt', 'label': 'Дата изменения'},
          {'value': 'lastAccessed', 'label': 'Последний доступ'},
          {'value': 'contentLength', 'label': 'Длина содержимого'},
        ];
      case UniversalEntityType.otp:
        return [
          {'value': 'issuer', 'label': 'Издатель'},
          {'value': 'accountName', 'label': 'Имя аккаунта'},
          {'value': 'createdAt', 'label': 'Дата создания'},
          {'value': 'modifiedAt', 'label': 'Дата изменения'},
          {'value': 'lastAccessed', 'label': 'Последний доступ'},
        ];
      case UniversalEntityType.attachment:
        return [
          {'value': 'name', 'label': 'Название'},
          {'value': 'fileSize', 'label': 'Размер файла'},
          {'value': 'createdAt', 'label': 'Дата создания'},
          {'value': 'modifiedAt', 'label': 'Дата изменения'},
          {'value': 'mimeType', 'label': 'MIME тип'},
        ];
    }
  }
}
