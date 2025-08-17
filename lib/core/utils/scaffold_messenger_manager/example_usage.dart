import 'package:flutter/material.dart';
import 'scaffold_messenger_manager.dart';

/// Пример использования ScaffoldMessengerManager с полоской прогресса
class SnackBarExampleScreen extends StatelessWidget {
  const SnackBarExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SnackBar с полоской времени')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                ScaffoldMessengerManager.instance.showError(
                  'Ошибка загрузки данных!',
                  duration: const Duration(seconds: 5),
                  showProgressBar: true, // Включена полоска прогресса
                );
              },
              child: const Text('Показать ошибку (с полоской)'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessengerManager.instance.showSuccess(
                  'Данные успешно сохранены!',
                  duration: const Duration(seconds: 3),
                  showProgressBar: false, // Отключена полоска прогресса
                );
              },
              child: const Text('Показать успех (без полоски)'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessengerManager.instance.showWarning(
                  'Внимание: низкий заряд батареи',
                  duration: const Duration(seconds: 7),
                  showProgressBar: true,
                  showCopyButton: true,
                );
              },
              child: const Text('Показать предупреждение (длинное)'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessengerManager.instance.showInfo(
                  'Обновление доступно в магазине приложений',
                  duration: const Duration(seconds: 4),
                  actionLabel: 'Обновить',
                  onActionPressed: () {
                    // Действие при нажатии на кнопку
                    ScaffoldMessengerManager.instance.showSuccess(
                      'Обновление началось!',
                      duration: const Duration(seconds: 2),
                    );
                  },
                );
              },
              child: const Text('Показать информацию (с действием)'),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessengerManager.instance.showInfo(
                  'Попробуйте навести курсор на это сообщение для остановки таймера!',
                  duration: const Duration(
                    seconds: 10,
                  ), // Долгая длительность для демо
                  showProgressBar: true,
                );
              },
              child: const Text('Демо остановки таймера (10 сек)'),
            ),
            const SizedBox(height: 32),

            const Text(
              'Полоска прогресса показывает оставшееся время до автоматического закрытия SnackBar.\n\n'
              '🖱️ Наведите курсор на SnackBar, чтобы остановить таймер!\n'
              'При наведении полоска прогресса станет ярче и остановится.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
