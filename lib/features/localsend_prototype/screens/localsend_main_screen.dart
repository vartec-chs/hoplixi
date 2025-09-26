import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/localsend_prototype/controllers/index.dart';
import 'package:hoplixi/features/localsend_prototype/providers/index.dart';
import 'devices_tab.dart';
import 'transfers_tab.dart';
import 'messages_tab.dart';

/// Основной экран LocalSend с вкладками для устройств, передач и настроек
class LocalSendMainScreen extends ConsumerStatefulWidget {
  const LocalSendMainScreen({super.key});

  @override
  ConsumerState<LocalSendMainScreen> createState() =>
      _LocalSendMainScreenState();
}

class _LocalSendMainScreenState extends ConsumerState<LocalSendMainScreen>
    with TickerProviderStateMixin {
  static const String _logTag = 'LocalSendMainScreen';
  late TabController _tabController;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeLocalSend();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _disposeLocalSend();
    super.dispose();
  }

  /// Очищает все данные LocalSend
  Future<void> _disposeLocalSend() async {
    try {
      logInfo('Очистка данных LocalSend при уходе с экрана', tag: _logTag);
      final controller = ref.read(localSendControllerProvider);
      await controller.disposeAll();
    } catch (e) {
      logError('Ошибка очистки LocalSend', error: e, tag: _logTag);
    }
  }

  /// Обработка нажатия кнопки "Назад"
  Future<bool> _onWillPop() async {
    try {
      logInfo('Обработка кнопки назад - очистка LocalSend', tag: _logTag);
      await _disposeLocalSend();
      return true; // Разрешаем выход
    } catch (e) {
      logError('Ошибка при обработке кнопки назад', error: e, tag: _logTag);
      return true; // Всё равно выходим
    }
  }

  Future<void> _initializeLocalSend() async {
    try {
      final controller = ref.read(localSendControllerProvider);
      if (!controller.isInitialized) {
        await controller.initialize();
        // Добавляем тестовые устройства для демонстрации
        // controller.addTestDevices();
      }
    } catch (e) {
      logError('Ошибка инициализации LocalSend', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка инициализации',
        description: 'Не удалось запустить LocalSend',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('LocalSend'), centerTitle: true),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Инициализация LocalSend...'),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('LocalSend'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.devices), text: 'Устройства'),
              Tab(icon: Icon(Icons.swap_horiz), text: 'Передачи'),
              Tab(icon: Icon(Icons.chat), text: 'Сообщения'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshDiscovery,
              tooltip: 'Обновить поиск устройств',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_test_devices',
                  child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text('Добавить тестовые устройства'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_history',
                  child: ListTile(
                    leading: Icon(Icons.clear_all),
                    title: Text('Очистить историю'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'dispose_all',
                  child: ListTile(
                    leading: Icon(Icons.cleaning_services),
                    title: Text('Очистить все данные'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                context.pop();
              }
            },
            tooltip: 'Назад',
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [DevicesTab(), TransfersTab(), MessagesTab()],
        ),
      ),
    );
  }

  Future<void> _refreshDiscovery() async {
    try {
      logInfo('Обновление поиска устройств', tag: _logTag);
      final controller = ref.read(localSendControllerProvider);
      if (!controller.isInitialized) {
        ToastHelper.error(
          title: 'Ошибка',
          description: 'LocalSend не инициализирован',
        );
        return;
      }
      await controller.refreshDeviceDiscovery();
      ToastHelper.info(
        title: 'Поиск устройств',
        description: 'Обновление списка устройств...',
      );
    } catch (e) {
      logError('Ошибка обновления поиска', error: e, tag: _logTag);
    }
  }

  void _handleMenuAction(String action) {
    final controller = ref.read(localSendControllerProvider);

    switch (action) {
      case 'add_test_devices':
        controller.addTestDevices();
        ToastHelper.success(
          title: 'Тестовые устройства',
          description: 'Добавлены тестовые устройства',
        );
        break;
      case 'clear_history':
        ref.read(messageHistoryProvider.notifier).clearHistory();
        ref.read(fileTransfersProvider.notifier).clearTransfers();
        ToastHelper.info(
          title: 'История очищена',
          description: 'Сообщения и передачи удалены',
        );
        break;
      case 'dispose_all':
        _disposeAllData();
        break;
    }
  }

  /// Полная очистка всех данных LocalSend по запросу пользователя
  Future<void> _disposeAllData() async {
    try {
      logInfo('Полная очистка всех данных LocalSend по запросу', tag: _logTag);
      final controller = ref.read(localSendControllerProvider);
      await controller.disposeAll();
      ToastHelper.success(
        title: 'Данные очищены',
        description: 'Все данные LocalSend удалены',
      );
    } catch (e) {
      logError('Ошибка очистки всех данных', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка очистки',
        description: 'Не удалось очистить все данные',
      );
    }
  }
}
