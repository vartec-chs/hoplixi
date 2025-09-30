import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
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

  // Timer для дебаунсинга обновлений
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _updateDisplayText();
  }

  @override
  void didUpdateWidget(TagFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    logDebug(
      'Обновление TagFilterWidget',
      tag: 'TagFilterWidget',
      data: {
        'oldSelectedCount': oldWidget.selectedTags.length,
        'newSelectedCount': widget.selectedTags.length,
        'oldTagNames': oldWidget.selectedTags.map((tag) => tag.name).toList(),
        'newTagNames': widget.selectedTags.map((tag) => tag.name).toList(),
        'identical': identical(oldWidget.selectedTags, widget.selectedTags),
        'listEquals': oldWidget.selectedTags == widget.selectedTags,
      },
    );

    // Если это тот же объект списка, но произошли изменения,
    // всегда обновляем текст для безопасности
    if (identical(oldWidget.selectedTags, widget.selectedTags)) {
      logDebug(
        'Обнаружен тот же объект списка, принудительное обновление текста',
        tag: 'TagFilterWidget',
      );
      _scheduleUpdate();
      return;
    }

    // Проверяем изменения в списке тегов более детально
    if (_tagsChanged(oldWidget.selectedTags, widget.selectedTags)) {
      logDebug(
        'Изменение в списке выбранных тегов обнаружено, планирование обновления текста',
        tag: 'TagFilterWidget',
      );
      _scheduleUpdate();
    } else {
      logDebug(
        'Изменений в списке выбранных тегов не обнаружено',
        tag: 'TagFilterWidget',
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
          'Выполнение отложенного обновления текста',
          tag: 'TagFilterWidget',
        );
        _updateDisplayText();
      }
    });
  }

  /// Проверяет, изменился ли список тегов
  bool _tagsChanged(List<store.Tag> oldTags, List<store.Tag> newTags) {
    logDebug(
      'Проверка изменений в списке тегов',
      tag: 'TagFilterWidget',
      data: {
        'oldTags': oldTags.map((tag) => tag.name).toList(),
        'newTags': newTags.map((tag) => tag.name).toList(),
      },
    );
    // Если оба списка пусты, изменений нет
    if (oldTags.isEmpty && newTags.isEmpty) {
      return false;
    }

    // Сначала проверяем длину
    if (oldTags.length != newTags.length) {
      logDebug(
        'Длина списков тегов различается',
        tag: 'TagFilterWidget',
        data: {'oldLength': oldTags.length, 'newLength': newTags.length},
      );
      return true;
    }

    // Если длина одинаковая, сравниваем ID тегов
    final oldTagIds = oldTags.map((tag) => tag.id).toSet();
    final newTagIds = newTags.map((tag) => tag.id).toSet();

    // Проверяем, есть ли разница в множествах ID
    final hasChanges =
        oldTagIds.difference(newTagIds).isNotEmpty ||
        newTagIds.difference(oldTagIds).isNotEmpty;

    if (hasChanges) {
      logDebug(
        'ID тегов изменились',
        tag: 'TagFilterWidget',
        data: {
          'oldTagIds': oldTagIds.toList(),
          'newTagIds': newTagIds.toList(),
          'added': newTagIds.difference(oldTagIds).toList(),
          'removed': oldTagIds.difference(newTagIds).toList(),
        },
      );
    }

    return hasChanges;
  }

  void _updateDisplayText() {
    final count = widget.selectedTags.length;
    logDebug(
      'Обновление текста фильтра тегов',
      tag: 'TagFilterWidget',
      data: {'tagType': widget.tagType.name, 'selectedCount': count},
    );

    String newText;
    if (count == 0) {
      newText = widget.searchPlaceholder ?? 'Выберите теги для фильтрации';
    } else {
      final tagNames = widget.selectedTags
          .take(2)
          .map((tag) => tag.name)
          .join(', ');
      if (count > 2) {
        newText = '$tagNames и ещё ${count - 2}';
      } else {
        newText = tagNames;
      }
    }

    logDebug(
      'Сравнение текста для обновления',
      tag: 'TagFilterWidget',
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
        tag: 'TagFilterWidget',
        data: {'oldText': _controller.text, 'newText': newText},
      );
      setState(() {
        _controller.text = newText;
      });
    } else {
      logDebug(
        'Текст не изменился, пропуск обновления',
        tag: 'TagFilterWidget',
        data: {'text': newText},
      );
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

    return SizedBox(
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
                  maxLines: 3,
                  minLines: 1,
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
    _updateTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
