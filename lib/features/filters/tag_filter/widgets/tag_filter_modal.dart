import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/common/debouncer.dart';
import 'package:hoplixi/common/shimmer_effect.dart';
import 'package:hoplixi/core/theme/colors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/providers.dart';

/// Модальное окно для фильтрации тегов
class TagFilterModal extends ConsumerStatefulWidget {
  /// Тип тегов для отображения
  final TagType tagType;

  /// Список выбранных тегов
  final List<store.Tag> selectedTags;

  /// Callback при выборе тега
  final void Function(store.Tag tag) onTagSelect;

  /// Callback при удалении тега из выбора
  final void Function(store.Tag tag) onTagRemove;

  /// Callback при очистке всех выбранных тегов
  final void Function() onClearAll;

  /// Заголовок модального окна
  final String title;

  /// Максимальное количество выбранных тегов
  final int? maxSelectedTags;

  /// Является ли мобильной версией (bottom sheet)
  final bool isMobile;

  const TagFilterModal({
    super.key,
    required this.tagType,
    required this.selectedTags,
    required this.onTagSelect,
    required this.onTagRemove,
    required this.onClearAll,
    required this.title,
    this.maxSelectedTags,
    this.isMobile = false,
  });

  @override
  ConsumerState<TagFilterModal> createState() => _TagFilterModalState();
}

