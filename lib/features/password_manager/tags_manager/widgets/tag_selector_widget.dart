import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/index.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'package:hoplixi/hoplixi_store/services/tags_service.dart';

/// Универсальный виджет для выбора тегов
class TagSelectorWidget extends ConsumerStatefulWidget {
  final TagType? filterType;
  final List<String> initialSelectedTagIds;
  final ValueChanged<List<store.Tag>> onSelectionChanged;
  final String? title;
  final Widget? emptyWidget;
  final bool showSelectedTags;
  final bool allowMultiple;

  const TagSelectorWidget({
    super.key,
    this.filterType,
    this.initialSelectedTagIds = const [],
    required this.onSelectionChanged,
    this.title,
    this.emptyWidget,
    this.showSelectedTags = true,
    this.allowMultiple = true,
  });

  @override
  ConsumerState<TagSelectorWidget> createState() => _TagSelectorWidgetState();
}

class _TagSelectorWidgetState extends ConsumerState<TagSelectorWidget> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  List<store.Tag> _allTags = [];
  Set<String> _selectedTagIds = {};
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = false;
  String _searchQuery = '';

  late TagsService _tagsService;

  @override
  void initState() {
    super.initState();
    _selectedTagIds = Set.from(widget.initialSelectedTagIds);
    _scrollController.addListener(_onScroll);

    // Инициализируем сервис и загружаем теги сразу, но через Future.microtask
    // чтобы избежать "Build scheduled during frame"
    Future.microtask(() => _initializeService());
  }

  void _initializeService() {
    try {
      _tagsService = ref.read(tagsServiceProvider);
      _loadTags();
    } catch (e) {
      setState(() {
        _error = 'Ошибка инициализации: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadTags({bool append = false}) async {
    if (_isLoading && !append) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = append ? _currentPage + 1 : 1;

      final result = await _tagsService.getTagsPaginated(
        page: page,
        pageSize: 20,
        orderBy: 'name',
        ascending: true,
        type: widget.filterType,
        searchTerm: _searchQuery.isEmpty ? null : _searchQuery,
      );

      setState(() {
        if (append) {
          _allTags.addAll(result.tags);
        } else {
          _allTags = result.tags;
        }
        _currentPage = page;
        _hasMore = result.hasMore;
        _isLoading = false;
      });

      _notifySelectionChanged();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка загрузки тегов: ${e.toString()}';
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoading) return;
    await _loadTags(append: true);
  }

  void _searchTags(String query) {
    if (query == _searchQuery) return;

    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _allTags = [];
    });

    _loadTags();
  }

  void _toggleTag(String tagId) {
    setState(() {
      if (widget.allowMultiple) {
        if (_selectedTagIds.contains(tagId)) {
          _selectedTagIds.remove(tagId);
        } else {
          _selectedTagIds.add(tagId);
        }
      } else {
        _selectedTagIds.clear();
        _selectedTagIds.add(tagId);
      }
    });

    _notifySelectionChanged();
  }

  void _removeSelectedTag(String tagId) {
    setState(() {
      _selectedTagIds.remove(tagId);
    });
    _notifySelectionChanged();
  }

  void _notifySelectionChanged() {
    final selectedTags = _allTags
        .where((tag) => _selectedTagIds.contains(tag.id))
        .toList();
    widget.onSelectionChanged(selectedTags);
  }

  Color _getTagColor(store.Tag tag) {
    if (tag.color != null && tag.color!.isNotEmpty) {
      try {
        return Color(int.parse(tag.color!.replaceAll('#', '0xFF')));
      } catch (e) {
        return _getDefaultTypeColor(tag.type);
      }
    }
    return _getDefaultTypeColor(tag.type);
  }

  Color _getDefaultTypeColor(TagType type) {
    switch (type) {
      case TagType.password:
        return Colors.blue;
      case TagType.notes:
        return Colors.green;
      case TagType.totp:
        return Colors.orange;
      case TagType.mixed:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(TagType type) {
    switch (type) {
      case TagType.password:
        return Icons.lock;
      case TagType.notes:
        return Icons.note;
      case TagType.totp:
        return Icons.security;
      case TagType.mixed:
        return Icons.category;
    }
  }

  String _getTypeLabel(TagType type) {
    switch (type) {
      case TagType.password:
        return 'Пароли';
      case TagType.notes:
        return 'Заметки';
      case TagType.totp:
        return 'TOTP';
      case TagType.mixed:
        return 'Смешанный';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTags = _allTags
        .where((tag) => _selectedTagIds.contains(tag.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок
        if (widget.title != null) ...[
          Text(widget.title!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
        ],

        // Выбранные теги
        if (widget.showSelectedTags && selectedTags.isNotEmpty) ...[
          Text(
            'Выбранные теги (${selectedTags.length})',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: selectedTags.map((tag) {
              return Chip(
                avatar: CircleAvatar(
                  backgroundColor: _getTagColor(tag),
                  radius: 12,
                  child: Icon(
                    _getTypeIcon(tag.type),
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                label: Text(tag.name),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeSelectedTag(tag.id),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Поиск
        PrimaryTextField(
          controller: _searchController,
          hintText: 'Поиск тегов...',
          prefixIcon: const Icon(Icons.search),
          onChanged: _searchTags,
        ),

        const SizedBox(height: 16),

        // Список тегов
        Expanded(child: _buildTagsList()),
      ],
    );
  }

  Widget _buildTagsList() {
    if (_isLoading && _allTags.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _allTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadTags(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_allTags.isEmpty) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_offer, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Теги не найдены',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _allTags.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _allTags.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final tag = _allTags[index];
        final isSelected = _selectedTagIds.contains(tag.id);

        return CheckboxListTile(
          value: isSelected,
          onChanged: (_) => _toggleTag(tag.id),
          title: Text(tag.name),
          subtitle: Row(
            children: [
              Icon(_getTypeIcon(tag.type), size: 16, color: _getTagColor(tag)),
              const SizedBox(width: 4),
              Text(_getTypeLabel(tag.type)),
            ],
          ),
          secondary: CircleAvatar(
            backgroundColor: _getTagColor(tag),
            radius: 16,
            child: Icon(_getTypeIcon(tag.type), color: Colors.white, size: 16),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        );
      },
    );
  }
}
