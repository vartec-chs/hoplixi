import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/core/theme/colors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/dao/categories_dao.dart';
import 'widgets/category_filter_modal.dart';

/// Виджет для фильтрации категорий с поддержкой модального окна/bottom sheet
class CategoryFilterWidget extends ConsumerStatefulWidget {
  /// Тип категорий для фильтрации (обязательный параметр)
  final CategoryType categoryType;

  /// Выбранные категории
  final List<store.Category> selectedCategories;

  /// Callback при выборе категории
  final void Function(store.Category category) onSelect;

  /// Callback при удалении категории из выбора
  final void Function(store.Category category) onRemove;

  /// Callback при очистке всех выбранных категорий
  final void Function() onClearAll;

  /// Callback при применении фильтра (опционально)
  final void Function(List<store.Category> categories)? onApplyFilter;

  /// Placeholder для поля поиска
  final String? searchPlaceholder;

  /// Заголовок модального окна
  final String? modalTitle;

  /// Максимальное количество выбранных категорий (по умолчанию без ограничений)
  final int? maxSelectedCategories;

  /// Показывать ли счетчик выбранных категорий
  final bool showSelectedCount;

  /// Включить ли режим только для чтения
  final bool readOnly;

  /// Кастомная высота виджета
  final double? height;

  /// Кастомная ширина виджета
  final double? width;

  /// Размер страницы для пагинации
  final int pageSize;

  /// Сортировка категорий
  final CategorySortBy sortBy;

  /// По возрастанию ли сортировать
  final bool ascending;

  const CategoryFilterWidget({
    super.key,
    required this.categoryType,
    required this.selectedCategories,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
    this.onApplyFilter,
    this.searchPlaceholder,
    this.modalTitle,
    this.maxSelectedCategories,
    this.showSelectedCount = true,
    this.readOnly = false,
    this.height,
    this.width,
    this.pageSize = 20,
    this.sortBy = CategorySortBy.name,
    this.ascending = true,
  });

  @override
  ConsumerState<CategoryFilterWidget> createState() =>
      _CategoryFilterWidgetState();
}

class _CategoryFilterWidgetState extends ConsumerState<CategoryFilterWidget> {
  final TextEditingController _controller = TextEditingController();

