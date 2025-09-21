import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/universal_filter/controllers/password_list_controller.dart';
import 'package:hoplixi/features/password_manager/universal_filter/widgets/password_card.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Виджет для отображения списка паролей с пагинацией
class PasswordsList extends ConsumerStatefulWidget {
  final VoidCallback? onPasswordTap;
  final Function(CardPasswordDto)? onPasswordLongPress;
  final Function(CardPasswordDto)? onPasswordEdit;
  final Function(CardPasswordDto)? onPasswordDelete;
  final Function(CardPasswordDto)? onPasswordFavoriteToggle;

  const PasswordsList({
    super.key,
    this.onPasswordTap,
    this.onPasswordLongPress,
    this.onPasswordEdit,
    this.onPasswordDelete,
    this.onPasswordFavoriteToggle,
  });

  @override
  ConsumerState<PasswordsList> createState() => _PasswordsListState();
}

class _PasswordsListState extends ConsumerState<PasswordsList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Добавляем слушатель прокрутки для пагинации
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Загружаем больше паролей когда прокрутили почти до конца
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePasswords();
    }
  }

  void _loadMorePasswords() {
    final controller = ref.read(passwordListControllerProvider.notifier);
    controller.loadMorePasswords();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordListControllerProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(passwordListControllerProvider.notifier).refresh();
      },
      child: Column(
        children: [
          _buildHeader(state),
          Expanded(child: _buildList(state, theme)),
        ],
      ),
    );
  }

  Widget _buildHeader(state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          if (state.isLoadingFirstPage)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          else
            Icon(Icons.key, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            state.isEmpty
                ? 'Паролей не найдено'
                : 'Паролей: ${state.passwords.length}${state.totalCount > 0 ? ' из ${state.totalCount}' : ''}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const Spacer(),
          if (state.hasMore && !state.isLoadingFirstPage)
            TextButton.icon(
              onPressed: _loadMorePasswords,
              icon: state.isLoadingMore
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(Icons.more_horiz, size: 16),
              label: Text(state.isLoadingMore ? 'Загрузка...' : 'Еще'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                textStyle: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(state, ThemeData theme) {
    if (state.error != null) {
      return _buildErrorState(state.error!, theme);
    }

    if (state.isLoadingFirstPage) {
      return _buildLoadingState(theme);
    }

    if (state.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: state.passwords.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Показываем индикатор загрузки в конце списка
        if (index >= state.passwords.length) {
          return _buildLoadingMoreIndicator(theme);
        }

        final password = state.passwords[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PasswordCard(
            password: password,
            onFavoriteToggle: () => _handleFavoriteToggle(password),
            onEdit: () => _handleEdit(password),
            onDelete: () => _handleDelete(password),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Загрузка паролей...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Пароли не найдены',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить фильтры поиска или создать новый пароль',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
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
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ref.read(passwordListControllerProvider.notifier).refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Загрузка...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFavoriteToggle(CardPasswordDto password) {
    try {
      widget.onPasswordFavoriteToggle?.call(password);
      logDebug('Переключение избранного для пароля: ${password.name}');
    } catch (e, stackTrace) {
      logError(
        'Ошибка переключения избранного',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleEdit(CardPasswordDto password) {
    try {
      widget.onPasswordEdit?.call(password);
      logDebug('Редактирование пароля: ${password.name}');
    } catch (e, stackTrace) {
      logError(
        'Ошибка редактирования пароля',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleDelete(CardPasswordDto password) {
    try {
      widget.onPasswordDelete?.call(password);
      logDebug('Удаление пароля: ${password.name}');
    } catch (e, stackTrace) {
      logError('Ошибка удаления пароля', error: e, stackTrace: stackTrace);
    }
  }
}
