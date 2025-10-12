import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/cloud_sync/providers/token_provider.dart';
import 'package:hoplixi/features/cloud_sync/services/oauth2_account_service.dart';
import 'package:hoplixi/features/global/widgets/button.dart';

/// Экран для отображения всех OAuth токенов
class TokenListScreen extends ConsumerWidget {
  const TokenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(tokenListProvider);
    final countAsync = ref.watch(tokenCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OAuth Токены'),
        actions: [
          if (asyncValue.hasValue && asyncValue.value!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(tokenListProvider.notifier).refresh();
                ref.invalidate(tokenCountProvider);
              },
              tooltip: 'Обновить',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Статистика
            _buildStatisticsCard(context, countAsync),
            const SizedBox(height: 8),
            // Список токенов
            Expanded(child: _buildBody(context, ref, asyncValue)),
          ],
        ),
      ),
      floatingActionButton: asyncValue.hasValue && asyncValue.value!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _confirmClearAll(context, ref),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Очистить всё'),
              backgroundColor: Theme.of(context).colorScheme.error,
            )
          : null,
    );
  }

  Widget _buildStatisticsCard(
    BuildContext context,
    AsyncValue<int> countAsync,
  ) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Icon(Icons.key, color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сохранённые токены',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  countAsync.when(
                    data: (count) => Text(
                      '$count ${_pluralizeTokens(count)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => Text(
                      'Ошибка подсчёта',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TokenInfo>> asyncValue,
  ) {
    return asyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
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
              'Ошибка загрузки токенов',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            SmoothButton(
              label: 'Повторить',
              onPressed: () {
                ref.read(tokenListProvider.notifier).refresh();
              },
            ),
          ],
        ),
      ),
      data: (tokens) {
        if (tokens.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.vpn_key_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет сохранённых токенов',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Выполните авторизацию OAuth для создания токенов',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(tokenListProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: tokens.length,
            itemBuilder: (context, index) {
              final tokenInfo = tokens[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TokenCard(
                  tokenInfo: tokenInfo,
                  onDelete: () => _confirmDelete(context, ref, tokenInfo),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    TokenInfo tokenInfo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление токена'),
        content: Text(
          'Вы действительно хотите удалить токен для "${tokenInfo.token.userName}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(tokenListProvider.notifier)
          .deleteToken(tokenInfo.key);

      if (success && context.mounted) {
        ToastHelper.success(title: 'Токен удалён');
        ref.invalidate(tokenCountProvider);
      } else if (context.mounted) {
        ToastHelper.error(title: 'Не удалось удалить токен');
      }
    }
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все токены'),
        content: const Text(
          'Вы действительно хотите удалить ВСЕ токены? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Удалить всё'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(tokenListProvider.notifier).clearAll();

      if (success && context.mounted) {
        ToastHelper.success(title: 'Все токены удалены');
        ref.invalidate(tokenCountProvider);
      } else if (context.mounted) {
        ToastHelper.error(title: 'Не удалось удалить токены');
      }
    }
  }

  String _pluralizeTokens(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'токен';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'токена';
    } else {
      return 'токенов';
    }
  }
}

/// Карточка отображения токена
class _TokenCard extends StatelessWidget {
  final TokenInfo tokenInfo;
  final VoidCallback onDelete;

  const _TokenCard({required this.tokenInfo, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = tokenInfo.token;

    // Определяем статус токена
    final needsRefresh = token.timeToRefresh;
    final needsLogin = token.timeToLogin;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (needsLogin) {
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.error_outline;
      statusText = 'Требуется повторный вход';
    } else if (needsRefresh) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Требуется обновление';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
      statusText = 'Активен';
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showTokenDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.key, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          token.userName.isNotEmpty
                              ? token.userName
                              : ProviderTypeX.fromKey(tokenInfo.key).name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: theme.colorScheme.error,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(context, 'Ключ', tokenInfo.key),
              const SizedBox(height: 4),
              _buildInfoRow(context, 'Провайдер', token.iss),
              const SizedBox(height: 4),
              _buildInfoRow(
                context,
                'Access Token',
                _maskString(token.accessToken),
              ),
              if (token.refreshToken.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  context,
                  'Refresh Token',
                  _maskString(token.refreshToken),
                ),
              ],
              const SizedBox(height: 4),
              _buildInfoRow(
                context,
                'Можно обновить',
                token.canRefresh ? 'Да' : 'Нет',
                isWarning: !token.canRefresh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isWarning ? theme.colorScheme.error : null,
              fontWeight: isWarning ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }

  void _showTokenDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _TokenDetailsDialog(tokenInfo: tokenInfo),
    );
  }

  String _maskString(String value) {
    if (value.isEmpty) return '—';
    if (value.length <= 8) {
      return '${value.substring(0, 2)}***';
    }
    return '${value.substring(0, 8)}...${value.substring(value.length - 8)}';
  }
}

/// Диалог с деталями токена
class _TokenDetailsDialog extends StatelessWidget {
  final TokenInfo tokenInfo;

  const _TokenDetailsDialog({required this.tokenInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final token = tokenInfo.token;

    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.key, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Детали токена',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCopyableField(context, 'Ключ', tokenInfo.key),
                const SizedBox(height: 16),
                _buildCopyableField(
                  context,
                  'Имя пользователя',
                  token.userName,
                ),
                const SizedBox(height: 16),
                _buildCopyableField(context, 'Провайдер', token.iss),
                const SizedBox(height: 16),
                _buildCopyableField(context, 'Access Token', token.accessToken),
                if (token.refreshToken.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildCopyableField(
                    context,
                    'Refresh Token',
                    token.refreshToken,
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusChip(
                        context,
                        'Можно обновить',
                        token.canRefresh,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildStatusChip(
                        context,
                        'Требует обновления',
                        token.timeToRefresh,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStatusChip(
                  context,
                  'Требуется повторный вход',
                  token.timeToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCopyableField(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value.isNotEmpty ? value : '—',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ToastHelper.success(title: 'Скопировано', description: label);
                },
                tooltip: 'Скопировать',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, bool value) {
    final theme = Theme.of(context);
    final color = value
        ? Colors.green
        : theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: value
                ? Colors.green
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: value
                    ? Colors.green
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
