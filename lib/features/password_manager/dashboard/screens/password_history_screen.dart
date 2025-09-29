import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/password_manager/dashboard/controllers/password_history/password_history_list_provider.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:intl/intl.dart';

class PasswordHistoryScreen extends ConsumerStatefulWidget {
  final String passwordId;

  const PasswordHistoryScreen({super.key, required this.passwordId});

  @override
  ConsumerState<PasswordHistoryScreen> createState() =>
      _PasswordHistoryScreenState();
}

class _PasswordHistoryScreenState extends ConsumerState<PasswordHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final historiesAsync = ref.watch(
      passwordHistoryListProvider(widget.passwordId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('История паролей'),
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(passwordHistoryListProvider(widget.passwordId).notifier)
                  .refresh();
            },
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: SafeArea(
        child: historiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Ошибка: $error')),
          data: (histories) => histories.isEmpty
              ? const Center(child: Text('История пуста'))
              : ListView.builder(
                  itemCount: histories.length,
                  itemBuilder: (context, index) {
                    final history = histories[index];
                    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ExpansionTile(
                        title: Text(history.name),
                        subtitle: Text(
                          '${history.action.name} • ${history.actionAt.toString()}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(history.id),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (history.description?.isNotEmpty ?? false)
                                  _buildInfoRow(
                                    'Описание',
                                    history.description!,
                                  ),
                                if (history.url?.isNotEmpty ?? false)
                                  _buildInfoRow('URL', history.url!),
                                if (history.login?.isNotEmpty ?? false)
                                  _buildInfoRow('Логин', history.login!),
                                if (history.email?.isNotEmpty ?? false)
                                  _buildInfoRow('Email', history.email!),
                                if (history.notes?.isNotEmpty ?? false)
                                  _buildInfoRow('Заметки', history.notes!),
                                if (history.categoryName?.isNotEmpty ?? false)
                                  _buildInfoRow(
                                    'Категория',
                                    history.categoryName!,
                                  ),
                                if (history.tags?.isNotEmpty ?? false)
                                  _buildInfoRow('Теги', history.tags!),
                                if (history.originalCreatedAt != null)
                                  _buildInfoRow(
                                    'Оригинальная дата создания',

                                    history.originalCreatedAt!.toString(),
                                  ),
                                if (history.originalModifiedAt != null)
                                  _buildInfoRow(
                                    'Оригинальная дата изменения',

                                    history.originalModifiedAt!.toString(),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _confirmDelete(String historyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить запись истории?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(passwordHistoryListProvider(widget.passwordId).notifier)
                  .optimisticDelete(historyId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
