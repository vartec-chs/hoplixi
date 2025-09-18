import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/features/passwords_list_section/password_card.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'passwords_list_controller.dart';

/// Современный компонент для отображения списка паролей с использованием AsyncNotifier
///
/// Особенности:
/// - Использует AsyncNotifier для управления состоянием
/// - Поддерживает пагинацию
/// - Интегрируется в CustomScrollView через Slivers
/// - Автоматически реагирует на изменения фильтров
/// - Обработка состояний loading/error/data через AsyncValue
class PasswordsList extends ConsumerStatefulWidget {
  /// Внешний ScrollController для обработки пагинации
  final ScrollController? scrollController;

  const PasswordsList({super.key, this.scrollController});

  @override
  ConsumerState<PasswordsList> createState() => _PasswordsListState();
}

class _PasswordsListState extends ConsumerState<PasswordsList> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    // Используем внешний контроллер или создаем свой
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    // Освобождаем только если создали сами
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  /// Обработка скролла для пагинации
  void _onScroll() {
    if (_isLoadingMore) return;

    final position = _scrollController.position;

    // Загружаем больше данных, если приблизились к концу списка
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMorePasswords();
    }
  }

  /// Загрузка дополнительных паролей (пагинация)
  Future<void> _loadMorePasswords() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await ref
          .read(passwordsListControllerProvider.notifier)
          .loadMorePasswords();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  /// Обработка pull-to-refresh
  Future<void> _handleRefresh() async {
    await ref.read(passwordsListControllerProvider.notifier).refreshPasswords();
  }

  /// Переключение избранного
  Future<void> _handleFavoriteToggle(String passwordId) async {
    await ref
        .read(passwordsListControllerProvider.notifier)
        .toggleFavorite(passwordId);
  }

  /// Редактирование пароля
  void _handleEdit(String passwordId) {
    context.push('${AppRoutes.passwordForm}/$passwordId');
  }

  /// Удаление пароля с подтверждением
  Future<void> _handleDelete(String passwordId) async {
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await ref
          .read(passwordsListControllerProvider.notifier)
          .deletePassword(passwordId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(passwordsListControllerProvider);
    final hasMorePasswords = ref.watch(hasMorePasswordsProvider);

    return SliverMainAxisGroup(
      slivers: [
        // Заголовок с количеством паролей
        _buildHeader(context),

        // Обработка состояний через AsyncValue.when
        ...asyncState.when(
          // Состояние загрузки (первоначальная загрузка)
          loading: () => [_buildLoadingSliver(context)],

          // Состояние ошибки
          error: (error, stackTrace) => [
            _buildErrorSliver(context, error.toString()),
          ],

          // Состояние с данными
          data: (state) {
            if (state.passwords.isEmpty) {
              return [_buildEmptySliver(context)];
            }

            return [
              // Основной список паролей
              _buildPasswordsList(context, state.passwords),

              // Индикатор загрузки дополнительных данных
              if (_isLoadingMore && hasMorePasswords)
                _buildPaginationLoader(context),

              // Дополнительный отступ снизу для FAB
              const SliverPadding(padding: EdgeInsets.only(bottom: 100.0)),
            ];
          },
        ),
      ],
    );
  }

  /// Заголовок с количеством паролей
  Widget _buildHeader(BuildContext context) {
    final totalCount = ref.watch(passwordsTotalCountProvider);
    final theme = Theme.of(context);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Пароли ($totalCount)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Индикатор первоначальной загрузки
  Widget _buildLoadingSliver(BuildContext context) {
    final theme = Theme.of(context);

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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Индикатор загрузки дополнительных данных (пагинация)
  Widget _buildPaginationLoader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
    );
  }

  /// Отображение ошибки
  Widget _buildErrorSliver(BuildContext context, String error) {
    final theme = Theme.of(context);

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
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
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
  Widget _buildEmptySliver(BuildContext context) {
    final theme = Theme.of(context);

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
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Паролей не найдено',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Попробуйте изменить фильтры или добавить новый пароль',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Основной список паролей
  Widget _buildPasswordsList(
    BuildContext context,
    List<CardPasswordDto> passwords,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList.separated(
        itemCount: passwords.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final password = passwords[index];

          return PasswordCard(
            password: password,
            onFavoriteToggle: () => _handleFavoriteToggle(password.id),
            onEdit: () => _handleEdit(password.id),
            onDelete: () => _handleDelete(password.id),
          );
        },
      ),
    );
  }
}
