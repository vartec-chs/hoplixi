import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/widgets/button.dart';
import 'package:hoplixi/app/theme/colors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/dao/categories_dao.dart';
import 'category_filter_modal.dart';

/// Кнопка для открытия фильтра категорий
class CategoryFilterButton extends ConsumerStatefulWidget {
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

  /// Текст кнопки (если не задан, автоматически определяется)
  final String? buttonText;

  /// Заголовок модального окна
  final String? modalTitle;

  /// Максимальное количество выбранных категорий
  final int? maxSelectedCategories;

  /// Размер страницы для пагинации
  final int pageSize;

  /// Сортировка категорий
  final CategorySortBy sortBy;

  /// По возрастанию ли сортировать
  final bool ascending;

  /// Тип кнопки
  final SmoothButtonType buttonType;

  /// Иконка кнопки
  final Widget? icon;

  /// Размер кнопки
  final SmoothButtonSize buttonSize;

  /// Включить ли режим только для чтения
  final bool readOnly;

  const CategoryFilterButton({
    super.key,
    required this.categoryType,
    required this.selectedCategories,
    required this.onSelect,
    required this.onRemove,
    required this.onClearAll,
    this.onApplyFilter,
    this.buttonText,
    this.modalTitle,
    this.maxSelectedCategories,
    this.pageSize = 20,
    this.sortBy = CategorySortBy.name,
    this.ascending = true,
    this.buttonType = SmoothButtonType.filled,
    this.icon,
    this.buttonSize = SmoothButtonSize.medium,
    this.readOnly = false,
  });

  @override
  ConsumerState<CategoryFilterButton> createState() =>
      _CategoryFilterButtonState();
}

class _CategoryFilterButtonState extends ConsumerState<CategoryFilterButton> {
  void _openCategoryFilter() async {
    if (widget.readOnly) return;

    logDebug(
      'Открытие фильтра категорий через кнопку',
      tag: 'CategoryFilterButton',
      data: {
        'categoryType': widget.categoryType.name,
        'selectedCount': widget.selectedCategories.length,
      },
    );

    try {
      final result = await _showCategoryFilter();

      if (result != null && widget.onApplyFilter != null) {
        widget.onApplyFilter!(result);
        logDebug(
          'Применен фильтр категорий',
          tag: 'CategoryFilterButton',
          data: {
            'categoryType': widget.categoryType.name,
            'selectedCount': result.length,
          },
        );
      }
    } catch (e, s) {
      logError(
        'Ошибка при открытии фильтра категорий',
        error: e,
        stackTrace: s,
        tag: 'CategoryFilterButton',
      );
    }
  }

  Future<List<store.Category>?> _showCategoryFilter() async {
    // Определяем, мобильная ли платформа
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return await showModalBottomSheet<List<store.Category>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
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

  String _getDefaultButtonText() {
    final selectedCount = widget.selectedCategories.length;

    if (selectedCount == 0) {
      switch (widget.categoryType) {
        case CategoryType.notes:
          return 'Фильтр заметок';
        case CategoryType.password:
          return 'Фильтр паролей';
        case CategoryType.totp:
          return 'Фильтр TOTP';
        case CategoryType.mixed:
          return 'Фильтр категорий';
      }
    } else {
      return 'Категории ($selectedCount)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = widget.selectedCategories.length;

    return Stack(
      children: [
        SmoothButton(
          label: widget.buttonText ?? _getDefaultButtonText(),
          onPressed: widget.readOnly ? null : _openCategoryFilter,
          icon: widget.icon ?? const Icon(Icons.filter_list),
          type: widget.buttonType,
          size: widget.buttonSize,
        ),

        // Индикатор выбранных категорий
        if (selectedCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.lightColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.surface, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              child: Text(
                '$selectedCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
