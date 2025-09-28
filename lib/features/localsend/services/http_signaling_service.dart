import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/connection.dart';
import 'package:uuid/uuid.dart';

/// Сервис для HTTP сигналинга между устройствами
class HttpSignalingService {
  static const String _logTag = 'HttpSignalingService';
  static const int _defaultPort = 8080;
  static const Duration _messageTimeout = Duration(seconds: 30);

  HttpServer? _server;
  final Map<String, List<SignalingMessage>> _pendingMessages = {};
  final Map<String, DateTime> _messageTimestamps = {};
  final StreamController<SignalingMessage> _messageController =
      StreamController<SignalingMessage>.broadcast();

  int? _port;
  bool _isRunning = false;
  Timer? _cleanupTimer;

  /// Поток входящих сообщений сигналинга
  Stream<SignalingMessage> get incomingMessages => _messageController.stream;

  /// Текущий порт сервера
  int? get port => _port;

  /// Проверяет, запущен ли сервер
  bool get isRunning => _isRunning;

  /// Запускает HTTP сервер для сигналинга
  Future<void> startServer({int? port}) async {
    if (_isRunning) {
      logWarning('HTTP сигналинг сервер уже запущен', tag: _logTag);
      return;
    }

    try {
      final serverPort = port ?? _defaultPort;

      // Пытаемся найти свободный порт
      _server = await _bindToAvailablePort(serverPort);
      _port = _server!.port;
      _isRunning = true;

      logInfo('HTTP сигналинг сервер запущен на порту $_port', tag: _logTag);

      // Настраиваем обработку запросов
      _server!.listen(_handleRequest);

      // Запускаем таймер для очистки старых сообщений
      _startCleanupTimer();
    } catch (e) {
      logError('Ошибка запуска HTTP сигналинг сервера', error: e, tag: _logTag);
      _isRunning = false;
      rethrow;
    }
  }

  /// Останавливает HTTP сервер
  Future<void> stopServer() async {
    if (!_isRunning || _server == null) return;

    try {
      _cleanupTimer?.cancel();
      await _server!.close(force: true);
      _server = null;
      _isRunning = false;
      _port = null;
      _pendingMessages.clear();
      _messageTimestamps.clear();

      logInfo('HTTP сигналинг сервер остановлен', tag: _logTag);
    } catch (e) {
      logError(
        'Ошибка остановки HTTP сигналинг сервера',
        error: e,
        tag: _logTag,
      );
    }
  }

  /// Отправляет сообщение сигналинга на удаленное устройство
  Future<bool> sendMessage(
    String targetDeviceId,
    String targetIp,
    int targetPort,
    SignalingMessage message,
  ) async {
    try {
      // Проверяем IP адрес на валидность
      if (!_isValidLocalIp(targetIp)) {
        logWarning(
          'Подозрительный IP адрес для локальной сети',
          tag: _logTag,
          data: {
            'targetIp': targetIp,
            'isPrivateRange': _isPrivateIpRange(targetIp),
            'isLoopback': targetIp.startsWith('127.'),
            'isLinkLocal': targetIp.startsWith('169.254.'),
          },
        );
      }

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(
        seconds: 5,
      ); // Уменьшили таймаут
      final uri = Uri.parse('http://$targetIp:$targetPort/signaling');

      logInfo(
        'Отправка сигналинг сообщения',
        tag: _logTag,
        data: {
          'type': message.type.name,
          'from': message.fromDeviceId,
          'to': targetDeviceId,
          'target': '$targetIp:$targetPort',
          'uri': uri.toString(),
          'isValidLocalIp': _isValidLocalIp(targetIp),
        },
      );

      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final messageJson = json.encode(message.toJson());
      logDebug('Отправляем JSON: $messageJson', tag: _logTag);
      request.write(messageJson);

      final response = await request.close();
      final responseBody = await utf8.decoder.bind(response).join();
      final success = response.statusCode == 200;

      logInfo(
        'Результат отправки сигналинг сообщения',
        tag: _logTag,
        data: {
          'success': success,
          'statusCode': response.statusCode,
          'responseBody': responseBody,
          'type': message.type.name,
          'to': targetDeviceId,
        },
      );

      if (!success) {
        logError(
          'Ошибка отправки сигналинг сообщения: ${response.statusCode} ',
          tag: _logTag,
          data: {'responseBody': responseBody},
        );
      }

      httpClient.close();
      return success;
    } catch (e, stackTrace) {
      // Дополнительная диагностика для разных типов ошибок
      String errorContext = 'Unknown error';
      if (e is SocketException) {
        errorContext = 'Network connectivity issue: ${e.message}';
      } else if (e is TimeoutException) {
        errorContext = 'Connection timeout - device may be unreachable';
      } else if (e is HttpException) {
        errorContext = 'HTTP protocol error: ${e.message}';
      }

      logError(
        'Исключение при отправке сигналинг сообщения: $errorContext',
        error: e,
        stackTrace: stackTrace,
        tag: _logTag,
        data: {
          'target': '$targetIp:$targetPort',
          'targetDevice': targetDeviceId,
          'messageType': message.type.name,
          'errorType': e.runtimeType.toString(),
          'isValidLocalIp': _isValidLocalIp(targetIp),
          'suggestedAction': _getSuggestedAction(targetIp, e),
        },
      );
      return false;
    }
  }

