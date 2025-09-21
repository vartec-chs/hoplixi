import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/attachments_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/notes_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/otp_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/password_filter.dart';
import 'package:hoplixi/features/password_manager/universal_filter/providers/entity_type_provider.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;

part 'universal_filter.freezed.dart';
part 'universal_filter.g.dart';

/// Универсальный фильтр, содержащий все возможные типы фильтров
@freezed
abstract class UniversalFilter with _$UniversalFilter {
  const factory UniversalFilter({
    required UniversalEntityType entityType,
    PasswordFilter? passwordFilter,
    NotesFilter? notesFilter,
    OtpFilter? otpFilter,
    AttachmentsFilter? attachmentsFilter,
  }) = _UniversalFilter;

  /// Создать пустой фильтр для указанного типа сущности
  factory UniversalFilter.empty(UniversalEntityType entityType) {
    switch (entityType) {
      case UniversalEntityType.password:
        return UniversalFilter(
          entityType: entityType,
          passwordFilter: const PasswordFilter(base: BaseFilter()),
        );
      case UniversalEntityType.note:
        return UniversalFilter(
          entityType: entityType,
          notesFilter: const NotesFilter(base: BaseFilter()),
        );
      case UniversalEntityType.otp:
        return UniversalFilter(
          entityType: entityType,
          otpFilter: const OtpFilter(base: BaseFilter()),
        );
      case UniversalEntityType.attachment:
        return UniversalFilter(
          entityType: entityType,
          attachmentsFilter: const AttachmentsFilter(base: BaseFilter()),
        );
    }
  }

  factory UniversalFilter.fromJson(Map<String, dynamic> json) =>
      _$UniversalFilterFromJson(json);
}

extension UniversalFilterHelpers on UniversalFilter {
  /// Получить активный фильтр в зависимости от типа сущности
  dynamic get activeFilter {
    switch (entityType) {
      case UniversalEntityType.password:
        return passwordFilter;
      case UniversalEntityType.note:
        return notesFilter;
      case UniversalEntityType.otp:
        return otpFilter;
      case UniversalEntityType.attachment:
        return attachmentsFilter;
    }
  }

  /// Проверить, есть ли активные ограничения в текущем фильтре
  bool get hasActiveConstraints {
    switch (entityType) {
      case UniversalEntityType.password:
        return passwordFilter?.hasActiveConstraints ?? false;
      case UniversalEntityType.note:
        return notesFilter?.hasActiveConstraints ?? false;
      case UniversalEntityType.otp:
        return otpFilter?.hasActiveConstraints ?? false;
      case UniversalEntityType.attachment:
        return attachmentsFilter?.hasActiveConstraints ?? false;
    }
  }

  /// Получить поисковый запрос из активного фильтра
  String get searchQuery {
    switch (entityType) {
      case UniversalEntityType.password:
        return passwordFilter?.base.query ?? '';
      case UniversalEntityType.note:
        return notesFilter?.base.query ?? '';
      case UniversalEntityType.otp:
        return otpFilter?.base.query ?? '';
      case UniversalEntityType.attachment:
        return attachmentsFilter?.base.query ?? '';
    }
  }

