import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/providers/app_lifecycle_provider.dart';

/// Глобальный оверлей, отображающийся при закрытии базы данных
class DatabaseClosedOverlay extends ConsumerStatefulWidget {
  const DatabaseClosedOverlay({super.key});

  @override
  ConsumerState<DatabaseClosedOverlay> createState() =>
      _DatabaseClosedOverlayState();
}

class _DatabaseClosedOverlayState extends ConsumerState<DatabaseClosedOverlay> {
  @override
  void initState() {
    super.initState();
  }

  void _showOverlay() {
    // if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('База данных закрыта'),
          content: const Text('Данные были очищены для безопасности.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (mounted && ref.exists(dataClearedProvider)) {
      ref.listen(dataClearedProvider, (previous, next) {
        if (next && previous != next) {
          // Если данные были очищены, показываем оверлей
          Future.microtask(
            () => {
              Future.delayed(const Duration(milliseconds: 200)),
              if (mounted) {_showOverlay()},
            },
          );
        }
      });
    }
    // final dataCleared = ref.watch(dataClearedProvider);

    // if (!dataCleared) {
    // return const SizedBox.shrink();
    // }

    return Material(
      child: Positioned.fill(
        child: GestureDetector(
          onTap: () {
            logInfo(
              'Пользователь нажал на оверлей закрытия БД',
              tag: 'DatabaseClosedOverlay',
            );
            // Сбрасываем флаг очистки данных при нажатии
            ref.read(appLifecycleProvider.notifier).resetDataClearedFlag();
          },
          child: Container(
            color: Colors.black.withOpacity(
              0.8,
            ), // Более темный фон для большей видимости
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'База данных закрыта',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Данные были очищены для безопасности.\nНажмите на экран для продолжения работы.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Касание в любом месте',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
