import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'passwords_list_controller.dart';

/// Компонент для отображения отфильтрованного списка паролей
/// Использует Slivers для оптимальной производительности
class PasswordsList extends ConsumerStatefulWidget {
  const PasswordsList({super.key});

  @override
  ConsumerState<PasswordsList> createState() => _PasswordsListState();
}

class _PasswordsListState extends ConsumerState<PasswordsList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Загружаем данные при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(passwordsListControllerProvider.notifier).loadPasswords();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Обработка скролла для пагинации
  void _onScroll() {
    if (_isLoadingMore) return;

    const double threshold = 200.0;
    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double currentScrollOffset = _scrollController.offset;

    if (currentScrollOffset >= (maxScrollExtent - threshold)) {
      final hasMore = ref.read(hasMorePasswordsProvider);

      if (hasMore) {
        _loadMorePasswords();
      }
    }
  }

  /// Загрузка дополнительных паролей
  Future<void> _loadMorePasswords() async {
    if (_isLoadingMore) return;

    setState(() => _isLoadingMore = true);
    await ref
        .read(passwordsListControllerProvider.notifier)
        .loadMorePasswords();
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  /// Обработка pull-to-refresh
  Future<void> _handleRefresh() async {
    await ref.read(passwordsListControllerProvider.notifier).refreshPasswords();
  }

  /// Переключение избранного
  void _handleFavoriteToggle(String passwordId) {
    ref
        .read(passwordsListControllerProvider.notifier)
        .toggleFavorite(passwordId);
  }

  /// Редактирование пароля
  void _handleEdit(String passwordId) {
    // TODO: Навигация к экрану редактирования пароля
    // Navigator.of(context).pushNamed('/password-edit', arguments: passwordId);
    debugPrint('Редактирование пароля: $passwordId');
  }

  /// Удаление пароля
  Future<void> _handleDelete(String passwordId) async {
    // Показываем диалог подтверждения
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Удаление пароля'),
        content: const Text('Вы уверены, что хотите удалить этот пароль?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      ref
          .read(passwordsListControllerProvider.notifier)
          .deletePassword(passwordId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passwordsState = ref.watch(passwordsListControllerProvider);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Заголовок с количеством паролей
          _buildHeader(passwordsState.totalCount),

          // Обработка состояний загрузки и ошибок
          if (passwordsState.isLoading && passwordsState.passwords.isEmpty)
            _buildLoadingSliver()
          else if (passwordsState.error != null &&
              passwordsState.passwords.isEmpty)
            _buildErrorSliver(passwordsState.error!)
          else if (passwordsState.passwords.isEmpty)
            _buildEmptySliver()
          else
            _buildPasswordsList(passwordsState.passwords),

          // Индикатор загрузки дополнительных элементов
          if (_isLoadingMore || passwordsState.hasMore) _buildLoadMoreSliver(),

          // Дополнительный отступ снизу
          const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
        ],
      ),
    );
  }

  /// Заголовок с количеством паролей
  Widget _buildHeader(int totalCount) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Пароли ($totalCount)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Индикатор загрузки
  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Загрузка паролей...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Отображение ошибки
  Widget _buildErrorSliver(String error) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _handleRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Попробовать снова'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Пустой список
  Widget _buildEmptySliver() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_open_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Паролей не найдено',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Попробуйте изменить фильтры или добавить новый пароль',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Список паролей
  Widget _buildPasswordsList(List<CardPasswordDto> passwords) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList.separated(
        itemCount: passwords.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final password = passwords[index];

          return ModernPasswordCard(
            password: password,
            onFavoriteToggle: () => _handleFavoriteToggle(password.id),
            onEdit: () => _handleEdit(password.id),
            onDelete: () => _handleDelete(password.id),
          );
        },
      ),
    );
  }

  /// Индикатор загрузки дополнительных элементов
  Widget _buildLoadMoreSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: _isLoadingMore
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Современная карточка пароля с поддержкой тегов
class ModernPasswordCard extends StatelessWidget {
  final CardPasswordDto password;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ModernPasswordCard({
    super.key,
    required this.password,
    required this.onFavoriteToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с кнопкой избранного
              Row(
                children: [
                  Expanded(
                    child: Text(
                      password.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onFavoriteToggle,
                    icon: Icon(
                      password.isFavorite ? Icons.star : Icons.star_outline,
                      color: password.isFavorite
                          ? Colors.amber
                          : theme.colorScheme.outline,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined),
                            SizedBox(width: 12),
                            Text('Редактировать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 12),
                            Text(
                              'Удалить',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),

              // Описание
              if (password.description != null &&
                  password.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  password.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Логин и email
              const SizedBox(height: 12),
              Row(
                children: [
                  if (password.login != null && password.login!.isNotEmpty) ...[
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        password.login!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (password.login != null &&
                      password.login!.isNotEmpty &&
                      password.email != null &&
                      password.email!.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Container(
                      width: 1,
                      height: 12,
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (password.email != null && password.email!.isNotEmpty) ...[
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        password.email!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),

              // Теги (максимум 4)
              if (password.tags != null && password.tags!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildTagsRow(password.tags!, theme),
              ],

              // Категории
              if (password.categories != null &&
                  password.categories!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildCategoriesRow(password.categories!, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Построение строки с тегами
  Widget _buildTagsRow(List<CardPasswordTagDto> tags, ThemeData theme) {
    // Показываем максимум 4 тега
    final displayTags = tags.take(4).toList();
    final hasMore = tags.length > 4;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        ...displayTags.map((tag) => _buildTagChip(tag, theme)),
        if (hasMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${tags.length - 4}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
      ],
    );
  }

  /// Построение чипа тега
  Widget _buildTagChip(CardPasswordTagDto tag, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tag.color != null
            ? Color(int.parse('FF${tag.color}', radix: 16)).withOpacity(0.1)
            : theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tag.color != null
              ? Color(int.parse('FF${tag.color}', radix: 16)).withOpacity(0.3)
              : theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        tag.name,
        style: theme.textTheme.labelSmall?.copyWith(
          color: tag.color != null
              ? Color(int.parse('FF${tag.color}', radix: 16))
              : theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Построение строки с категориями
  Widget _buildCategoriesRow(
    List<CardPasswordCategoryDto> categories,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 8,
      children: categories
          .map((category) => _buildCategoryChip(category, theme))
          .toList(),
    );
  }

  /// Построение чипа категории
  Widget _buildCategoryChip(CardPasswordCategoryDto category, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Color(
          int.parse('FF${category.color}', radix: 16),
        ).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(
            int.parse('FF${category.color}', radix: 16),
          ).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Color(int.parse('FF${category.color}', radix: 16)),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            category.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