  /// Обновить поисковый запрос в активном фильтре
  UniversalFilter updateSearchQuery(String query) {
    switch (entityType) {
      case UniversalEntityType.password:
        final currentFilter =
            passwordFilter ?? const PasswordFilter(base: BaseFilter());
        return copyWith(
          passwordFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(query: query),
          ),
        );
      case UniversalEntityType.note:
        final currentFilter =
            notesFilter ?? const NotesFilter(base: BaseFilter());
        return copyWith(
          notesFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(query: query),
          ),
        );
      case UniversalEntityType.otp:
        final currentFilter = otpFilter ?? const OtpFilter(base: BaseFilter());
        return copyWith(
          otpFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(query: query),
          ),
        );
      case UniversalEntityType.attachment:
        final currentFilter =
            attachmentsFilter ?? const AttachmentsFilter(base: BaseFilter());
        return copyWith(
          attachmentsFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(query: query),
          ),
        );
    }
  }

  /// Обновить категории в активном фильтре
  UniversalFilter updateCategories(List<String> categoryIds) {
    switch (entityType) {
      case UniversalEntityType.password:
        final currentFilter =
            passwordFilter ?? const PasswordFilter(base: BaseFilter());
        return copyWith(
          passwordFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(categoryIds: categoryIds),
          ),
        );
      case UniversalEntityType.note:
        final currentFilter =
            notesFilter ?? const NotesFilter(base: BaseFilter());
        return copyWith(
          notesFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(categoryIds: categoryIds),
          ),
        );
      case UniversalEntityType.otp:
        final currentFilter = otpFilter ?? const OtpFilter(base: BaseFilter());
        return copyWith(
          otpFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(categoryIds: categoryIds),
          ),
        );
      case UniversalEntityType.attachment:
        final currentFilter =
            attachmentsFilter ?? const AttachmentsFilter(base: BaseFilter());
        return copyWith(
          attachmentsFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(categoryIds: categoryIds),
          ),
        );
    }
  }

  /// Обновить категории из объектов Category
  UniversalFilter updateCategoriesFromObjects(List<store.Category> categories) {
    return updateCategories(categories.map((c) => c.id).toList());
  }

  /// Обновить теги в активном фильтре
  UniversalFilter updateTags(List<String> tagIds) {
    switch (entityType) {
      case UniversalEntityType.password:
        final currentFilter =
            passwordFilter ?? const PasswordFilter(base: BaseFilter());
        return copyWith(
          passwordFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(tagIds: tagIds),
          ),
        );
      case UniversalEntityType.note:
        final currentFilter =
            notesFilter ?? const NotesFilter(base: BaseFilter());
        return copyWith(
          notesFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(tagIds: tagIds),
          ),
        );
      case UniversalEntityType.otp:
        final currentFilter = otpFilter ?? const OtpFilter(base: BaseFilter());
        return copyWith(
          otpFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(tagIds: tagIds),
          ),
        );
      case UniversalEntityType.attachment:
        final currentFilter =
            attachmentsFilter ?? const AttachmentsFilter(base: BaseFilter());
        return copyWith(
          attachmentsFilter: currentFilter.copyWith(
            base: currentFilter.base.copyWith(tagIds: tagIds),
          ),
        );
    }
  }

  /// Обновить теги из объектов Tag
  UniversalFilter updateTagsFromObjects(List<store.Tag> tags) {
    return updateTags(tags.map((t) => t.id).toList());
  }

  /// Сбросить фильтр к начальному состоянию
  UniversalFilter reset() {
    return UniversalFilter.empty(entityType).updateSearchQuery(searchQuery);
  }

  /// Получить список категорий из активного фильтра
  List<String> get categoryIds {
    switch (entityType) {
      case UniversalEntityType.password:
        return passwordFilter?.base.categoryIds ?? [];
      case UniversalEntityType.note:
        return notesFilter?.base.categoryIds ?? [];
      case UniversalEntityType.otp:
        return otpFilter?.base.categoryIds ?? [];
      case UniversalEntityType.attachment:
        return attachmentsFilter?.base.categoryIds ?? [];
    }
  }

  /// Получить список тегов из активного фильтра
  List<String> get tagIds {
    switch (entityType) {
      case UniversalEntityType.password:
        return passwordFilter?.base.tagIds ?? [];
      case UniversalEntityType.note:
        return notesFilter?.base.tagIds ?? [];
      case UniversalEntityType.otp:
        return otpFilter?.base.tagIds ?? [];
      case UniversalEntityType.attachment:
        return attachmentsFilter?.base.tagIds ?? [];
    }
  }
}
