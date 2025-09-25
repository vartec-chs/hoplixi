import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_providers.dart';
import 'package:hoplixi/hoplixi_store/providers.dart';
import 'package:hoplixi/router/routes_path.dart';

class CloseDatabaseButton extends ConsumerWidget {
  final BoxConstraints? constraints;
  final bool useListTile;

  const CloseDatabaseButton({
    super.key,
    this.constraints = const BoxConstraints(maxHeight: 40, maxWidth: 40),
    this.useListTile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDatabaseOpen = ref.watch(isDatabaseOpenProvider);
    final dbNotifier = ref.read(hoplixiStoreProvider.notifier);
    final clearState = ref.watch(clearAllProvider);

    void _showConfirmationDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Подтверждение'),
          content: const Text('Вы уверены, что хотите закрыть базу данных?'),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.pop(context),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.8),
              ),
              child: const Text('Закрыть'),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(clearAllProvider.notifier).clearAll();
                await dbNotifier.closeDatabase();
                if (context.mounted) context.go(AppRoutes.home);
              },
            ),
          ],
        ),
      );
    }

    return Visibility(
      visible: isDatabaseOpen,
      child: clearState.isLoading
          ? const CircularProgressIndicator()
          : useListTile
          ? ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Закрыть базу данных'),
              onTap: _showConfirmationDialog,
            )
          : IconButton(
              padding: const EdgeInsets.all(6),
              tooltip: 'Закрыть бызу данных',
              constraints: constraints,
              icon: const Icon(Icons.lock, size: 20),
              onPressed: _showConfirmationDialog,
            ),
    );
  }
}
