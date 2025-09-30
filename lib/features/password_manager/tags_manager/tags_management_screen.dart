import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/index.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'tags_management_control.dart';
import 'widgets/tag_create_edit_modal.dart';
import 'widgets/tag_item_widget.dart';
import 'widgets/tag_filters_widget.dart';

class TagsManagementScreen extends ConsumerStatefulWidget {
  const TagsManagementScreen({super.key});

  @override
  ConsumerState<TagsManagementScreen> createState() =>
      _TagsManagementScreenState();
}

class _TagsManagementScreenState extends ConsumerState<TagsManagementScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      ref.read(tagsManagementProvider.notifier).loadMore();
    }
  }

  Future<void> _showCreateTagModal() async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const TagCreateEditModal(),
    );
  }

  Future<void> _showEditTagModal(store.Tag tag) async {
    await showModalBottomSheet(
      
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TagCreateEditModal(tag: tag),
    );
  }

  void _onSearch(String query) {
    ref.read(tagsManagementProvider.notifier).searchTags(query);
  }

  void _onFilterChanged(TagType? type) {
    ref.read(tagsManagementProvider.notifier).filterByType(type);
  }

  void _onSortChanged(String sortBy) {
    ref.read(tagsManagementProvider.notifier).sort(sortBy);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tagsManagementProvider);
    final notifier = ref.read(tagsManagementProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление тегами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: PrimaryTextField(
              controller: _searchController,
              hintText: 'Поиск тегов...',
              prefixIcon: const Icon(Icons.search),
              onChanged: _onSearch,
            ),
          ),

          // Фильтры
          TagFiltersWidget(
            selectedType: state.filterType,
            selectedSort: state.sortBy,
            isAscending: state.isAscending,
            onTypeChanged: _onFilterChanged,
            onSortChanged: _onSortChanged,
          ),

          // Статистика
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Всего тегов: ${state.totalCount}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (state.searchQuery.isNotEmpty)
                  Text(
                    'Найдено: ${state.tags.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),

          // Список тегов
          Expanded(child: _buildTagsList(state)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTagModal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTagsList(TagsManagementState state) {
    if (state.isLoading && state.tags.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(tagsManagementProvider.notifier).refresh(),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (state.tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Теги не найдены',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте первый тег',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showCreateTagModal,
              icon: const Icon(Icons.add),
              label: const Text('Создать тег'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tagsManagementProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.tags.length + (state.hasMore ? 1 : 0),
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          if (index >= state.tags.length) {
            // Показываем индикатор загрузки для следующей страницы
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final tag = state.tags[index];
          return TagItemWidget(
            tag: tag,
            onEdit: () => _showEditTagModal(tag),
            onDelete: () => _confirmDeleteTag(tag),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteTag(store.Tag tag) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить тег?'),
        content: Text('Вы уверены, что хотите удалить тег "${tag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref
          .read(tagsManagementProvider.notifier)
          .deleteTag(tag.id);
      if (success && mounted) {
        ToastHelper.success(
          title: 'Тег удален',
          description: 'Тег "${tag.name}" успешно удален.',
          context: context,
        );
      }
    }
  }
}
