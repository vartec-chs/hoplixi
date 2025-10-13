import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/widgets/text_field.dart';
import 'package:hoplixi/shared/widgets/button.dart';
import 'package:hoplixi/shared/widgets/debouncer.dart';
import 'package:hoplixi/shared/widgets/shimmer_effect.dart';
import 'package:hoplixi/app/theme/colors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/parse_hex_color.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/dao/categories_dao.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';

/// Провайдер для сервиса категорий
/// Модальное окно для фильтрации категорий
class CategoryFilterModal extends ConsumerStatefulWidget {
  /// Тип категорий для отображения
  final CategoryType categoryType;

  /// Список выбранных категорий
  final List<store.Category> selectedCategories;

  /// Callback при выборе категории
  final void Function(store.Category category) onCategorySelect;

  /// Callback при удалении категории из выбора
  final void Function(store.Category category) onCategoryRemove;

  /// Callback при очистке всех выбранных категорий
  final void Function() onClearAll;

  /// Заголовок модального окна
  final String title;

  /// Максимальное количество выбранных категорий
  final int? maxSelectedCategories;

  /// Является ли мобильной версией (bottom sheet)
  final bool isMobile;

  /// Размер страницы для пагинации
  final int pageSize;

  /// Сортировка категорий
  final CategorySortBy sortBy;

  /// По возрастанию ли сортировать
  final bool ascending;

  const CategoryFilterModal({
    super.key,
    required this.categoryType,
    required this.selectedCategories,
    required this.onCategorySelect,
    required this.onCategoryRemove,
    required this.onClearAll,
    required this.title,
    this.maxSelectedCategories,
    this.isMobile = false,
    this.pageSize = 20,
    this.sortBy = CategorySortBy.name,
    this.ascending = true,
  });

  @override
  ConsumerState<CategoryFilterModal> createState() =>
      _CategoryFilterModalState();
}

