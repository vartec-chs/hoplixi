import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app/theme/colors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'tag_filter_modal.dart';

/// Компактный виджет для фильтрации тегов в виде кнопки-индикатора
class TagFilterButton extends ConsumerStatefulWidget {
  /// Тип тегов для фильтрации
  final TagType tagType;

  /// Выбранные теги
  final List<store.Tag> selectedTags;

  /// Callback при выборе тега
  final void Function(store.Tag tag) onTagSelect;

  /// Callback при удалении тега из выбора
  final void Function(store.Tag tag) onTagRemove;

  /// Callback при очистке всех выбранных тегов
  final void Function() onClearAll;

  /// Callback при применении фильтра (опционально)
  final void Function(List<store.Tag> tags)? onApplyFilter;

  /// Заголовок модального окна
  final String? modalTitle;

  /// Максимальное количество выбранных тегов (по умолчанию без ограничений)
  final int? maxSelectedTags;

  /// Включить ли режим только для чтения
  final bool readOnly;

  /// Показывать ли текст кнопки
  final bool showButtonText;

  /// Кастомный текст кнопки
  final String? buttonText;

  /// Размер кнопки
  final Size? buttonSize;

  const TagFilterButton({
    super.key,
    required this.tagType,
    required this.selectedTags,
    required this.onTagSelect,
    required this.onTagRemove,
    required this.onClearAll,
    this.onApplyFilter,
    this.modalTitle,
    this.maxSelectedTags,
    this.readOnly = false,
    this.showButtonText = true,
    this.buttonText,
    this.buttonSize,
  });

  @override
  ConsumerState<TagFilterButton> createState() => _TagFilterButtonState();
}

class _TagFilterButtonState extends ConsumerState<TagFilterButton> {
  void _openTagSelector() async {
    if (widget.readOnly) return;

    logDebug(
      'Открытие селектора тегов (кнопка)',
      tag: 'TagFilterButton',
      data: {
        'tagType': widget.tagType.name,
        'selectedCount': widget.selectedTags.length,
      },
    );

    try {
      final result = await _showTagSelector();

      if (result != null && widget.onApplyFilter != null) {
        widget.onApplyFilter!(result);
        logDebug(
          'Применен фильтр тегов (кнопка)',
          tag: 'TagFilterButton',
          data: {
            'tagType': widget.tagType.name,
            'selectedCount': result.length,
          },
        );
      }
    } catch (e, s) {
      logError(
        'Ошибка при открытии селектора тегов (кнопка)',
        error: e,
        stackTrace: s,
        tag: 'TagFilterButton',
      );
    }
  }

  Future<List<store.Tag>?> _showTagSelector() async {
    // Определяем, мобильная ли платформа
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return await showModalBottomSheet<List<store.Tag>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => TagFilterModal(
          tagType: widget.tagType,
          selectedTags: List.from(widget.selectedTags),
          onTagSelect: widget.onTagSelect,
          onTagRemove: widget.onTagRemove,
          onClearAll: widget.onClearAll,
          title: widget.modalTitle ?? _getDefaultTitle(),
          maxSelectedTags: widget.maxSelectedTags,
          isMobile: true,
        ),
      );
    } else {
      return await showDialog<List<store.Tag>>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: 600,
            height: 700,
            child: TagFilterModal(
              tagType: widget.tagType,
              selectedTags: List.from(widget.selectedTags),
              onTagSelect: widget.onTagSelect,
              onTagRemove: widget.onTagRemove,
              onClearAll: widget.onClearAll,
              title: widget.modalTitle ?? _getDefaultTitle(),
              maxSelectedTags: widget.maxSelectedTags,
              isMobile: false,
            ),
          ),
        ),
      );
    }
  }

  String _getDefaultTitle() {
    switch (widget.tagType) {
      case TagType.notes:
        return 'Фильтр тегов заметок';
      case TagType.password:
        return 'Фильтр тегов паролей';
      case TagType.totp:
        return 'Фильтр тегов TOTP';
      case TagType.mixed:
        return 'Фильтр тегов';
    }
  }

  String _getButtonText() {
    if (widget.buttonText != null) {
      return widget.buttonText!;
    }

    final count = widget.selectedTags.length;
    if (count == 0) {
      return 'Теги';
    } else {
      return 'Теги ($count)';
    }
  }

  Color _getButtonColor(ThemeData theme) {
    if (widget.selectedTags.isEmpty) {
      return theme.colorScheme.outline;
    }

    switch (widget.tagType) {
      case TagType.notes:
        return AppColors.lightColors.secondary;
      case TagType.password:
        return AppColors.lightColors.primary;
      case TagType.totp:
        return AppColors.lightColors.tertiary;
      case TagType.mixed:
        return theme.colorScheme.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = _getButtonColor(theme);
    final hasSelection = widget.selectedTags.isNotEmpty;

    return SizedBox(
      width: widget.buttonSize?.width,
      height: widget.buttonSize?.height ?? 40,
      child: Material(
        color: hasSelection ? buttonColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: widget.readOnly ? null : _openTagSelector,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasSelection ? buttonColor : theme.colorScheme.outline,
                width: hasSelection ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Иконка фильтра
                Icon(
                  hasSelection ? Icons.filter_alt : Icons.filter_alt_outlined,
                  size: 18,
                  color: hasSelection ? buttonColor : theme.iconTheme.color,
                ),

                // Текст кнопки
                if (widget.showButtonText) ...[
                  const SizedBox(width: 6),
                  Text(
                    _getButtonText(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasSelection
                          ? buttonColor
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight: hasSelection
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],

                // Индикатор количества тегов
                if (hasSelection) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.selectedTags.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],

                // Стрелка раскрытия
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: widget.readOnly
                      ? theme.disabledColor
                      : hasSelection
                      ? buttonColor
                      : theme.iconTheme.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