class _TagFilterModalState extends ConsumerState<TagFilterModal> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Debouncer для поиска
  late final Debouncer _searchDebouncer;

  List<store.Tag> _availableTags = [];
  List<store.Tag> _filteredTags = [];
  List<store.Tag> _localSelectedTags = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  // Пагинация
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  // Кэш запросов для избежания дублирования
  final Set<String> _loadingQueries = {};

  @override
  void initState() {
    super.initState();
    _localSelectedTags = List.from(widget.selectedTags);
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
    _loadTags();
    _setupScrollController();
    _searchController.addListener(_onSearchChanged);
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreTags();
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (_searchQuery == query) return;

    _searchDebouncer.run(() {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _currentPage = 1;
          _hasMoreData = true;
        });
        _loadTags();
      }
    });
  }

  Future<void> _loadTags() async {
    if (_isLoading) return;

    final queryKey = '${_searchQuery}_${_currentPage}';
    if (_loadingQueries.contains(queryKey)) return;

    setState(() {
      _isLoading = true;
    });

    _loadingQueries.add(queryKey);

    try {
      final tagsService = ref.read(tagsServiceProvider);

      final result = await tagsService.getTagsPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        type: widget.tagType,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
        orderBy: 'name',
        ascending: true,
      );

      if (!mounted) return;

      setState(() {
        if (_currentPage == 1) {
          _availableTags = result.tags;
        } else {
          _availableTags.addAll(result.tags);
        }

        _filteredTags = _availableTags;
        _hasMoreData = result.tags.length == _pageSize;
        _isLoading = false;
      });

      logDebug(
        'Загружены теги для фильтрации',
        tag: 'TagFilterModal',
        data: {
          'tagType': widget.tagType.name,
          'page': _currentPage,
          'loadedCount': result.tags.length,
          'totalCount': result.totalCount,
        },
      );
    } catch (e, s) {
      logError(
        'Ошибка загрузки тегов для фильтрации',
        error: e,
        stackTrace: s,
        tag: 'TagFilterModal',
        data: {
          'tagType': widget.tagType.name,
          'page': _currentPage,
          'searchQuery': _searchQuery,
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } finally {
      _loadingQueries.remove(queryKey);
    }
  }

  Future<void> _loadMoreTags() async {
    if (_isLoadingMore || !_hasMoreData || _isLoading) return;

    final queryKey = '${_searchQuery}_${_currentPage + 1}';
    if (_loadingQueries.contains(queryKey)) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    _loadingQueries.add(queryKey);

    try {
      final tagsService = ref.read(tagsServiceProvider);

      final result = await tagsService.getTagsPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        type: widget.tagType,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
        orderBy: 'name',
        ascending: true,
      );

      if (!mounted) return;

      setState(() {
        _availableTags.addAll(result.tags);
        _filteredTags = _availableTags;
        _hasMoreData = result.tags.length == _pageSize;
        _isLoadingMore = false;
      });

      logDebug(
        'Загружены дополнительные теги',
        tag: 'TagFilterModal',
        data: {
          'tagType': widget.tagType.name,
          'page': _currentPage,
          'loadedCount': result.tags.length,
        },
      );
    } catch (e, s) {
      logError(
        'Ошибка загрузки дополнительных тегов',
        error: e,
        stackTrace: s,
        tag: 'TagFilterModal',
      );

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPage--;
        });
      }
    } finally {
      _loadingQueries.remove(queryKey);
    }
  }

  bool _isTagSelected(store.Tag tag) {
    return _localSelectedTags.any((selected) => selected.id == tag.id);
  }

  void _toggleTag(store.Tag tag) {
    setState(() {
      final isSelected = _isTagSelected(tag);

      if (isSelected) {
        _localSelectedTags.removeWhere((selected) => selected.id == tag.id);
      } else {
        // Проверяем ограничение на максимальное количество
        if (widget.maxSelectedTags != null &&
            _localSelectedTags.length >= widget.maxSelectedTags!) {
          _showMaxSelectionError();
          return;
        }

        _localSelectedTags.add(tag);
      }
    });

    logDebug(
      'Переключен выбор тега',
      tag: 'TagFilterModal',
      data: {
        'tagId': tag.id,
        'tagName': tag.name,
        'isSelected': !_isTagSelected(tag),
        'totalSelected': _localSelectedTags.length,
      },
    );
  }

  void _showMaxSelectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Можно выбрать максимум ${widget.maxSelectedTags} тегов'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearAllSelected() {
    setState(() {
      _localSelectedTags.clear();
    });

    logDebug(
      'Очищены все выбранные теги',
      tag: 'TagFilterModal',
      data: {'tagType': widget.tagType.name},
    );
  }

  void _applyFilter() {
    // Применяем изменения к родительскому виджету
    // Используем ID для сравнения тегов, а не прямое сравнение объектов
    final selectedTagIds = widget.selectedTags.map((tag) => tag.id).toSet();
    final localSelectedTagIds = _localSelectedTags.map((tag) => tag.id).toSet();

    final removedTags = widget.selectedTags
        .where((tag) => !localSelectedTagIds.contains(tag.id))
        .toList();

    final addedTags = _localSelectedTags
        .where((tag) => !selectedTagIds.contains(tag.id))
        .toList();

    logDebug(
      'Подготовка к применению фильтра тегов',
      tag: 'TagFilterModal',
      data: {
        'tagType': widget.tagType.name,
        'selectedCount': _localSelectedTags.length,
        'addedCount': addedTags.length,
        'removedCount': removedTags.length,
        'removedTagIds': removedTags.map((tag) => tag.id).toList(),
        'addedTagIds': addedTags.map((tag) => tag.id).toList(),
      },
    );

    // Удаляем старые теги
    for (final tag in removedTags) {
      widget.onTagRemove(tag);
    }

    // Добавляем новые теги
    for (final tag in addedTags) {
      widget.onTagSelect(tag);
    }

    logDebug(
      'Применен фильтр тегов',
      tag: 'TagFilterModal',
      data: {
        'tagType': widget.tagType.name,
        'selectedCount': _localSelectedTags.length,
        'addedCount': addedTags.length,
        'removedCount': removedTags.length,
      },
    );

    Navigator.of(context).pop(_localSelectedTags);
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: widget.isMobile
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: widget.isMobile ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Заголовок и кнопка закрытия
          _buildHeader(theme),

          // Поле поиска
          _buildSearchField(),

          // Выбранные теги
          if (_localSelectedTags.isNotEmpty) _buildSelectedTagsSection(theme),

          // Список доступных тегов
          Expanded(child: _buildTagsList(theme)),

          // Кнопки действий
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (widget.maxSelectedTags != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_localSelectedTags.length}/${widget.maxSelectedTags}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(width: 8),

          IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer.withOpacity(
                0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: PrimaryTextField(
        controller: _searchController,
        label: 'Поиск тегов',
        hintText: 'Введите название тега...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
    );
  }

  Widget _buildSelectedTagsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Выбранные теги (${_localSelectedTags.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearAllSelected,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Очистить все'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _localSelectedTags.length,
              itemBuilder: (context, index) {
                final tag = _localSelectedTags[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: _buildSelectedTagChip(tag, theme),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          Divider(color: theme.dividerColor),
        ],
      ),
    );
  }

  Widget _buildSelectedTagChip(store.Tag tag, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getTagColor(tag, theme),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getTagTextColor(tag, theme),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _toggleTag(tag),
            child: Icon(
              Icons.close,
              size: 16,
              color: _getTagTextColor(tag, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsList(ThemeData theme) {
    if (_isLoading && _currentPage == 1) {
      return const TagListShimmer(itemCount: 8);
    }

    if (_filteredTags.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Теги не найдены'
                  : 'Нет тегов по запросу "$_searchQuery"',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredTags.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredTags.length) {
          // Индикатор загрузки для пагинации
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: _isLoadingMore
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const SizedBox.shrink(),
          );
        }

        final tag = _filteredTags[index];
        final isSelected = _isTagSelected(tag);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildTagListItem(tag, isSelected, theme),
        );
      },
    );
  }

  Widget _buildTagListItem(store.Tag tag, bool isSelected, ThemeData theme) {
    return Material(
      color: isSelected
          ? _getTagColor(tag, theme).withOpacity(0.3)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _toggleTag(tag),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Цветовой индикатор тега
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getTagColor(tag, theme),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Название тега
              Expanded(
                child: Text(
                  tag.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),

              // Чекбокс
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleTag(tag),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          // Информация о выбранных тегах
          Expanded(
            child: Text(
              'Выбрано: ${_localSelectedTags.length} тегов',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Кнопка отмены
          TextButton(onPressed: _cancel, child: const Text('Отмена')),

          const SizedBox(width: 8),

          // Кнопка применения
          SmoothButton(label: 'Применить', onPressed: _applyFilter),
        ],
      ),
    );
  }

  Color _getTagColor(store.Tag tag, ThemeData theme) {
    if (tag.color != null && tag.color!.isNotEmpty) {
      try {
        return Color(int.parse(tag.color!.replaceAll('#', '0xFF')));
      } catch (e) {
        // Fallback цвет если не удалось распарсить
      }
    }

    // Дефолтный цвет на основе типа тега
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

  Color _getTagTextColor(store.Tag tag, ThemeData theme) {
    final bgColor = _getTagColor(tag, theme);
    // Определяем контрастный цвет текста
    final luminance = bgColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }
}
