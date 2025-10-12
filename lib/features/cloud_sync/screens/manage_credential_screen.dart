import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';
import 'package:hoplixi/features/cloud_sync/providers/credential_provider.dart';
import 'package:hoplixi/features/cloud_sync/screens/token_list_screen.dart';
import 'package:hoplixi/features/cloud_sync/widgets/auth_modal.dart';
import 'package:hoplixi/features/cloud_sync/widgets/credential_form_dialog.dart';
import 'package:hoplixi/features/cloud_sync/widgets/credential_card.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/router/routes_path.dart';

class ManageCredentialScreen extends ConsumerWidget {
  const ManageCredentialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(credentialListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление учётными данными'),
        actions: [
          // if (asyncValue.hasValue && asyncValue.value!.isNotEmpty)
          //   IconButton(
          //     icon: const Icon(Icons.refresh),
          //     onPressed: () {
          //       ref.read(credentialListProvider.notifier).refresh();
          //     },
          //     tooltip: 'Обновить',
          //   ),
          IconButton(
            onPressed: () => showAuthModal(context),
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
    AsyncValue<List<CredentialApp>> asyncValue,
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
                ref.read(credentialListProvider.notifier).refresh();
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
          onRefresh: () => ref.read(credentialListProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: credentials.length,
            itemBuilder: (context, index) {
              final credential = credentials[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CredentialCard(
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
      builder: (context) => const CredentialFormDialog(),
    );

    if (result == true && context.mounted) {
      ToastHelper.success(title: 'Учётные данные успешно добавлены');
    }
  }

  Future<void> _showEditCredentialDialog(
    BuildContext context,
    WidgetRef ref,
    CredentialApp credential,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CredentialFormDialog(credential: credential),
    );

    if (result == true && context.mounted) {
      ToastHelper.success(title: 'Учётные данные успешно обновлены');
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CredentialApp credential,
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
          .read(credentialListProvider.notifier)
          .deleteCredential(credential.id);

      if (success && context.mounted) {
        ToastHelper.success(title: 'Учётные данные удалены');
      } else if (context.mounted) {
        ToastHelper.error(title: 'Не удалось удалить учётные данные');
      }
    }
  }
}
