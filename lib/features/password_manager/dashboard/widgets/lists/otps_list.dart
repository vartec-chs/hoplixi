import 'package:flutter/material.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/lists_providers/paginated_otps_provider.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/cards/otp_card.dart';
import 'package:hoplixi/features/password_manager/dashboard/widgets/lists/empty_list.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

/// Виджет списка OTP как Sliver
class OtpsSliverList extends StatelessWidget {
  final PaginatedOtpsState state;
  final ScrollController? scrollController;
  final Function(CardOtpDto) onOtpFavoriteToggle;
  final Function(CardOtpDto) onOtpEdit;
  final Function(CardOtpDto) onOtpDelete;
  final Function(CardOtpDto) onOtpLongPress;

  const OtpsSliverList({
    required this.state,
    this.scrollController,
    required this.onOtpFavoriteToggle,
    required this.onOtpEdit,
    required this.onOtpDelete,
    required this.onOtpLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (state.otps.isEmpty) {
      return const SliverFillRemaining(
        child: EmptyView(
          title: 'Нет OTP',
          subtitle: 'Создайте первый OTP токен, чтобы начать работу',
          icon: Icons.security,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          // Обработка индикатора загрузки
          if (index == state.otps.length) {
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
                    'Все OTP загружены (${state.totalCount})',
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

          final otp = state.otps[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(
              8,
              index == 0 ? 16 : 8,
              8,
              index == state.otps.length - 1 && !state.hasMore ? 16 : 8,
            ),
            child: TotpCard(
              totp: otp,
              onFavoriteToggle: () => onOtpFavoriteToggle(otp),
              onEdit: () => onOtpEdit(otp),
              onDelete: () => onOtpDelete(otp),
              onLongPress: () => onOtpLongPress(otp),
            ),
          );
        },
        childCount:
            state.otps.length + (state.isLoadingMore || !state.hasMore ? 1 : 0),
      ),
    );
  }
}
