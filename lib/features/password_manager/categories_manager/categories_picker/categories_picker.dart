import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/common/text_field.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as db;
import 'package:hoplixi/hoplixi_store/services_providers.dart';

/// Компонент для выбора категорий
///
/// Отображает текстовое поле, при нажатии на которое открывается
/// модальное окно (на ПК) или bottom sheet (на мобильных устройствах)
/// для выбора категорий с пагинацией.
class CategoriesPicker extends ConsumerStatefulWidget {
  /// Тип категорий для фильтрации
  final CategoryType categoryType;

  /// Максимальное количество выбранных категорий
  final int maxSelection;

  /// Уже выбранные категории (список ID)
  final List<String> selectedCategoryIds;

  /// Колбек при выборе категории
  final Function(List<String> selectedIds) onSelect;

  /// Колбек при очистке выбора
  final VoidCallback? onClear;

  /// Колбек при отмене выбора категории
  final Function(String categoryId)? onRemove;

  /// Подсказка в текстовом поле
  final String? hintText;

  /// Лейбл текстового поля
  final String? labelText;

  /// Включено ли поле
  final bool enabled;

  const CategoriesPicker({
    super.key,
    required this.categoryType,
    required this.onSelect,
    this.maxSelection = 1,
    this.selectedCategoryIds = const [],
    this.onClear,
    this.onRemove,
    this.hintText,
    this.labelText,
    this.enabled = true,
  });

  @override
  ConsumerState<CategoriesPicker> createState() => _CategoriesPickerState();
}

class _CategoriesPickerState extends ConsumerState<CategoriesPicker> {
  late TextEditingController _controller;
  late List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedCategoryIds);
    _controller = TextEditingController();
    _updateControllerText();
  }

  @override
  void didUpdateWidget(CategoriesPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategoryIds != widget.selectedCategoryIds) {
      _selectedIds = List.from(widget.selectedCategoryIds);
      _updateControllerText();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Обновляет текст в контроллере на основе выбранных категорий
  Future<void> _updateControllerText() async {
    if (_selectedIds.isEmpty) {
      _controller.text = '';
      return;
    }

    try {
      final dao = ref.read(categoriesDaoProvider);
      final categories = <db.Category>[];

      for (final id in _selectedIds) {
        final category = await dao.getCategoryById(id);
        if (category != null) {
          categories.add(category);
        }
      }

      if (categories.isNotEmpty) {
        if (categories.length == 1) {
          _controller.text = categories.first.name;
        } else {
          _controller.text = '${categories.length} категорий выбрано';
        }
      } else {
        _controller.text = '';
      }
    } catch (e) {
      _controller.text = _selectedIds.isNotEmpty ? 'Ошибка загрузки' : '';
    }
  }

  /// Открывает селектор категорий
  Future<void> _openCategorySelector() async {
    if (!widget.enabled) return;

    final result = await _showCategorySelector();
    if (result != null) {
      setState(() {
        _selectedIds = result;
      });
      _updateControllerText();
      widget.onSelect(_selectedIds);
    }
  }

  /// Показывает селектор категорий (адаптивно)
  Future<List<String>?> _showCategorySelector() async {
    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      // На десктопе показываем диалог
      return showDialog<List<String>>(
        context: context,
        builder: (context) => _CategorySelectorDialog(
          categoryType: widget.categoryType,
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
        builder: (context) => _CategorySelectorBottomSheet(
          categoryType: widget.categoryType,
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
      label: widget.labelText ?? 'Категория',
      hintText: widget.hintText ?? 'Выберите категорию',
      readOnly: true,
      enabled: widget.enabled,
      onTap: _openCategorySelector,
      suffixIcon: _selectedIds.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: widget.enabled ? _clearSelection : null,
            )
          : const Icon(Icons.arrow_drop_down),
    );
  }
}

/// Диалог выбора категорий для десктопа
class _CategorySelectorDialog extends StatelessWidget {
  final CategoryType categoryType;
  final int maxSelection;
  final List<String> selectedIds;

  const _CategorySelectorDialog({
    required this.categoryType,
    required this.maxSelection,
    required this.selectedIds,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: _CategorySelectorContent(
          categoryType: categoryType,
          maxSelection: maxSelection,
          selectedIds: selectedIds,
          isDialog: true,
        ),
      ),
    );
  }
}