  /// Создает сообщение offer для WebRTC
  SignalingMessage createOfferMessage({
    required String fromDeviceId,
    required String toDeviceId,
    required Map<String, dynamic> sdpOffer,
  }) {
    return SignalingMessage(
      type: SignalingMessageType.offer,
      fromDeviceId: fromDeviceId,
      toDeviceId: toDeviceId,
      data: sdpOffer,
      timestamp: DateTime.now(),
      messageId: const Uuid().v4(),
    );
  }

  /// Создает сообщение answer для WebRTC
  SignalingMessage createAnswerMessage({
    required String fromDeviceId,
    required String toDeviceId,
    required Map<String, dynamic> sdpAnswer,
  }) {
    return SignalingMessage(
      type: SignalingMessageType.answer,
      fromDeviceId: fromDeviceId,
      toDeviceId: toDeviceId,
      data: sdpAnswer,
      timestamp: DateTime.now(),
      messageId: const Uuid().v4(),
    );
  }

  /// Создает сообщение ICE candidate
  SignalingMessage createIceCandidateMessage({
    required String fromDeviceId,
    required String toDeviceId,
    required Map<String, dynamic> iceCandidate,
  }) {
    return SignalingMessage(
      type: SignalingMessageType.iceCandidate,
      fromDeviceId: fromDeviceId,
      toDeviceId: toDeviceId,
      data: iceCandidate,
      timestamp: DateTime.now(),
      messageId: const Uuid().v4(),
    );
  }

  /// Получает ожидающие сообщения для устройства
  List<SignalingMessage> getPendingMessages(String deviceId) {
    final messages = _pendingMessages[deviceId] ?? [];
    _pendingMessages[deviceId] = []; // Очищаем после получения
    return messages;
  }

  /// Освобождает ресурсы
  Future<void> dispose() async {
    await stopServer();
    await _messageController.close();
  }

  /// Пытается привязать сервер к доступному порту
  Future<HttpServer> _bindToAvailablePort(int startPort) async {
    for (int port = startPort; port <= startPort + 10; port++) {
      try {
        return await HttpServer.bind(InternetAddress.anyIPv4, port);
      } catch (e) {
        if (port == startPort + 10) {
          throw Exception(
            'Не удалось найти свободный порт в диапазоне $startPort-${startPort + 10}',
          );
        }
        // Пробуем следующий порт
        continue;
      }
    }
    throw Exception('Не удалось запустить сервер');
  }

