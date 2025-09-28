import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hoplixi/common/index.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/device_info.dart'
    as localsend;
import 'package:hoplixi/features/localsend/models/connection.dart';
import 'package:hoplixi/features/localsend/models/file_transfer.dart';
import 'package:hoplixi/features/localsend/models/message.dart';
import 'package:hoplixi/features/localsend/providers/webrtc_provider.dart';
import 'package:hoplixi/features/localsend/providers/discovery_provider.dart';
import 'package:hoplixi/features/localsend/providers/message_provider.dart';
import 'package:hoplixi/features/localsend/widgets/connection_status_widget.dart';
import 'package:hoplixi/features/localsend/widgets/file_transfer_widget.dart';
import 'package:hoplixi/features/localsend/widgets/message_input_widget.dart';
import 'package:hoplixi/features/localsend/widgets/message_list_widget.dart';

const _logTag = 'TransceiverScreen';

class TransceiverScreen extends ConsumerStatefulWidget {
  const TransceiverScreen({super.key, this.deviceInfo});

  final localsend.DeviceInfo? deviceInfo;

  @override
  ConsumerState<TransceiverScreen> createState() => _TransceiverScreenState();
}

class _TransceiverScreenState extends ConsumerState<TransceiverScreen>
    with SingleTickerProviderStateMixin {
  String? _connectionId;
  bool _isConnecting = false;
  bool _hasInitialized = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeConnection() async {
    logInfo('_initializeConnection вызван', tag: _logTag);

    if (_isConnecting) {
      logInfo('Уже идет подключение, пропускаем', tag: _logTag);
      return;
    }

    if (widget.deviceInfo == null) {
      logError(
        'widget.deviceInfo == null, не можем подключиться',
        tag: _logTag,
      );
      return;
    }

    setState(() => _isConnecting = true);
    logInfo('Состояние _isConnecting установлено в true', tag: _logTag);

    try {
      final selfDevice = ref.read(selfDeviceProvider);
      logInfo('Получили selfDevice: ${selfDevice.name}', tag: _logTag);

      final webrtcNotifier = ref.read(webrtcConnectionProvider.notifier);
      logInfo('Получили webrtcNotifier', tag: _logTag);

      logInfo(
        'Инициализация подключения к устройству',
        tag: _logTag,
        data: {
          'targetDevice': widget.deviceInfo!.name,
          'targetDeviceId': widget.deviceInfo!.id,
          'targetIp': widget.deviceInfo!.ipAddress,
          'targetPort': widget.deviceInfo!.port,
          'selfDevice': selfDevice.name,
          'selfDeviceId': selfDevice.id,
        },
      );

      // Сначала инициализируем WebRTC Service
      final webrtcService = ref.read(webrtcServiceProvider);
      logInfo('Получили webrtcService', tag: _logTag);
      await webrtcService.initialize();
      logInfo('WebRTCService инициализирован', tag: _logTag);

      final connectionId = await webrtcNotifier.connectToDevice(
        localDeviceId: selfDevice.id,
        targetDevice: widget.deviceInfo!,
      );
      logInfo(
        'connectToDevice завершен, connectionId: $connectionId',
        tag: _logTag,
      );

      if (connectionId != null) {
        setState(() => _connectionId = connectionId);
        logInfo(
          'Соединение инициализировано, ожидание подключения...',
          tag: _logTag,
        );
        ToastHelper.info(
          title: 'Подключение к ${widget.deviceInfo!.name}',
          description: 'Ожидание установки соединения...',
        );
      } else {
        logError('connectToDevice вернул null', tag: _logTag);
        ToastHelper.error(title: 'Не удалось инициировать соединение');
      }
    } catch (e) {
      logError('Ошибка инициализации соединения', error: e, tag: _logTag);
      ToastHelper.error(title: 'Ошибка подключения', description: e.toString());
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  Future<void> _pickAndSendFile() async {
    if (_connectionId == null) {
      ToastHelper.error(title: 'Нет активного соединения');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) return;

      final file = result.files.single;
      final filePath = file.path!;

      logInfo(
        'Выбран файл для отправки',
        tag: _logTag,
        data: {
          'fileName': file.name,
          'fileSize': file.size,
          'filePath': filePath,
        },
      );

      final fileTransferNotifier = ref.read(fileTransferProvider.notifier);
      final transferId = await fileTransferNotifier.sendFile(
        connectionId: _connectionId!,
        filePath: filePath,
        fileName: file.name,
        mimeType: _getMimeType(file.extension),
      );

      if (transferId != null) {
        ToastHelper.success(title: 'Передача файла началась');
        // Переключаемся на вкладку файлов
        _tabController.animateTo(1);
      } else {
        ToastHelper.error(title: 'Не удалось начать передачу файла');
      }
    } catch (e) {
      logError('Ошибка выбора и отправки файла', error: e, tag: _logTag);
      ToastHelper.error(
        title: 'Ошибка отправки файла',
        description: e.toString(),
      );
    }
  }

  Future<void> _sendMessage(String content) async {
    if (_connectionId == null || content.trim().isEmpty) return;

    try {
      final webrtcNotifier = ref.read(webrtcConnectionProvider.notifier);
      final success = await webrtcNotifier.sendMessage(
        connectionId: _connectionId!,
        content: content.trim(),
      );

      if (success) {
        // Добавляем отправленное сообщение в список
        final selfDevice = ref.read(selfDeviceProvider);
        final connection = webrtcNotifier.getConnection(_connectionId!);
        if (connection != null) {
          final messageNotifier = ref.read(messageProvider.notifier);
          messageNotifier.addMessage(
            LocalSendMessage.text(
              senderId: selfDevice.id,
              receiverId: connection.remoteDeviceId,
              content: content.trim(),
            ),
          );
        }
        ToastHelper.success(title: 'Сообщение отправлено');
      } else {
        ToastHelper.error(title: 'Не удалось отправить сообщение');
      }
    } catch (e) {
      logError('Ошибка отправки сообщения', error: e, tag: _logTag);
      ToastHelper.error(title: 'Ошибка отправки сообщения');
    }
  }

  Future<void> _acceptFile(FileTransfer transfer) async {
    try {
      final directory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath = '${directory.path}/${transfer.fileName}';

      final fileTransferNotifier = ref.read(fileTransferProvider.notifier);
      final success = await fileTransferNotifier.acceptFile(
        transfer.id,
        savePath,
      );

      if (success) {
        ToastHelper.success(title: 'Прием файла начался');
      } else {
        ToastHelper.error(title: 'Не удалось принять файл');
      }
    } catch (e) {
      logError('Ошибка принятия файла', error: e, tag: _logTag);
      ToastHelper.error(title: 'Ошибка принятия файла');
    }
  }

  Future<void> _rejectFile(FileTransfer transfer) async {
    try {
      final fileTransferNotifier = ref.read(fileTransferProvider.notifier);
      final success = await fileTransferNotifier.rejectFile(transfer.id);

      if (success) {
        ToastHelper.info(title: 'Файл отклонен');
      }
    } catch (e) {
      logError('Ошибка отклонения файла', error: e, tag: _logTag);
      ToastHelper.error(title: 'Ошибка отклонения файла');
    }
  }

  Future<void> _disconnectDevice() async {
    if (_connectionId == null) return;

    try {
      final webrtcNotifier = ref.read(webrtcConnectionProvider.notifier);
      await webrtcNotifier.closeConnection(_connectionId!);

      setState(() => _connectionId = null);

      // Очищаем сообщения при отключении
      ref.read(messageProvider.notifier).clearMessages();

      ToastHelper.info(title: 'Соединение разорвано');
    } catch (e) {
      logError('Ошибка разрыва соединения', error: e, tag: _logTag);
      ToastHelper.error(title: 'Ошибка разрыва соединения');
    }
  }

  String? _getMimeType(String? extension) {
    if (extension == null) return null;

    final mimeTypes = {
      '.txt': 'text/plain',
      '.pdf': 'application/pdf',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.mp4': 'video/mp4',
      '.mp3': 'audio/mpeg',
      '.zip': 'application/zip',
      '.rar': 'application/x-rar-compressed',
      '.docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      '.xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };

    return mimeTypes[extension.toLowerCase()];
  }

  @override
  Widget build(BuildContext context) {
    final transfersAsync = ref.watch(fileTransferProvider);
    final messagesAsync = ref.watch(messageProvider);
    final currentConnection = ref.watch(currentConnectionProvider);

    // Автоинициализация подключения при первой загрузке
    if (!_hasInitialized && widget.deviceInfo != null) {
      logInfo(
        'Автоинициализация подключения',
        tag: _logTag,
        data: {
          'deviceInfo': widget.deviceInfo!.name,
          'hasInitialized': _hasInitialized,
        },
      );
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        logInfo('addPostFrameCallback выполняется', tag: _logTag);
        _initializeConnection();
      });
    } else {
      logDebug(
        'Автоинициализация пропущена',
        tag: _logTag,
        data: {
          'hasInitialized': _hasInitialized,
          'hasDeviceInfo': widget.deviceInfo != null,
        },
      );
    }

    // Отслеживание изменений соединения
    ref.listen(currentConnectionProvider, (previous, next) {
      if (_connectionId != null && next?.connectionId == _connectionId) {
        switch (next?.state) {
          case WebRTCConnectionState.connected:
            ToastHelper.success(
              title: 'Подключено к ${widget.deviceInfo!.name}',
              description: 'Теперь можно отправлять файлы и сообщения',
            );
            break;
          case WebRTCConnectionState.failed:
            ToastHelper.error(
              title: 'Не удалось подключиться',
              description: 'Проверьте сетевое подключение',
            );
            break;
          case WebRTCConnectionState.disconnected:
          case WebRTCConnectionState.disconnecting:
            if (previous?.state == WebRTCConnectionState.connected) {
              ToastHelper.info(title: 'Соединение разорвано');
            }
            break;
          default:
            break;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceInfo?.name ?? 'LocalSend'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Закрываем соединение при выходе
            if (_connectionId != null) {
              await _disconnectDevice();
            }
            if (context.mounted) {
              context.pop();
            }
          },
        ),
        actions: [
          if (_connectionId != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _disconnectDevice,
              tooltip: 'Разорвать соединение',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isConnecting ? null : _initializeConnection,
            tooltip: 'Переподключить',
          ),
        ],
        bottom: widget.deviceInfo == null
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.message), text: 'Сообщения'),
                  Tab(icon: Icon(Icons.folder), text: 'Файлы'),
                ],
              ),
      ),
      body: SafeArea(
        child: widget.deviceInfo == null
            ? const Center(child: Text('Нет информации об устройстве'))
            : Column(
                children: [
                  // Статус соединения
                  ConnectionStatusWidget(
                    deviceInfo: widget.deviceInfo!,
                    isConnecting: _isConnecting,
                    connection: currentConnection,
                  ),

                  // Содержимое вкладок
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Вкладка сообщений
                        Column(
                          children: [
                            Expanded(
                              child: messagesAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (error, stack) =>
                                    Center(child: Text('Ошибка: $error')),
                                data: (messages) {
                                  final selfDevice = ref.read(
                                    selfDeviceProvider,
                                  );
                                  return MessageListWidget(
                                    messages: messages,
                                    currentDeviceId: selfDevice.id,
                                  );
                                },
                              ),
                            ),
                            // Поле ввода сообщений
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: MessageInputWidget(
                                enabled:
                                    currentConnection?.state ==
                                    WebRTCConnectionState.connected,
                                onSendMessage: _sendMessage,
                              ),
                            ),
                          ],
                        ),

                        // Вкладка файлов
                        Column(
                          children: [
                            // Активные передачи файлов
                            Expanded(
                              child: transfersAsync.when(
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (error, stack) =>
                                    Center(child: Text('Ошибка: $error')),
                                data: (transfers) => transfers.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.folder_outlined,
                                              size: 64,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Нет активных передач',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                            Text(
                                              'Отправьте файл для начала передачи',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: transfers.length,
                                        itemBuilder: (context, index) {
                                          final transfer = transfers[index];
                                          return FileTransferWidget(
                                            transfer: transfer,
                                            onAccept: () =>
                                                _acceptFile(transfer),
                                            onReject: () =>
                                                _rejectFile(transfer),
                                            onCancel: () => ref
                                                .read(
                                                  fileTransferProvider.notifier,
                                                )
                                                .cancelTransfer(transfer.id),
                                          );
                                        },
                                      ),
                              ),
                            ),

                            // Кнопка отправки файла
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: SmoothButton(
                                type: SmoothButtonType.filled,
                                size: SmoothButtonSize.large,
                                label: 'Отправить файл',
                                onPressed:
                                    currentConnection?.state ==
                                        WebRTCConnectionState.connected
                                    ? _pickAndSendFile
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
