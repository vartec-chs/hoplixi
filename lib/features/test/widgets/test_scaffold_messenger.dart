import 'package:flutter/material.dart';
import 'package:hoplixi/core/utils/scaffold_messenger_manager/scaffold_messenger_manager.dart';

class TestScaffoldMessengerScreen extends StatefulWidget {
  const TestScaffoldMessengerScreen({super.key});

  @override
  State<TestScaffoldMessengerScreen> createState() =>
      _TestScaffoldMessengerScreenState();
}

class _TestScaffoldMessengerScreenState
    extends State<TestScaffoldMessengerScreen> {
  final ScaffoldMessengerManager _messenger = ScaffoldMessengerManager.instance;
  bool _enableBlur = false;
  bool _showCopyButton = true;
  Duration _duration = const Duration(seconds: 4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест ScaffoldMessengerManager'),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showQueueInfo(),
            icon: const Icon(Icons.info_outline),
            tooltip: 'Информация о очереди',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusSection(),
            const SizedBox(height: 20),
            _buildSettingsSection(),
            const SizedBox(height: 20),
            _buildSnackBarSection(),
            const SizedBox(height: 20),
            _buildBannerSection(),
            const SizedBox(height: 20),
            _buildAnimationSection(),
            const SizedBox(height: 20),
            _buildControlSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статус менеджера',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              'Приложение инициализировано',
              _messenger.isAppInitialized,
            ),
            _buildStatusRow('Очередь пуста', _messenger.isQueueEmpty),
            _buildStatusRow(
              'Есть отложенные сообщения',
              _messenger.hasPendingMessages,
            ),
            const SizedBox(height: 8),
            Text('Сообщений в очереди: ${_messenger.queueLength}'),
            Text('Отложенных сообщений: ${_messenger.pendingMessagesCount}'),
            Text('Всего сообщений: ${_messenger.totalMessagesCount}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Настройки',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Размытие фона'),
              value: _enableBlur,
              onChanged: (value) => setState(() => _enableBlur = value),
            ),
            SwitchListTile(
              title: const Text('Кнопка копирования'),
              value: _showCopyButton,
              onChanged: (value) => setState(() => _showCopyButton = value),
            ),
            ListTile(
              title: const Text('Длительность'),
              subtitle: Text('${_duration.inSeconds} секунд'),
              trailing: DropdownButton<Duration>(
                value: _duration,
                items: const [
                  DropdownMenuItem(
                    value: Duration(seconds: 2),
                    child: Text('2 сек'),
                  ),
                  DropdownMenuItem(
                    value: Duration(seconds: 4),
                    child: Text('4 сек'),
                  ),
                  DropdownMenuItem(
                    value: Duration(seconds: 6),
                    child: Text('6 сек'),
                  ),
                  DropdownMenuItem(
                    value: Duration(seconds: 10),
                    child: Text('10 сек'),
                  ),
                ],
                onChanged: (value) => setState(() => _duration = value!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnackBarSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тест SnackBar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showErrorSnackBar(),
                  icon: const Icon(Icons.error),
                  label: const Text('Ошибка'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showWarningSnackBar(),
                  icon: const Icon(Icons.warning),
                  label: const Text('Предупреждение'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showInfoSnackBar(),
                  icon: const Icon(Icons.info),
                  label: const Text('Информация'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSuccessSnackBar(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Успех'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showMultipleSnackBars(),
                    child: const Text('Несколько сообщений'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showLongMessage(),
                    child: const Text('Длинное сообщение'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тест MaterialBanner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showErrorBanner(),
                  icon: const Icon(Icons.error),
                  label: const Text('Ошибка'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showWarningBanner(),
                  icon: const Icon(Icons.warning),
                  label: const Text('Предупреждение'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showInfoBanner(),
                  icon: const Icon(Icons.info),
                  label: const Text('Информация'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSuccessBanner(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Успех'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Тест анимаций',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _messenger.disableAnimations();
                    _showTestMessage('Анимации отключены');
                  },
                  child: const Text('Без анимации'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _messenger.setFastAnimations();
                    _showTestMessage('Быстрые анимации');
                  },
                  child: const Text('Быстрые'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _messenger.enableAnimations();
                    _showTestMessage('Обычные анимации');
                  },
                  child: const Text('Обычные'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _messenger.setSlowAnimations();
                    _showTestMessage('Медленные анимации');
                  },
                  child: const Text('Медленные'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _messenger.setBounceAnimations();
                    _showTestMessage('Bounce анимации');
                  },
                  child: const Text('Bounce'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Управление',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _messenger.hideCurrentSnackBar(),
                    child: const Text('Скрыть SnackBar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _messenger.hideCurrentBanner(),
                    child: const Text('Скрыть Banner'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _messenger.clearSnackBarQueue(),
                    child: const Text('Очистить очередь'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Обновить статус'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar() {
    _messenger.showError(
      'Произошла ошибка при выполнении операции',
      duration: _duration,
      actionLabel: 'Повторить',
      onActionPressed: () => _showSuccessSnackBar(),
      showCopyButton: _showCopyButton,
      enableBlur: _enableBlur,
    );
  }

  void _showWarningSnackBar() {
    _messenger.showWarning(
      'Предупреждение: проверьте введенные данные',
      duration: _duration,
      actionLabel: 'Понятно',
      enableBlur: _enableBlur,
    );
  }

  void _showInfoSnackBar() {
    _messenger.showInfo(
      'Информация: операция выполнена успешно',
      duration: _duration,
      actionLabel: 'ОК',
      enableBlur: _enableBlur,
    );
  }

  void _showSuccessSnackBar() {
    _messenger.showSuccess(
      'Успех! Данные сохранены',
      duration: _duration,
      enableBlur: _enableBlur,
    );
  }

  void _showMultipleSnackBars() {
    _messenger.showError('Первое сообщение');
    _messenger.showWarning('Второе сообщение');
    _messenger.showInfo('Третье сообщение');
    _messenger.showSuccess('Четвертое сообщение');
  }

  void _showLongMessage() {
    _messenger.showInfo(
      'Это очень длинное сообщение, которое должно корректно отображаться в SnackBar даже при большом количестве текста. Проверяем перенос строк и адаптивность интерфейса.',
      duration: const Duration(seconds: 6),
      enableBlur: _enableBlur,
    );
  }

  void _showTestMessage(String message) {
    _messenger.showInfo(message, duration: const Duration(seconds: 2));
  }

  void _showErrorBanner() {
    _messenger.showErrorBanner(
      'Критическая ошибка системы',
      actions: [
        TextButton(
          onPressed: () => _messenger.hideCurrentBanner(),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () {
            _messenger.hideCurrentBanner();
            _showSuccessSnackBar();
          },
          child: const Text('Исправить'),
        ),
      ],
    );
  }

  void _showWarningBanner() {
    _messenger.showWarningBanner(
      'Требуется обновление приложения',
      actions: [
        TextButton(
          onPressed: () => _messenger.hideCurrentBanner(),
          child: const Text('Позже'),
        ),
        TextButton(
          onPressed: () {
            _messenger.hideCurrentBanner();
            _showInfoSnackBar();
          },
          child: const Text('Обновить'),
        ),
      ],
    );
  }

  void _showInfoBanner() {
    _messenger.showInfoBanner(
      'Новая функция доступна в приложении',
      actions: [
        TextButton(
          onPressed: () => _messenger.hideCurrentBanner(),
          child: const Text('Понятно'),
        ),
      ],
    );
  }

  void _showSuccessBanner() {
    _messenger.showSuccessBanner(
      'Операция выполнена успешно',
      actions: [
        TextButton(
          onPressed: () => _messenger.hideCurrentBanner(),
          child: const Text('ОК'),
        ),
      ],
    );
  }

  void _showQueueInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о очереди'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Приложение инициализировано: ${_messenger.isAppInitialized}'),
            Text('Сообщений в очереди: ${_messenger.queueLength}'),
            Text('Отложенных сообщений: ${_messenger.pendingMessagesCount}'),
            Text('Всего сообщений: ${_messenger.totalMessagesCount}'),
            Text('Очередь пуста: ${_messenger.isQueueEmpty}'),
            Text('Есть отложенные: ${_messenger.hasPendingMessages}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
