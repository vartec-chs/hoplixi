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

  @override
  void initState() {
    super.initState();
    _updateDisplayText();
  }

  @override
  void didUpdateWidget(CategoryFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategories.length !=
        widget.selectedCategories.length) {
      _updateDisplayText();
    }
  }

  void _updateDisplayText() {
    final count = widget.selectedCategories.length;
    if (count == 0) {
      _controller.text = widget.searchPlaceholder ?? _getDefaultPlaceholder();
    } else {
      final categoryNames = widget.selectedCategories
          .take(2)
          .map((category) => category.name)
          .join(', ');
      if (count > 2) {
        _controller.text = '$categoryNames и ещё ${count - 2}';
      } else {
        _controller.text = categoryNames;
      }
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
    _controller.dispose();
    super.dispose();
  }
}
