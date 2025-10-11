import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter_models/notes_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter_models/base_filter.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'base_filter_provider.dart';

/// Провайдер для управления фильтром заметок
final notesFilterProvider = NotifierProvider<NotesFilterNotifier, NotesFilter>(
  () => NotesFilterNotifier(),
);

class NotesFilterNotifier extends Notifier<NotesFilter> {
  @override
  NotesFilter build() {
    logDebug('NotesFilterNotifier: Инициализация фильтра заметок');

    // Подписываемся на изменения базового фильтра
    ref.listen(baseFilterProvider, (previous, next) {
      logDebug('NotesFilterNotifier: Обновление базового фильтра');
      state = state.copyWith(base: next);
    });

    return NotesFilter(base: ref.read(baseFilterProvider));
  }

  /// Обновляет заголовок заметки
  void updateTitle(String? title) {
    final normalizedTitle = title?.trim();
    logDebug('NotesFilterNotifier: Обновление заголовка: $normalizedTitle');
    state = state.copyWith(
      title: normalizedTitle?.isEmpty == true ? null : normalizedTitle,
    );
  }

  /// Обновляет содержимое заметки
  void updateContent(String? content) {
    final normalizedContent = content?.trim();
    logDebug(
      'NotesFilterNotifier: Обновление содержимого: ${normalizedContent?.length ?? 0} символов',
    );
    state = state.copyWith(
      content: normalizedContent?.isEmpty == true ? null : normalizedContent,
    );
  }

  /// Обновляет фильтр закрепленных заметок
  void updateIsPinned(bool? isPinned) {
    logDebug('NotesFilterNotifier: Обновление фильтра закрепленных: $isPinned');
    state = state.copyWith(isPined: isPinned);
  }

  /// Обновляет фильтр наличия содержимого
  void updateHasContent(bool? hasContent) {
    logDebug(
      'NotesFilterNotifier: Обновление фильтра наличия содержимого: $hasContent',
    );
    state = state.copyWith(hasContent: hasContent);
  }

  /// Обновляет минимальную длину содержимого
  void updateMinContentLength(int? minLength) {
    logDebug(
      'NotesFilterNotifier: Обновление минимальной длины содержимого: $minLength',
    );

    // Валидация
    int? validMinLength = minLength;
    if (minLength != null && minLength < 0) {
      validMinLength = 0;
      logDebug(
        'NotesFilterNotifier: Исправлена отрицательная минимальная длина на 0',
      );
    }

    // Проверяем, что минимум не больше максимума
    if (validMinLength != null &&
        state.maxContentLength != null &&
        validMinLength > state.maxContentLength!) {
      logDebug(
        'NotesFilterNotifier: Минимальная длина больше максимальной, сбрасываем максимальную',
      );
      state = state.copyWith(
        minContentLength: validMinLength,
        maxContentLength: null,
      );
    } else {
      state = state.copyWith(minContentLength: validMinLength);
    }
  }

  /// Обновляет максимальную длину содержимого
  void updateMaxContentLength(int? maxLength) {
    logDebug(
      'NotesFilterNotifier: Обновление максимальной длины содержимого: $maxLength',
    );

    // Валидация
    int? validMaxLength = maxLength;
    if (maxLength != null && maxLength < 0) {
      validMaxLength = null;
      logDebug(
        'NotesFilterNotifier: Отрицательная максимальная длина сброшена',
      );
    }

    // Проверяем, что максимум не меньше минимума
    if (validMaxLength != null &&
        state.minContentLength != null &&
        validMaxLength < state.minContentLength!) {
      logDebug(
        'NotesFilterNotifier: Максимальная длина меньше минимальной, сбрасываем минимальную',
      );
      state = state.copyWith(
        minContentLength: null,
        maxContentLength: validMaxLength,
      );
    } else {
      state = state.copyWith(maxContentLength: validMaxLength);
    }
  }

  /// Обновляет диапазон длины содержимого
  void updateContentLengthRange(int? minLength, int? maxLength) {
    logDebug(
      'NotesFilterNotifier: Обновление диапазона длины содержимого: $minLength - $maxLength',
    );

    // Валидация
    int? validMinLength = minLength;
    int? validMaxLength = maxLength;

    if (minLength != null && minLength < 0) {
      validMinLength = 0;
    }

    if (maxLength != null && maxLength < 0) {
      validMaxLength = null;
    }

    if (validMinLength != null &&
        validMaxLength != null &&
        validMinLength > validMaxLength) {
      // Если минимум больше максимума, сбрасываем максимум
      validMaxLength = null;
    }

    state = state.copyWith(
      minContentLength: validMinLength,
      maxContentLength: validMaxLength,
    );
  }

  /// Обновляет фильтр наличия вложений
  void updateHasAttachments(bool? hasAttachments) {
    logDebug(
      'NotesFilterNotifier: Обновление фильтра наличия вложений: $hasAttachments',
    );
    state = state.copyWith(hasAttachments: hasAttachments);
  }

  /// Обновляет поле сортировки
  void updateSortField(NotesSortField? sortField) {
    logDebug('NotesFilterNotifier: Обновление поля сортировки: $sortField');
    state = state.copyWith(sortField: sortField);
  }

  /// Сбрасывает фильтр к начальному состоянию
  void reset() {
    logDebug('NotesFilterNotifier: Сброс фильтра заметок');
    state = NotesFilter(base: ref.read(baseFilterProvider));
  }

  /// Применяет новый фильтр заметок
  void applyFilter(NotesFilter filter) {
    logDebug('NotesFilterNotifier: Применение нового фильтра заметок');
    state = filter;
  }

  /// Создает новый фильтр с указанными параметрами
  void createFilter({
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
    logDebug('NotesFilterNotifier: Создание нового фильтра');
    final newFilter = NotesFilter.create(
      base: base ?? ref.read(baseFilterProvider),
      title: title,
      content: content,
      isPinned: isPinned,
      hasContent: hasContent,
      minContentLength: minContentLength,
      maxContentLength: maxContentLength,
      hasAttachments: hasAttachments,
      sortField: sortField,
    );
    state = newFilter;
  }

  /// Проверяет, есть ли активные ограничения
  bool get hasActiveConstraints => state.hasActiveConstraints;

  /// Проверяет валидность диапазона длины содержимого
  bool get isValidContentLengthRange => state.isValidContentLengthRange;

  /// Получает базовый фильтр
  BaseFilter get baseFilter => state.base;

  /// Обновляет базовый фильтр
  void updateBaseFilter(BaseFilter baseFilter) {
    logDebug('NotesFilterNotifier: Обновление базового фильтра');
    state = state.copyWith(base: baseFilter);
  }

  /// Генерирует SQL условие для длины содержимого
  String contentLengthSqlCondition(String contentColumn) {
    return state.contentLengthSqlCondition(contentColumn);
  }
}