  /// Обрабатывает входящие HTTP запросы
  Future<void> _handleRequest(HttpRequest request) async {
    logDebug(
      'Получен HTTP запрос',
      tag: _logTag,
      data: {
        'method': request.method,
        'path': request.uri.path,
        'remote': request.connectionInfo?.remoteAddress.address,
      },
    );

    try {
      // Устанавливаем CORS заголовки
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers.set(
        'Access-Control-Allow-Methods',
        'GET, POST, OPTIONS',
      );
      request.response.headers.set(
        'Access-Control-Allow-Headers',
        'Content-Type',
      );

      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }

      if (request.method == 'POST' && request.uri.path == '/signaling') {
        await _handleSignalingRequest(request);
      } else if (request.method == 'GET' && request.uri.path == '/messages') {
        await _handleMessagesRequest(request);
      } else if (request.method == 'GET' && request.uri.path == '/health') {
        await _handleHealthRequest(request);
      } else {
        logWarning(
          'Неизвестный HTTP запрос',
          tag: _logTag,
          data: {'method': request.method, 'path': request.uri.path},
        );
        request.response.statusCode = 404;
        request.response.write('Not Found');
        await request.response.close();
      }
    } catch (e) {
      logError('Ошибка обработки HTTP запроса', error: e, tag: _logTag);
      try {
        request.response.statusCode = 500;
        request.response.write('Internal Server Error');
        await request.response.close();
      } catch (_) {}
    }
  }

  /// Обрабатывает запрос сигналинга
  Future<void> _handleSignalingRequest(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final messageJson = json.decode(body) as Map<String, dynamic>;
      final message = SignalingMessage.fromJson(messageJson);

      logInfo(
        'Получено сигналинг сообщение',
        tag: _logTag,
        data: {
          'type': message.type.name,
          'from': message.fromDeviceId,
          'to': message.toDeviceId,
        },
      );

      // Сохраняем сообщение для получателя
      _addPendingMessage(message.toDeviceId, message);

      // Уведомляем слушателей
      _messageController.add(message);

      request.response.statusCode = 200;
      request.response.write('OK');
      await request.response.close();
    } catch (e) {
      logError('Ошибка обработки сигналинг запроса', error: e, tag: _logTag);
      request.response.statusCode = 400;
      request.response.write('Bad Request');
      await request.response.close();
    }
  }

  /// Обрабатывает запрос на получение сообщений
  Future<void> _handleMessagesRequest(HttpRequest request) async {
    try {
      final deviceId = request.uri.queryParameters['deviceId'];
      if (deviceId == null) {
        request.response.statusCode = 400;
        request.response.write('Missing deviceId parameter');
        await request.response.close();
        return;
      }

      final messages = getPendingMessages(deviceId);
      final messagesJson = messages.map((m) => m.toJson()).toList();

      request.response.headers.set('Content-Type', 'application/json');
      request.response.statusCode = 200;
      request.response.write(json.encode(messagesJson));
      await request.response.close();
    } catch (e) {
      logError('Ошибка обработки запроса сообщений', error: e, tag: _logTag);
      request.response.statusCode = 500;
      request.response.write('Internal Server Error');
      await request.response.close();
    }
  }

  /// Обрабатывает health check запрос
  Future<void> _handleHealthRequest(HttpRequest request) async {
    request.response.statusCode = 200;
    request.response.write('OK');
    await request.response.close();
  }

  /// Добавляет сообщение в очередь ожидания
  void _addPendingMessage(String deviceId, SignalingMessage message) {
    if (!_pendingMessages.containsKey(deviceId)) {
      _pendingMessages[deviceId] = [];
    }
    _pendingMessages[deviceId]!.add(message);
    _messageTimestamps[message.messageId] = message.timestamp;
  }

  /// Запускает таймер для очистки старых сообщений
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupOldMessages();
    });
  }

  /// Очищает старые сообщения
  void _cleanupOldMessages() {
    final now = DateTime.now();
    final expiredMessageIds = <String>[];

    _messageTimestamps.forEach((messageId, timestamp) {
      if (now.difference(timestamp) > _messageTimeout) {
        expiredMessageIds.add(messageId);
      }
    });

    // Удаляем истекшие сообщения
    for (final messageId in expiredMessageIds) {
      _messageTimestamps.remove(messageId);

      _pendingMessages.forEach((deviceId, messages) {
        messages.removeWhere((message) => message.messageId == messageId);
      });
    }

    if (expiredMessageIds.isNotEmpty) {
      logDebug(
        'Очищено ${expiredMessageIds.length} истекших сообщений',
        tag: _logTag,
      );
    }
  }

  /// Проверяет, является ли IP адрес валидным для локальной сети
  bool _isValidLocalIp(String ip) {
    // Проверяем базовый формат IP
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) return false;

    // Проверяем, что это приватный IP диапазон
    return _isPrivateIpRange(ip) ||
        ip.startsWith('127.') || // loopback
        ip.startsWith('169.254.'); // link-local
  }

  /// Проверяет, находится ли IP в приватном диапазоне
  bool _isPrivateIpRange(String ip) {
    final parts = ip.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.contains(null)) return false;

    final a = parts[0]!;
    final b = parts[1]!;

    // 10.0.0.0/8
    if (a == 10) return true;

    // 172.16.0.0/12
    if (a == 172 && b >= 16 && b <= 31) return true;

    // 192.168.0.0/16
    if (a == 192 && b == 168) return true;

    return false;
  }

  /// Возвращает предложение по исправлению проблемы на основе IP и ошибки
  String _getSuggestedAction(String targetIp, Object error) {
    if (!_isValidLocalIp(targetIp)) {
      return 'Check DNS resolution - IP seems to be outside local network';
    }

    if (error is SocketException) {
      if (error.message.contains('timed out')) {
        return 'Device unreachable - check if target device is on same network';
      } else if (error.message.contains('refused')) {
        return 'Connection refused - check if signaling server is running on target';
      }
    }

    return 'Check network connectivity and firewall settings';
  }
}
