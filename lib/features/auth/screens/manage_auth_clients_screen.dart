import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/providers/auth_clients_provider.dart';
import 'package:hoplixi/features/auth/screens/token_list_screen.dart';
import 'package:hoplixi/features/auth/widgets/auth_modal.dart';
import 'package:hoplixi/features/auth/widgets/auth_client_form_dialog.dart';
import 'package:hoplixi/features/auth/widgets/auth_client_card.dart';
import 'package:hoplixi/features/auth/widgets/auth_modal_new.dart';
import 'package:hoplixi/shared/widgets/button.dart';
import 'package:hoplixi/app/router/routes_path.dart';

class ManageAuthClientsScreen extends ConsumerWidget {
  const ManageAuthClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(authClientsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление клиентами авторизации'),
        actions: [
          if (asyncValue.hasValue && asyncValue.value!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(authClientsListProvider.notifier).refresh();
              },
              tooltip: 'Обновить',
            ),
          IconButton(
            onPressed: () => showNewAuthModal(
              context,
              returnPath: AppRoutes.manageCredential,
            ),
            icon: const Icon(Icons.login),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => context.push(AppRoutes.authManager),
            icon: const Icon(Icons.add),
            tooltip: 'Добавить авторизацию',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TokenListScreen(),
                ),
              ),
            },
            icon: const Icon(Icons.vpn_key),
            tooltip: 'Управление токенами',
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(context, ref, asyncValue)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCredentialDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<AuthClientConfig>> asyncValue,
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
              error.toString(),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SmoothButton(
              label: 'Повторить',
              onPressed: () {
                ref.read(authClientsListProvider.notifier).refresh();
              },
            ),
          ],
        ),
      ),
      data: (credentials) {
        if (credentials.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет учётных данных',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Добавьте учётные данные для синхронизации',
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
          onRefresh: () => ref.read(authClientsListProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: credentials.length,
            itemBuilder: (context, index) {
              final credential = credentials[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AuthClientCard(
                  credential: credential,
                  onEdit: () =>
                      _showEditCredentialDialog(context, ref, credential),
                  onDelete: () => _confirmDelete(context, ref, credential),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddCredentialDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AuthClientFormDialog(),
    );

    if (result == true && context.mounted) {
      ToastHelper.success(title: 'Учётные данные успешно добавлены');
    }
  }

  Future<void> _showEditCredentialDialog(
    BuildContext context,
    WidgetRef ref,
    AuthClientConfig credential,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AuthClientFormDialog(credential: credential),
    );

    if (result == true && context.mounted) {
      ToastHelper.success(title: 'Учётные данные успешно обновлены');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AuthClientConfig credential,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление учётных данных'),
        content: Text(
          'Вы действительно хотите удалить учётные данные для ${credential.type.name}?',
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
          .read(authClientsListProvider.notifier)
          .delete(credential.id);

      if (success && context.mounted) {
        ToastHelper.success(title: 'Учётные данные удалены');
      } else if (context.mounted) {
        ToastHelper.error(title: 'Не удалось удалить учётные данные');
      }
    }
  }
}
