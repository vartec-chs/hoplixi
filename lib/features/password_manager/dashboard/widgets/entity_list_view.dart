import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/models/entety_type.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/entety_type_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/filter_providers/paginated_passwords_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/password_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/entity_action_modal.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/router/routes_path.dart';

/// Виджет для отображения списков различных сущностей с пагинацией
class EntityListView extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const EntityListView({super.key, this.scrollController});

  @override
  ConsumerState<EntityListView> createState() => _EntityListViewState();
}

class _EntityListViewState extends ConsumerState<EntityListView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    final entityType = ref.read(currentEntityTypeProvider);

    // Пагинация только для паролей пока что
    if (entityType != EntityType.password) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Загружаем больше данных когда до конца остается 200 пикселей
      ref.read(paginatedPasswordsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entityType = ref.watch(currentEntityTypeProvider);

    logDebug('Текущий тип сущности: $entityType', tag: 'EntityListView');

    switch (entityType) {
      case EntityType.password:
        return _buildPasswordsList();
      case EntityType.note:
        return _buildNotImplementedView('Заметки', Icons.note);
      case EntityType.otp:
        return _buildNotImplementedView('OTP', Icons.security);
    }
  }

  Widget _buildPasswordsList() {
    final passwordsAsync = ref.watch(paginatedPasswordsProvider);

    return passwordsAsync.when(
      loading: () => const _LoadingSliverView(),
      error: (error, _) => _ErrorSliverView(
        error: error.toString(),
        onRetry: () {
          ref.read(paginatedPasswordsProvider.notifier).refresh();
        },
      ),
      data: (state) => _PasswordsSliverList(
        state: state,
        scrollController: _scrollController,
        onPasswordFavoriteToggle: _onPasswordFavoriteToggle,
        onPasswordEdit: _onPasswordEdit,
        onPasswordDelete: _onPasswordDelete,
        onPasswordLongPress: _onPasswordLongPress,
      ),
    );
  }

  Widget _buildNotImplementedView(String title, IconData icon) {
    return SliverFillRemaining(
      child: _EmptyView(
        title: title,
        subtitle: 'Функционал находится в разработке',
        icon: icon,
        isNotImplemented: true,
      ),
    );
  }

  void _onPasswordFavoriteToggle(CardPasswordDto password) {
    logInfo(
      'EntityListView: Переключение избранного для пароля ${password.id}',
    );
    if (mounted) {
      ref.read(paginatedPasswordsProvider.notifier).toggleFavorite(password.id);
    }
  }

  void _onPasswordEdit(CardPasswordDto password) {
    logInfo('EntityListView: Редактирование пароля ${password.id}');
    context.push('${AppRoutes.passwordForm}/${password.id}');
  }

  void _onPasswordDelete(CardPasswordDto password) {
    logInfo('EntityListView: Удаление пароля ${password.id}');
    if (mounted) {
      ref.read(paginatedPasswordsProvider.notifier).deletePassword(password.id);
    }
  }

  void _onPasswordLongPress(CardPasswordDto password) {
    logInfo('EntityListView: Долгое нажатие на пароль ${password.id}');
    EntityActionModalHelper.showPasswordActions(
      context,
      passwordName: password.name,
      loginOrEmail: password.login ?? password.email ?? 'Нет данных',
      onEdit: () => _onPasswordEdit(password),
      onDelete: () => _onPasswordDelete(password),
    );
  }
}

/// Виджет списка паролей как Sliver
class _PasswordsSliverList extends StatelessWidget {
  final PaginatedPasswordsState state;
  final ScrollController? scrollController;
  final Function(CardPasswordDto) onPasswordFavoriteToggle;
  final Function(CardPasswordDto) onPasswordEdit;
  final Function(CardPasswordDto) onPasswordDelete;
  final Function(CardPasswordDto) onPasswordLongPress;

  const _PasswordsSliverList({
    required this.state,
    this.scrollController,
    required this.onPasswordFavoriteToggle,
    required this.onPasswordEdit,
    required this.onPasswordDelete,
    required this.onPasswordLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (state.passwords.isEmpty) {
      return const SliverFillRemaining(
        child: _EmptyView(
          title: 'Нет паролей',
          subtitle: 'Создайте первый пароль, чтобы начать работу',
          icon: Icons.password,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Обработка индикатора загрузки
          if (index == state.passwords.length) {
            if (state.isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (!state.hasMore) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Все пароли загружены (${state.totalCount})',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final password = state.passwords[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              index == 0 ? 16 : 8,
              8,
              index == state.passwords.length - 1 && !state.hasMore ? 16 : 8,
            ),
            child: PasswordCard(
              password: password,
              onFavoriteToggle: () => onPasswordFavoriteToggle(password),
              onEdit: () => onPasswordEdit(password),
              onDelete: () => onPasswordDelete(password),
              onLongPress: () => onPasswordLongPress(password),
            ),
          );
        },
        childCount:
            state.passwords.length +
            (state.isLoadingMore || !state.hasMore ? 1 : 0),
      ),
    );
  }
}

/// Виджет загрузки как Sliver
class _LoadingSliverView extends StatelessWidget {
  const _LoadingSliverView();

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка данных...'),
          ],
        ),
      ),
    );
  }
}

/// Виджет ошибки как Sliver
class _ErrorSliverView extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const _ErrorSliverView({required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Center(
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
              'Произошла ошибка',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Виджет пустого состояния
class _EmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isNotImplemented;

  const _EmptyView({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isNotImplemented = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isNotImplemented
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          if (isNotImplemented) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'В разработке',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
