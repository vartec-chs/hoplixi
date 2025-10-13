import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';

/// Виджет-индикатор состояния жизненного цикла приложения
/// Показывает оставшееся время до автоматического выхода
class AppLifecycleIndicator extends ConsumerWidget {
  const AppLifecycleIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTimerActive = ref.watch(isTimerActiveProvider);
    final remainingTime = ref.watch(remainingTimeFormattedProvider);

    if (!isTimerActive) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 8),
          Text(
            'Автовыход через: $remainingTime',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Простая кнопка для тестирования функций жизненного цикла
class AppLifecycleTestButtons extends ConsumerWidget {
  const AppLifecycleTestButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: () {
            ref.read(appLifecycleProvider.notifier).startTimer();
          },
          child: const Text('Запустить таймер'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            ref.read(appLifecycleProvider.notifier).stopTimer();
          },
          child: const Text('Остановить таймер'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () {
            // ref.read(appLifecycleProvider.notifier).clearAll();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Очистить все данные'),
        ),
      ],
    );
  }
}
