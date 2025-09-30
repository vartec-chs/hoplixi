import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as db;
import 'package:hoplixi/hoplixi_store/services_providers.dart';

/// Компонент для выбора тегов
///
/// Отображает текстовое поле, при нажатии на которое открывается
/// модальное окно (на ПК) или bottom sheet (на мобильных устройствах)
/// для выбора тегов с пагинацией.
class TagsPicker extends ConsumerStatefulWidget {
  /// Тип тегов для фильтрации
  final TagType tagType;

  /// Максимальное количество выбранных тегов
  final int maxSelection;

  /// Уже выбранные теги (список ID)
  final List<String> selectedTagIds;

  /// Колбек при выборе тега
  final Function(List<String> selectedIds) onSelect;

  /// Колбек при очистке выбора
  final VoidCallback? onClear;

  /// Колбек при отмене выбора тега
  final Function(String tagId)? onRemove;

  /// Подсказка в текстовом поле
  final String? hintText;

  /// Лейбл текстового поля
  final String? labelText;

  /// Включено ли поле
  final bool enabled;

  const TagsPicker({
    super.key,
    required this.tagType,
    required this.onSelect,
    this.maxSelection = 5,
    this.selectedTagIds = const [],
    this.onClear,
    this.onRemove,
    this.hintText,
    this.labelText,
    this.enabled = true,
  });

  @override
  ConsumerState<TagsPicker> createState() => _TagsPickerState();
}

class _TagsPickerState extends ConsumerState<TagsPicker> {
  late TextEditingController _controller;
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedTagIds);
    _controller = TextEditingController();
    _updateControllerText();
  }

  @override
  void didUpdateWidget(TagsPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTagIds != widget.selectedTagIds) {
      _selectedIds = List.from(widget.selectedTagIds);
      _updateControllerText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Обновляет текст в контроллере на основе выбранных тегов
  Future<void> _updateControllerText() async {
    if (_selectedIds.isEmpty) {
      _controller.text = '';
      return;
    }

    try {
      final dao = ref.read(tagsDaoProvider);
      final tags = <db.Tag>[];

      for (final id in _selectedIds) {
        final tag = await dao.getTagById(id);
        if (tag != null) {
          tags.add(tag);
        }
      }

      if (tags.isNotEmpty) {
        if (tags.length == 1) {
          _controller.text = tags.first.name;
        } else {
          final tagNames = tags.map((t) => t.name).toList();
          if (tagNames.length <= 3) {
            _controller.text = tagNames.join(', ');
          } else {
            _controller.text =
                '${tagNames.take(2).join(', ')} и еще ${tagNames.length - 2}';
          }
        }
      } else {
        _controller.text = '';
      }
    } catch (e) {
      _controller.text = _selectedIds.isNotEmpty ? 'Ошибка загрузки' : '';
    }
  }

  /// Открывает селектор тегов
  Future<void> _openTagSelector() async {
    if (!widget.enabled) return;

    final result = await _showTagSelector();
    if (result != null) {
      setState(() {
        _selectedIds = result;
      });
      _updateControllerText();
      widget.onSelect(_selectedIds);
    }
  }

  /// Показывает селектор тегов (адаптивно)
  Future<List<String>?> _showTagSelector() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      // На десктопе показываем диалог
      return showDialog<List<String>>(
        context: context,
        builder: (context) => _TagSelectorDialog(
          tagType: widget.tagType,
          maxSelection: widget.maxSelection,
          selectedIds: _selectedIds,
        ),
      );
    } else {
      // На мобильных устройствах показываем bottom sheet
      return showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _TagSelectorBottomSheet(
          tagType: widget.tagType,
          maxSelection: widget.maxSelection,
          selectedIds: _selectedIds,
        ),
      );
    }
  }

  /// Очищает выбор
  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
    _updateControllerText();
    widget.onClear?.call();
    widget.onSelect(_selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryTextField(
      controller: _controller,
      label: widget.labelText ?? 'Теги',
      hintText: widget.hintText ?? 'Выберите теги',
      readOnly: true,
      enabled: widget.enabled,
      onTap: _openTagSelector,
      suffixIcon: _selectedIds.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: widget.enabled ? _clearSelection : null,
            )
          : const Icon(Icons.arrow_drop_down),
    );
  }
}

/// Диалог выбора тегов для десктопа
class _TagSelectorDialog extends StatelessWidget {
  final TagType tagType;
  final int maxSelection;
  final List<String> selectedIds;

  const _TagSelectorDialog({
    required this.tagType,
    required this.maxSelection,
    required this.selectedIds,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(8),
        child: _TagSelectorContent(
          tagType: tagType,
          maxSelection: maxSelection,
          selectedIds: selectedIds,
          isDialog: true,
        ),
      ),
    );
  }
}

/// Bottom Sheet выбора тегов для мобильных устройств
class _TagSelectorBottomSheet extends StatelessWidget {
  final TagType tagType;
  final int maxSelection;
  final List<String> selectedIds;

  const _TagSelectorBottomSheet({
    required this.tagType,
    required this.maxSelection,
    required this.selectedIds,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: _TagSelectorContent(
            tagType: tagType,
            maxSelection: maxSelection,
            selectedIds: selectedIds,
            isDialog: false,
            scrollController: scrollController,
          ),
        );
      },
    );
  }
}

