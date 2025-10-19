/// Пример интеграции облачного экспорта при закрытии базы данных
///
/// Этот файл содержит примеры того, как интегрировать CloudExportProgressDialog
/// в различные части UI приложения для показа прогресса экспорта.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/widgets/cloud_export_progress_dialog.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/providers/cloud_export_provider.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';

/// Пример 1: Интеграция в виджет с кнопкой закрытия БД
class CloseDatabaseWithExportButton extends ConsumerWidget {
  const CloseDatabaseWithExportButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDatabaseOpen = ref.watch(isDatabaseOpenProvider);

    return Visibility(
      visible: isDatabaseOpen,
      child: IconButton(
        icon: const Icon(Icons.lock),
        tooltip: 'Закрыть базу данных',
        onPressed: () async {
          // Показываем диалог подтверждения
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Закрыть базу данных?'),
              content: const Text(
                'База данных будет экспортирована в облако перед закрытием.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            // Получаем clientKey из OAuth2
            final oauth2Service = await ref.read(oauth2AccountProvider.future);
            // TODO: Получить clientKey из oauth2Service
            const clientKey = 'temp_client_key';

            // Показываем диалог экспорта
            if (context.mounted) {
              await CloudExportProgressDialog.show(
                context,
                onComplete: () async {
                  // После успешного экспорта закрываем БД
                  await ref.read(hoplixiStoreProvider.notifier).closeDatabase();
                  ref.read(appLifecycleProvider.notifier).cleanup();
                },
                onError: () {
                  // При ошибке показываем снекбар
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ошибка экспорта. БД будет закрыта без экспорта.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              );

              // Запускаем экспорт
              ref
                  .read(cloudExportProvider.notifier)
                  .exportCurrentStorage(clientKey: clientKey);
            }
          }
        },
      ),
    );
  }
}

/// Пример 2: Функция-хелпер для экспорта и закрытия БД
Future<void> exportAndCloseDatabase({
  required BuildContext context,
  required WidgetRef ref,
  bool showConfirmation = true,
}) async {
  // Показываем подтверждение если требуется
  if (showConfirmation) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Закрыть базу данных?'),
        content: const Text(
          'База данных будет экспортирована в облако перед закрытием.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
  }

  if (!context.mounted) return;

  try {
    // Получаем clientKey
    final oauth2Service = await ref.read(oauth2AccountProvider.future);
    // TODO: Получить реальный clientKey
    const clientKey = 'temp_client_key';

    // Показываем диалог прогресса
    if (context.mounted) {
      await CloudExportProgressDialog.show(
        context,
        onComplete: () async {
          // Закрываем БД после экспорта
          await ref.read(hoplixiStoreProvider.notifier).closeDatabase();
          ref.read(appLifecycleProvider.notifier).cleanup();
        },
        onError: () async {
          // При ошибке закрываем БД без экспорта
          await ref.read(hoplixiStoreProvider.notifier).closeDatabase();
          ref.read(appLifecycleProvider.notifier).cleanup();
        },
      );

      // Запускаем экспорт
      ref
          .read(cloudExportProvider.notifier)
          .exportCurrentStorage(clientKey: clientKey);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Пример 3: Интеграция в существующий CloseDatabaseButton
/// 
/// Для интеграции в lib/shared/widgets/close_database_button.dart:
/// 
/// ```dart
/// FilledButton(
///   style: FilledButton.styleFrom(
///     backgroundColor: Colors.red.withValues(alpha: 0.8),
///   ),
///   child: const Text('Закрыть'),
///   onPressed: () async {
///     Navigator.pop(context); // Закрываем диалог подтверждения
///     
///     // Получаем clientKey из OAuth2
///     final oauth2Service = await ref.read(oauth2AccountProvider.future);
///     const clientKey = 'temp_client_key'; // TODO: получить реальный ключ
///     
///     if (context.mounted) {
///       // Показываем диалог экспорта
///       await CloudExportProgressDialog.show(
///         context,
///         onComplete: () async {
///           await ref.read(clearAllProvider.notifier).clearAll();
///           await dbNotifier.closeDatabase();
///           ref.read(appLifecycleProvider.notifier).cleanup();
///           if (context.mounted) context.go(AppRoutes.home);
///         },
///         onError: () async {
///           // Закрываем БД даже при ошибке экспорта
///           await ref.read(clearAllProvider.notifier).clearAll();
///           await dbNotifier.closeDatabase();
///           ref.read(appLifecycleProvider.notifier).cleanup();
///           if (context.mounted) context.go(AppRoutes.home);
///         },
///       );
///       
///       // Запускаем экспорт
///       ref.read(cloudExportProvider.notifier).exportCurrentStorage(
///         clientKey: clientKey,
///       );
///     }
///   },
/// ),
/// ```
