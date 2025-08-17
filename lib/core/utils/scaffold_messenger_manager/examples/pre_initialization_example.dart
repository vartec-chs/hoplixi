// Пример использования ScaffoldMessengerManager до инициализации приложения

import 'package:flutter/material.dart';
import '../scaffold_messenger_manager.dart';

/// Пример демонстрирует, как сообщения сохраняются в очереди
/// до инициализации приложения и отображаются после неё
class PreInitializationExample {
  static void demonstratePreInitBehavior() {
    final manager = ScaffoldMessengerManager.instance;

    // ==================== ДО ИНИЦИАЛИЗАЦИИ ====================
    print('=== До инициализации приложения ===');
    print('Приложение инициализировано: ${manager.isAppInitialized}');
    print('Сообщений в очереди: ${manager.queueLength}');
    print('Отложенных сообщений: ${manager.pendingMessagesCount}');
    print('Общее количество сообщений: ${manager.totalMessagesCount}');

    // Добавляем сообщения до инициализации - они попадут в pending очередь
    manager.showError('Ошибка до инициализации 1');
    manager.showWarning('Предупреждение до инициализации');
    manager.showInfo('Информация до инициализации');
    manager.showSuccess('Успех до инициализации');
    manager.showError('Ошибка до инициализации 2');

    print('\n=== После добавления сообщений (до инициализации) ===');
    print('Сообщений в основной очереди: ${manager.queueLength}');
    print('Отложенных сообщений: ${manager.pendingMessagesCount}');
    print('Общее количество сообщений: ${manager.totalMessagesCount}');
    print('Есть отложенные сообщения: ${manager.hasPendingMessages}');

    // ==================== ИНИЦИАЛИЗАЦИЯ ====================
    print('\n=== Инициализация приложения ===');
    ScaffoldMessengerManager.initializeApp();

    print('Приложение инициализировано: ${manager.isAppInitialized}');
    print('Сообщений в основной очереди: ${manager.queueLength}');
    print('Отложенных сообщений: ${manager.pendingMessagesCount}');
    print('Общее количество сообщений: ${manager.totalMessagesCount}');
    print('Есть отложенные сообщения: ${manager.hasPendingMessages}');

    // ==================== ПОСЛЕ ИНИЦИАЛИЗАЦИИ ====================
    print('\n=== После инициализации ===');

    // Теперь новые сообщения идут сразу в основную очередь
    manager.showInfo('Новое сообщение после инициализации');

    print('Сообщений в основной очереди: ${manager.queueLength}');
    print('Отложенных сообщений: ${manager.pendingMessagesCount}');
    print('Общее количество сообщений: ${manager.totalMessagesCount}');
  }
}

/// Виджет для демонстрации работы с отложенными сообщениями
class PreInitializationDemoWidget extends StatefulWidget {
  const PreInitializationDemoWidget({Key? key}) : super(key: key);

  @override
  State<PreInitializationDemoWidget> createState() =>
      _PreInitializationDemoWidgetState();
}

class _PreInitializationDemoWidgetState
    extends State<PreInitializationDemoWidget> {
  final manager = ScaffoldMessengerManager.instance;

  @override
  void initState() {
    super.initState();

    // Симулируем добавление сообщений до полной инициализации
    _simulatePreInitMessages();
  }

  void _simulatePreInitMessages() {
    // Эти сообщения добавляются до того, как UI готов к их отображению
    manager.showError('Ошибка инициализации данных');
    manager.showWarning('Проверьте подключение к интернету');
    manager.showInfo('Загрузка конфигурации...');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Демо отложенных сообщений'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статистика очереди',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Приложение инициализировано: ${manager.isAppInitialized}',
                    ),
                    Text('Сообщений в очереди: ${manager.queueLength}'),
                    Text(
                      'Отложенных сообщений: ${manager.pendingMessagesCount}',
                    ),
                    Text('Общее количество: ${manager.totalMessagesCount}'),
                    Text('Есть отложенные: ${manager.hasPendingMessages}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessengerManager.initializeApp();
                setState(() {}); // Обновляем UI
              },
              child: const Text('Инициализировать приложение'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                manager.showSuccess('Новое сообщение после инициализации');
                setState(() {});
              },
              child: const Text('Добавить сообщение'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                manager.clearSnackBarQueue();
                setState(() {});
              },
              child: const Text('Очистить очередь'),
            ),
            const SizedBox(height: 16),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Как это работает:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Сообщения до инициализации сохраняются в отдельной очереди\n'
                      '2. После инициализации они перемещаются в основную очередь\n'
                      '3. Новые сообщения после инициализации идут сразу в основную очередь\n'
                      '4. Это предотвращает потерю сообщений',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