/// Основное содержимое селектора тегов
class _TagSelectorContent extends ConsumerStatefulWidget {
  final TagType tagType;
  final int maxSelection;
  final List<String> selectedIds;
  final bool isDialog;
  final ScrollController? scrollController;

  const _TagSelectorContent({
    required this.tagType,
    required this.maxSelection,
    required this.selectedIds,
    required this.isDialog,
    this.scrollController,
  });

  @override
  ConsumerState<_TagSelectorContent> createState() =>
      _TagSelectorContentState();
}

class _TagSelectorContentState extends ConsumerState<_TagSelectorContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();

  List<String> _currentSelectedIds = [];
  List<db.Tag> _tags = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentOffset = 0;
  String _searchQuery = '';

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _currentSelectedIds = List.from(widget.selectedIds);
    _listScrollController.addListener(_onScroll);
    _loadTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  /// Обработчик скролла для пагинации
  void _onScroll() {
    if (_listScrollController.position.pixels >=
        _listScrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMore) {
        _loadMoreTags();
      }
    }
  }

  /// Загружает теги
  Future<void> _loadTags() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentOffset = 0;
      _tags.clear();
    });

    try {
      final dao = ref.read(tagsDaoProvider);
      List<db.Tag> result;

      if (_searchQuery.isEmpty) {
        result = await dao.getTagsByTypePaginated(
          widget.tagType,
          offset: _currentOffset,
          limit: _pageSize,
        );
      } else {
        result = await dao.searchTagsPaginated(
          _searchQuery,
          offset: _currentOffset,
          limit: _pageSize,
          type: widget.tagType,
        );
      }

      setState(() {
        _tags = result;
        _hasMore = result.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastHelper.error(title: 'Ошибка загрузки тегов', description: '$e');
      }
    }
  }

  /// Загружает дополнительные теги
  Future<void> _loadMoreTags() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dao = ref.read(tagsDaoProvider);
      final newOffset = _currentOffset + _pageSize;

      List<db.Tag> result;
      if (_searchQuery.isEmpty) {
        result = await dao.getTagsByTypePaginated(
          widget.tagType,
          offset: newOffset,
          limit: _pageSize,
        );
      } else {
        result = await dao.searchTagsPaginated(
          _searchQuery,
          offset: newOffset,
          limit: _pageSize,
          type: widget.tagType,
        );
      }

      setState(() {
        _currentOffset = newOffset;
        _tags.addAll(result);
        _hasMore = result.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Обрабатывает поиск
  void _onSearchChanged(String query) {
    _searchQuery = query;
    _loadTags();
  }

  /// Переключает выбор тега
  void _toggleTag(String tagId) {
    setState(() {
      if (_currentSelectedIds.contains(tagId)) {
        _currentSelectedIds.remove(tagId);
      } else {
        if (_currentSelectedIds.length < widget.maxSelection) {
          _currentSelectedIds.add(tagId);
        } else {
          // Если достигнут лимит, показываем уведомление
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Можно выбрать максимум ${widget.maxSelection} тегов',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    });
  }

  /// Подтверждает выбор
  void _confirmSelection() {
    Navigator.of(context).pop(_currentSelectedIds);
  }

  /// Отменяет выбор
  void _cancelSelection() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Заголовок и кнопка закрытия
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Выбор тегов',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: _cancelSelection,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),

        // Поле поиска
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryTextField(
            controller: _searchController,
            hintText: 'Поиск тегов...',
            prefixIcon: const Icon(Icons.search),
            onChanged: _onSearchChanged,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 16),

        // Счетчик выбранных тегов
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Выбрано: ${_currentSelectedIds.length} из ${widget.maxSelection}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),

        const SizedBox(height: 8),

        // Список тегов
        Expanded(
          child: _tags.isEmpty && !_isLoading
              ? const Center(child: Text('Теги не найдены'))
              : ListView.builder(
                  controller: widget.scrollController ?? _listScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tags.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _tags.length) {
                      // Индикатор загрузки
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final tag = _tags[index];
                    final isSelected = _currentSelectedIds.contains(tag.id);
                    final canSelect =
                        isSelected ||
                        _currentSelectedIds.length < widget.maxSelection;

                    return Card(
                      child: ListTile(
                        title: Text(tag.name),
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: tag.color != null
                                ? Color(
                                    int.parse(
                                      'FF${tag.color!.replaceAll('#', '')}',
                                      radix: 16,
                                    ),
                                  )
                                : Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.tag,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: canSelect
                              ? (_) => _toggleTag(tag.id)
                              : null,
                        ),
                        onTap: canSelect ? () => _toggleTag(tag.id) : null,
                      ),
                    );
                  },
                ),
        ),

        // Кнопки действий
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: SmoothButton(
                  onPressed: _cancelSelection,
                  type: SmoothButtonType.outlined,
                  label: 'Отмена',
                ),
              ),

              Expanded(
                child: SmoothButton(
                  onPressed: _confirmSelection,
                  type: SmoothButtonType.filled,
                  label: 'Подтвердить',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
