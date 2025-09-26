import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend_prototype/providers/index.dart';
import 'package:hoplixi/features/localsend_prototype/widgets/index.dart';

/// Вкладка с историей сообщений
class MessagesTab extends ConsumerWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageHistory = ref.watch(messageHistoryProvider);

    if (messageHistory.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: messageHistory.length,
      itemBuilder: (context, index) {
        final message = messageHistory[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: MessageCard(
            message: message,
            deviceName: 'Device ${message.senderId.substring(0, 8)}',
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: colors.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Нет сообщений',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Отправленные и полученные сообщения\nбудут отображаться здесь',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