class _CategoryFilterModalState extends ConsumerState<CategoryFilterModal> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Debouncer для поиска
  late final Debouncer _searchDebouncer;

  List<store.Category> _availableCategories = [];
  List<store.Category> _filteredCategories = [];
  List<store.Category> _localSelectedCategories = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  // Пагинация
  int _currentPage = 1;
  bool _hasMoreData = true;

  // Кэш запросов для избежания дублирования
  final Set<String> _loadingQueries = {};

  @override
  void initState() {
    super.initState();
    _localSelectedCategories = List.from(widget.selectedCategories);
    _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
    _loadCategories();
    _setupScrollController();
    _searchController.addListener(_onSearchChanged);
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreCategories();
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
        _loadCategories();
      }
    });
  }

  Future<void> _loadCategories() async {
    if (_isLoading) return;

    final queryKey = '${_searchQuery}_$_currentPage';
    if (_loadingQueries.contains(queryKey)) return;

    setState(() {
      _isLoading = true;
    });

    _loadingQueries.add(queryKey);

    try {
      final categoriesService = ref.read(categoriesServiceProvider);

      final result = await categoriesService.getCategoriesPaginated(
        page: _currentPage,
        pageSize: widget.pageSize,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
        type: widget.categoryType,
        sortBy: widget.sortBy,
        ascending: widget.ascending,
      );

      if (!mounted) return;

      setState(() {
        if (_currentPage == 1) {
          _availableCategories = result.categories;
        } else {
          _availableCategories.addAll(result.categories);
        }

        _filteredCategories = _availableCategories;
        _hasMoreData = result.categories.length == widget.pageSize;
        _isLoading = false;
      });

      logDebug(
        'Загружены категории для фильтрации',
        tag: 'CategoryFilterModal',
        data: {
          'categoryType': widget.categoryType.name,
          'page': _currentPage,
          'loadedCount': result.categories.length,
          'totalCount': result.pagination.totalItems,
        },
      );
    } catch (e, s) {
      logError(
        'Ошибка загрузки категорий для фильтрации',
        error: e,
        stackTrace: s,
        tag: 'CategoryFilterModal',
        data: {
          'categoryType': widget.categoryType.name,
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

  Future<void> _loadMoreCategories() async {
    if (_isLoadingMore || !_hasMoreData || _isLoading) return;

    final queryKey = '${_searchQuery}_${_currentPage + 1}';
    if (_loadingQueries.contains(queryKey)) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    _loadingQueries.add(queryKey);

    try {
      final categoriesService = ref.read(categoriesServiceProvider);

      final result = await categoriesService.getCategoriesPaginated(
        page: _currentPage,
        pageSize: widget.pageSize,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
        type: widget.categoryType,
        sortBy: widget.sortBy,
        ascending: widget.ascending,
      );

      if (!mounted) return;

      setState(() {
        _availableCategories.addAll(result.categories);
        _filteredCategories = _availableCategories;
        _hasMoreData = result.categories.length == widget.pageSize;
        _isLoadingMore = false;
      });

      logDebug(
        'Загружены дополнительные категории',
        tag: 'CategoryFilterModal',
        data: {
          'categoryType': widget.categoryType.name,
          'page': _currentPage,
          'loadedCount': result.categories.length,
        },
      );
    } catch (e, s) {
      logError(
        'Ошибка загрузки дополнительных категорий',
        error: e,
        stackTrace: s,
        tag: 'CategoryFilterModal',
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

  bool _isCategorySelected(store.Category category) {
    return _localSelectedCategories.any(
      (selected) => selected.id == category.id,
    );
  }

  void _toggleCategory(store.Category category) {
    setState(() {
      final isSelected = _isCategorySelected(category);

      if (isSelected) {
        _localSelectedCategories.removeWhere(
          (selected) => selected.id == category.id,
        );
      } else {
        // Проверяем ограничение на максимальное количество
        if (widget.maxSelectedCategories != null &&
            _localSelectedCategories.length >= widget.maxSelectedCategories!) {
          _showMaxSelectionError();
          return;
        }

        _localSelectedCategories.add(category);
      }
    });

    logDebug(
      'Переключен выбор категории',
      tag: 'CategoryFilterModal',
      data: {
        'categoryId': category.id,
        'categoryName': category.name,
        'isSelected': !_isCategorySelected(category),
        'totalSelected': _localSelectedCategories.length,
      },
    );
  }

  void _showMaxSelectionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Можно выбрать максимум ${widget.maxSelectedCategories} категорий',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearAllSelected() {
    setState(() {
      _localSelectedCategories.clear();
    });

    logDebug(
      'Очищены все выбранные категории',
      tag: 'CategoryFilterModal',
      data: {'categoryType': widget.categoryType.name},
    );
  }

  void _applyFilter() {
    // Применяем изменения к родительскому виджету
    final removedCategories = widget.selectedCategories
        .where((category) => !_localSelectedCategories.contains(category))
        .toList();

    final addedCategories = _localSelectedCategories
        .where((category) => !widget.selectedCategories.contains(category))
        .toList();

    // Удаляем старые категории
    for (final category in removedCategories) {
      widget.onCategoryRemove(category);
    }

    // Добавляем новые категории
    for (final category in addedCategories) {
      widget.onCategorySelect(category);
    }

    logDebug(
      'Применен фильтр категорий',
      tag: 'CategoryFilterModal',
      data: {
        'categoryType': widget.categoryType.name,
        'selectedCount': _localSelectedCategories.length,
        'addedCount': addedCategories.length,
        'removedCount': removedCategories.length,
      },
    );

    Navigator.of(context).pop(_localSelectedCategories);
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

          // Выбранные категории
          if (_localSelectedCategories.isNotEmpty)
            _buildSelectedCategoriesSection(theme),

          // Список доступных категорий
          Expanded(child: _buildCategoriesList(theme)),

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

          if (widget.maxSelectedCategories != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_localSelectedCategories.length}/${widget.maxSelectedCategories}',
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
            style: IconButton.styleFrom(),
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
        label: 'Поиск категорий',
        hintText: 'Введите название категории...',
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

  Widget _buildSelectedCategoriesSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Выбранные категории (${_localSelectedCategories.length})',
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
              itemCount: _localSelectedCategories.length,
              itemBuilder: (context, index) {
                final category = _localSelectedCategories[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: _buildSelectedCategoryChip(category, theme),
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

  Widget _buildSelectedCategoryChip(store.Category category, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: parseHexColor(
          category.color,
          _getCategoryColor(category, theme),
        ).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            category.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getCategoryTextColor(category, theme),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _toggleCategory(category),
            child: Icon(
              Icons.close,
              size: 16,
              color: _getCategoryTextColor(category, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(ThemeData theme) {
    if (_isLoading && _currentPage == 1) {
      return const CategoryListShimmer(itemCount: 8);
    }

    if (_filteredCategories.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Категории не найдены'
                  : 'Нет категорий по запросу "$_searchQuery"',
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
      itemCount: _filteredCategories.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _filteredCategories.length) {
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

        final category = _filteredCategories[index];
        final isSelected = _isCategorySelected(category);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _buildCategoryListItem(category, isSelected, theme),
        );
      },
    );
  }

  Widget _buildCategoryListItem(
    store.Category category,
    bool isSelected,
    ThemeData theme,
  ) {
    return Material(
      color: isSelected
          ? theme.colorScheme.secondary.withOpacity(0.3)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _toggleCategory(category),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Цветовой индикатор категории
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: parseHexColor(
                    category.color,
                    _getCategoryColor(category, theme),
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Название и описание категории
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (category.description != null &&
                        category.description!.isNotEmpty)
                      Text(
                        category.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              // Тип категории
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCategoryTypeName(category.type),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Чекбокс
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleCategory(category),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: Row(
          children: [
            // Информация о выбранных категориях
            Expanded(
              child: Text(
                'Выбрано: ${_localSelectedCategories.length} категорий',
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
      ),
    );
  }

  String _getCategoryTypeName(CategoryType type) {
    switch (type) {
      case CategoryType.notes:
        return 'Заметки';
      case CategoryType.password:
        return 'Пароли';
      case CategoryType.totp:
        return 'TOTP';
      case CategoryType.mixed:
        return 'Смешанная';
    }
  }

  Color _getCategoryColor(store.Category category, ThemeData theme) {
    if (category.color.isNotEmpty) {
      try {
        return Color(int.parse(category.color.replaceAll('#', '0xFF')));
      } catch (e) {
        // Fallback цвет если не удалось распарсить
      }
    }

    // Дефолтный цвет на основе типа категории
    switch (category.type) {
      case CategoryType.notes:
        return AppColors.lightColors.secondary;
      case CategoryType.password:
        return AppColors.lightColors.primary;
      case CategoryType.totp:
        return AppColors.lightColors.tertiary;
      case CategoryType.mixed:
        return theme.colorScheme.primaryContainer;
    }
  }

  Color _getCategoryTextColor(store.Category category, ThemeData theme) {
    final bgColor = _getCategoryColor(category, theme);
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