/// Bottom Sheet выбора категорий для мобильных устройств
class _CategorySelectorBottomSheet extends StatelessWidget {
  final CategoryType categoryType;
  final int maxSelection;
  final List<String> selectedIds;

  const _CategorySelectorBottomSheet({
    required this.categoryType,
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
          child: _CategorySelectorContent(
            categoryType: categoryType,
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

/// Основное содержимое селектора категорий
class _CategorySelectorContent extends ConsumerStatefulWidget {
  final CategoryType categoryType;
  final int maxSelection;
  final List<String> selectedIds;
  final bool isDialog;
  final ScrollController? scrollController;

  const _CategorySelectorContent({
    required this.categoryType,
    required this.maxSelection,
    required this.selectedIds,
    required this.isDialog,
    this.scrollController,
  });

  @override
  ConsumerState<_CategorySelectorContent> createState() =>
      _CategorySelectorContentState();
}

class _CategorySelectorContentState
    extends ConsumerState<_CategorySelectorContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();

  List<String> _currentSelectedIds = [];
  List<db.Category> _categories = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String _searchQuery = '';

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _currentSelectedIds = List.from(widget.selectedIds);
    _listScrollController.addListener(_onScroll);
    _loadCategories();
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
        _loadMoreCategories();
      }
    }
  }

  /// Загружает категории
  Future<void> _loadCategories() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _categories.clear();
    });

    try {
      final dao = ref.read(categoriesDaoProvider);
      final result = await dao.getCategoriesPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        type: widget.categoryType,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _categories = result.categories;
        _hasMore = result.pagination.hasNextPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка загрузки категорий')),
        );
      }
    }
  }

  /// Загружает дополнительные категории
  Future<void> _loadMoreCategories() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dao = ref.read(categoriesDaoProvider);
      final result = await dao.getCategoriesPaginated(
        page: _currentPage + 1,
        pageSize: _pageSize,
        type: widget.categoryType,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        _currentPage++;
        _categories.addAll(result.categories);
        _hasMore = result.pagination.hasNextPage;
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
    _loadCategories();
  }

  /// Переключает выбор категории
  void _toggleCategory(String categoryId) {
    setState(() {
      if (_currentSelectedIds.contains(categoryId)) {
        _currentSelectedIds.remove(categoryId);
      } else {
        if (_currentSelectedIds.length < widget.maxSelection) {
          _currentSelectedIds.add(categoryId);
        } else if (widget.maxSelection == 1) {
          // Если можно выбрать только одну категорию, заменяем
          _currentSelectedIds.clear();
          _currentSelectedIds.add(categoryId);
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
                  'Выбор категорий',
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
            hintText: 'Поиск категорий...',
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

        // Счетчик выбранных категорий
        if (widget.maxSelection > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Выбrano: ${_currentSelectedIds.length} из ${widget.maxSelection}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

        // Список категорий
        Expanded(
          child: _categories.isEmpty && !_isLoading
              ? const Center(child: Text('Категории не найдены'))
              : ListView.builder(
                  controller: widget.scrollController ?? _listScrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _categories.length) {
                      // Индикатор загрузки
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final category = _categories[index];
                    final isSelected = _currentSelectedIds.contains(
                      category.id,
                    );
                    final canSelect =
                        isSelected ||
                        _currentSelectedIds.length < widget.maxSelection;

                    return Card(
                      child: ListTile(
                        title: Text(category.name),
                        subtitle: category.description?.isNotEmpty == true
                            ? Text(category.description!)
                            : null,
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse('FF${category.color}', radix: 16),
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        trailing: widget.maxSelection == 1
                            ? Radio<String>(
                                value: category.id,
                                groupValue: _currentSelectedIds.isNotEmpty
                                    ? _currentSelectedIds.first
                                    : null,
                                onChanged: canSelect
                                    ? (_) => _toggleCategory(category.id)
                                    : null,
                              )
                            : Checkbox(
                                value: isSelected,
                                onChanged: canSelect
                                    ? (_) => _toggleCategory(category.id)
                                    : null,
                              ),
                        onTap: canSelect
                            ? () => _toggleCategory(category.id)
                            : null,
                      ),
                    );
                  },
                ),
        ),

        // Кнопки действий
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelSelection,
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmSelection,
                  child: const Text('Подтвердить'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