  // Timer для дебаунсинга обновлений
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateDisplayText();
  }

  @override
  void didUpdateWidget(CategoryFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    logDebug(
      'Обновление CategoryFilterWidget',
      tag: 'CategoryFilterWidget',
      data: {
        'oldSelectedCount': oldWidget.selectedCategories.length,
        'newSelectedCount': widget.selectedCategories.length,
        'oldCategoryNames': oldWidget.selectedCategories
            .map((cat) => cat.name)
            .toList(),
        'newCategoryNames': widget.selectedCategories
            .map((cat) => cat.name)
            .toList(),
        'identical': identical(
          oldWidget.selectedCategories,
          widget.selectedCategories,
        ),
        'listEquals': oldWidget.selectedCategories == widget.selectedCategories,
      },
    );

    // Если это тот же объект списка, но произошли изменения,
    // всегда обновляем текст для безопасности
    if (identical(oldWidget.selectedCategories, widget.selectedCategories)) {
      logDebug(
        'Обнаружен тот же объект списка категорий, принудительное обновление текста',
        tag: 'CategoryFilterWidget',
      );
      _scheduleUpdate();
      return;
    }

    // Проверяем изменения в списке категорий более детально
    if (_categoriesChanged(
      oldWidget.selectedCategories,
      widget.selectedCategories,
    )) {
      logDebug(
        'Изменение в списке выбранных категорий обнаружено, планирование обновления текста',
        tag: 'CategoryFilterWidget',
      );
      _scheduleUpdate();
    } else {
      logDebug(
        'Изменений в списке выбранных категорий не обнаружено',
        tag: 'CategoryFilterWidget',
      );
    }
  }

  void _scheduleUpdate() {
    // Отменяем предыдущий таймер, если он есть
    _updateTimer?.cancel();

    // Планируем обновление с небольшой задержкой
    _updateTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        logDebug(
          'Выполнение отложенного обновления текста категорий',
          tag: 'CategoryFilterWidget',
        );
        _updateDisplayText();
      }
    });
  }

  /// Проверяет, изменился ли список категорий
  bool _categoriesChanged(
    List<store.Category> oldCategories,
    List<store.Category> newCategories,
  ) {
    logDebug(
      'Проверка изменений в списке категорий',
      tag: 'CategoryFilterWidget',
      data: {
        'oldCategories': oldCategories.map((cat) => cat.name).toList(),
        'newCategories': newCategories.map((cat) => cat.name).toList(),
      },
    );

    // Если оба списка пусты, изменений нет
    if (oldCategories.isEmpty && newCategories.isEmpty) {
      return false;
    }

    // Сначала проверяем длину
    if (oldCategories.length != newCategories.length) {
      logDebug(
        'Длина списков категорий различается',
        tag: 'CategoryFilterWidget',
        data: {
          'oldLength': oldCategories.length,
          'newLength': newCategories.length,
        },
      );
      return true;
    }

    // Если длина одинаковая, сравниваем ID категорий
    final oldCategoryIds = oldCategories.map((cat) => cat.id).toSet();
    final newCategoryIds = newCategories.map((cat) => cat.id).toSet();

    // Проверяем, есть ли разница в множествах ID
    final hasChanges =
        oldCategoryIds.difference(newCategoryIds).isNotEmpty ||
        newCategoryIds.difference(oldCategoryIds).isNotEmpty;

    if (hasChanges) {
      logDebug(
        'ID категорий изменились',
        tag: 'CategoryFilterWidget',
        data: {
          'oldCategoryIds': oldCategoryIds.toList(),
          'newCategoryIds': newCategoryIds.toList(),
          'added': newCategoryIds.difference(oldCategoryIds).toList(),
          'removed': oldCategoryIds.difference(newCategoryIds).toList(),
        },
      );
    }

    return hasChanges;
  }

  void _updateDisplayText() {
    final count = widget.selectedCategories.length;
    logDebug(
      'Обновление текста фильтра категорий',
      tag: 'CategoryFilterWidget',
      data: {'categoryType': widget.categoryType.name, 'selectedCount': count},
    );

    String newText;
    if (count == 0) {
      newText = widget.searchPlaceholder ?? _getDefaultPlaceholder();
    } else {
      final categoryNames = widget.selectedCategories
          .take(2)
          .map((category) => category.name)
          .join(', ');
      if (count > 2) {
        newText = '$categoryNames и ещё ${count - 2}';
      } else {
        newText = categoryNames;
      }
    }

    logDebug(
      'Сравнение текста для обновления',
      tag: 'CategoryFilterWidget',
      data: {
        'currentText': _controller.text,
        'newText': newText,
        'needsUpdate': _controller.text != newText,
      },
    );

    // Обновляем текст только если он действительно изменился
    if (_controller.text != newText) {
      logDebug(
        'Текст изменился, обновление',
        tag: 'CategoryFilterWidget',
        data: {'oldText': _controller.text, 'newText': newText},
      );
      setState(() {
        _controller.text = newText;
      });
    } else {
      logDebug(
        'Текст не изменился, пропуск обновления',
        tag: 'CategoryFilterWidget',
        data: {'text': newText},
      );
    }
  }

  String _getDefaultPlaceholder() {
    switch (widget.categoryType) {
      case CategoryType.notes:
        return 'Выберите категории заметок';
      case CategoryType.password:
        return 'Выберите категории паролей';
      case CategoryType.totp:
        return 'Выберите категории TOTP';
      case CategoryType.mixed:
        return 'Выберите категории';
    }
  }

  void _openCategorySelector() async {
    if (widget.readOnly) return;

    logDebug(
      'Открытие селектора категорий',
      tag: 'CategoryFilterWidget',
      data: {
        'categoryType': widget.categoryType.name,
        'selectedCount': widget.selectedCategories.length,
      },
    );

    try {
      final result = await _showCategorySelector();

      if (result != null && widget.onApplyFilter != null) {
        widget.onApplyFilter!(result);
        logDebug(
          'Применен фильтр категорий',
          tag: 'CategoryFilterWidget',
          data: {
            'categoryType': widget.categoryType.name,
            'selectedCount': result.length,
          },
        );
      }
    } catch (e, s) {
      logError(
        'Ошибка при открытии селектора категорий',
        error: e,
        stackTrace: s,
        tag: 'CategoryFilterWidget',
      );
    }
  }

  Future<List<store.Category>?> _showCategorySelector() async {
    // Определяем, мобильная ли платформа
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return await showModalBottomSheet<List<store.Category>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CategoryFilterModal(
          categoryType: widget.categoryType,
          selectedCategories: List.from(widget.selectedCategories),
          onCategorySelect: widget.onSelect,
          onCategoryRemove: widget.onRemove,
          onClearAll: widget.onClearAll,
          title: widget.modalTitle ?? _getDefaultTitle(),
          maxSelectedCategories: widget.maxSelectedCategories,
          isMobile: true,
          pageSize: widget.pageSize,
          sortBy: widget.sortBy,
          ascending: widget.ascending,
        ),
      );
    } else {
      return await showDialog<List<store.Category>>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: 600,
            height: 700,
            child: CategoryFilterModal(
              categoryType: widget.categoryType,
              selectedCategories: List.from(widget.selectedCategories),
              onCategorySelect: widget.onSelect,
              onCategoryRemove: widget.onRemove,
              onClearAll: widget.onClearAll,
              title: widget.modalTitle ?? _getDefaultTitle(),
              maxSelectedCategories: widget.maxSelectedCategories,
              isMobile: false,
              pageSize: widget.pageSize,
              sortBy: widget.sortBy,
              ascending: widget.ascending,
            ),
          ),
        ),
      );
    }
  }

  String _getDefaultTitle() {
    switch (widget.categoryType) {
      case CategoryType.notes:
        return 'Фильтр категорий заметок';
      case CategoryType.password:
        return 'Фильтр категорий паролей';
      case CategoryType.totp:
        return 'Фильтр категорий TOTP';
      case CategoryType.mixed:
        return 'Фильтр категорий';
    }
  }

  void _clearFilter() {
    if (widget.readOnly) return;

    logDebug(
      'Очистка фильтра категорий',
      tag: 'CategoryFilterWidget',
      data: {
        'categoryType': widget.categoryType.name,
        'clearedCount': widget.selectedCategories.length,
      },
    );

    widget.onClearAll();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: widget.height ?? 56,
      width: widget.width,
      child: Row(
        children: [
          // Основное поле с выбранными категориями
          Expanded(
            child: GestureDetector(
              onTap: _openCategorySelector,
              child: AbsorbPointer(
                child: PrimaryTextField(
                  controller: _controller,
                  label: 'Фильтр по категориям',
                  readOnly: true,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Счетчик выбранных категорий
                      if (widget.showSelectedCount &&
                          widget.selectedCategories.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.lightColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.selectedCategories.length}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // Иконка раскрытия
                      Icon(
                        Icons.arrow_drop_down,
                        color: widget.readOnly
                            ? theme.disabledColor
                            : theme.iconTheme.color,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Кнопка очистки
          if (widget.selectedCategories.isNotEmpty && !widget.readOnly)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: IconButton(
                onPressed: _clearFilter,
                icon: Icon(Icons.clear, color: theme.colorScheme.error),
                tooltip: 'Очистить фильтр',
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
