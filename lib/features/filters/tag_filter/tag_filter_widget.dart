import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/core/theme/colors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'widgets/tag_filter_modal.dart';

/// Виджет для фильтрации тегов с поддержкой модального окна/bottom sheet
class TagFilterWidget extends ConsumerStatefulWidget {
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

  /// Placeholder для поля поиска
  final String? searchPlaceholder;

  /// Заголовок модального окна
  final String? modalTitle;

  /// Максимальное количество выбранных тегов (по умолчанию без ограничений)
  final int? maxSelectedTags;

  /// Показывать ли счетчик выбранных тегов
  final bool showSelectedCount;

  /// Включить ли режим только для чтения
  final bool readOnly;

  /// Кастомная высота виджета
  final double? height;

  /// Кастомная ширина виджета
  final double? width;

  const TagFilterWidget({
    super.key,
    required this.tagType,
    required this.selectedTags,
    required this.onTagSelect,
    required this.onTagRemove,
    required this.onClearAll,
    this.onApplyFilter,
    this.searchPlaceholder,
    this.modalTitle,
    this.maxSelectedTags,
    this.showSelectedCount = true,
    this.readOnly = false,
    this.height,
    this.width,
  });

  @override
  ConsumerState<TagFilterWidget> createState() => _TagFilterWidgetState();
}

class _TagFilterWidgetState extends ConsumerState<TagFilterWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDisplayText();
  }

  @override
  void didUpdateWidget(TagFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTags.length != widget.selectedTags.length) {
      _updateDisplayText();
    }
  }

  void _updateDisplayText() {
    final count = widget.selectedTags.length;
    if (count == 0) {
      _controller.text =
          widget.searchPlaceholder ?? 'Выберите теги для фильтрации';
    } else {
      final tagNames = widget.selectedTags
          .take(2)
          .map((tag) => tag.name)
          .join(', ');
      if (count > 2) {
        _controller.text = '$tagNames и ещё ${count - 2}';
      } else {
        _controller.text = tagNames;
      }
    }
  }

  void _openTagSelector() async {
    if (widget.readOnly) return;

    logDebug(
      'Открытие селектора тегов',
      tag: 'TagFilterWidget',
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
          'Применен фильтр тегов',
          tag: 'TagFilterWidget',
          data: {
            'tagType': widget.tagType.name,
            'selectedCount': result.length,
          },
        );
      }
    } catch (e, s) {
      logError(
        'Ошибка при открытии селектора тегов',
        error: e,
        stackTrace: s,
        tag: 'TagFilterWidget',
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
          child: Container(
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

  void _clearFilter() {
    if (widget.readOnly) return;

    logDebug(
      'Очистка фильтра тегов',
      tag: 'TagFilterWidget',
      data: {
        'tagType': widget.tagType.name,
        'clearedCount': widget.selectedTags.length,
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
          // Основное поле с выбранными тегами
          Expanded(
            child: GestureDetector(
              onTap: _openTagSelector,
              child: AbsorbPointer(
                child: PrimaryTextField(
                  controller: _controller,
                  label: 'Фильтр по тегам',
                  readOnly: true,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Счетчик выбранных тегов
                      if (widget.showSelectedCount &&
                          widget.selectedTags.isNotEmpty)
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
                            '${widget.selectedTags.length}',
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
          if (widget.selectedTags.isNotEmpty && !widget.readOnly)
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
