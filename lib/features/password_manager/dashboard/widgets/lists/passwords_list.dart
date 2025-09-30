import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/lists_providers/paginated_passwords_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/password_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/lists/empty_list.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

/// Виджет списка паролей как Sliver
class PasswordsSliverList extends StatelessWidget {
  final PaginatedPasswordsState state;
  final ScrollController? scrollController;
  final Function(CardPasswordDto) onPasswordFavoriteToggle;
  final Function(CardPasswordDto) onPasswordEdit;
  final Function(CardPasswordDto) onPasswordDelete;
  final Function(CardPasswordDto) onPasswordLongPress;

  const PasswordsSliverList({
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
        child: EmptyView(
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
