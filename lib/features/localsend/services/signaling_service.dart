import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/index.dart';

/// HTTP сервер для обмена WebRTC сигналами (SDP/ICE)
class SignalingService {
  static const String _logTag = 'SignalingService';

  HttpServer? _server;
  late int _port;

  final StreamController<SignalingMessage> _messageController =
      StreamController<SignalingMessage>.broadcast();

  /// Поток входящих сигналов
  Stream<SignalingMessage> get incomingSignals => _messageController.stream;

  /// Запускает HTTP сервер на указанном порту
  Future<void> start(int port) async {
    try {
      // Проверяем, не запущен ли уже сервер
      if (_server != null) {
        logWarning(
          'Сигналинг сервер уже запущен на порту $_port',
          tag: _logTag,
        );
        return;
      }

      _port = port;

      logInfo('Запуск сигналинг сервера на порту $_port', tag: _logTag);

      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);

      _server!.listen(_handleRequest);

      logInfo('Сигналинг сервер запущен на $_port', tag: _logTag);
    } catch (e) {
      logError('Ошибка запуска сигналинг сервера', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Останавливает HTTP сервер
  Future<void> stop() async {
    try {
      if (_server != null) {
        await _server!.close(force: true);
        _server = null;
        logInfo('Сигналинг сервер остановлен', tag: _logTag);
      }
    } catch (e) {
      logError('Ошибка остановки сигналинг сервера', error: e, tag: _logTag);
    }
  }

  /// Отправляет сигнал на удаленное устройство
  Future<bool> sendSignal(
    DeviceInfo targetDevice,
    SignalingMessage message,
  ) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final url = 'http://${targetDevice.fullAddress}/signal';
      final uri = Uri.parse(url);

      logDebug(
        'Отправка сигнала на $url',
        tag: _logTag,
        data: {'type': message.type.name, 'messageId': message.messageId},
      );

      final request = await client.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');

      final jsonData = jsonEncode(message.toJson());
      request.write(jsonData);

      final response = await request.close();
      client.close();

      if (response.statusCode == 200) {
        logDebug('Сигнал успешно отправлен', tag: _logTag);
        return true;
      } else {
        logWarning(
          'Ошибка отправки сигнала: ${response.statusCode}',
          tag: _logTag,
        );
        return false;
      }
    } catch (e) {
      logError(
        'Ошибка отправки сигнала на ${targetDevice.fullAddress}',
        error: e,
        tag: _logTag,
      );
      return false;
    }
  }

  /// Получает текущий порт сервера
  int get port => _port;

  /// Проверяет, работает ли сервер
  bool get isRunning => _server != null;

  /// Освобождает ресурсы
  Future<void> dispose() async {
    await stop();
    await _messageController.close();
    logInfo('SignalingService освобожден', tag: _logTag);
  }

  /// Обрабатывает HTTP запросы
  void _handleRequest(HttpRequest request) async {
    try {
      // Настройка CORS для кросс-доменных запросов
      _setCorsHeaders(request.response);

      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }

      if (request.method == 'POST' && request.uri.path == '/signal') {
        await _handleSignalRequest(request);
      } else if (request.method == 'GET' && request.uri.path == '/ping') {
        await _handlePingRequest(request);
      } else {
        request.response.statusCode = 404;
        request.response.write('Not found');
        await request.response.close();
      }
    } catch (e) {
      logError('Ошибка обработки HTTP запроса', error: e, tag: _logTag);

      try {
        request.response.statusCode = 500;
        request.response.write('Internal server error');
        await request.response.close();
      } catch (closeError) {
        logError(
          'Ошибка закрытия HTTP ответа',
          error: closeError,
          tag: _logTag,
        );
      }
    }
  }

  /// Обрабатывает запросы сигналинга
  Future<void> _handleSignalRequest(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final jsonData = jsonDecode(body) as Map<String, dynamic>;

      final message = SignalingMessage.fromJson(jsonData);

      logDebug(
        'Получен сигнал',
        tag: _logTag,
        data: {
          'type': message.type.name,
          'from': message.fromDeviceId,
          'messageId': message.messageId,
        },
      );

      _messageController.add(message);

      request.response.statusCode = 200;
      request.response.headers.set('Content-Type', 'application/json');
      request.response.write(jsonEncode({'status': 'ok'}));
      await request.response.close();
    } catch (e) {
      logError('Ошибка обработки сигнала', error: e, tag: _logTag);

      request.response.statusCode = 400;
      request.response.write('Bad request');
      await request.response.close();
    }
  }

  /// Обрабатывает ping запросы для проверки доступности
  Future<void> _handlePingRequest(HttpRequest request) async {
    try {
      request.response.statusCode = 200;
      request.response.headers.set('Content-Type', 'application/json');
      request.response.write(
        jsonEncode({
          'status': 'ok',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'service': 'localsend-signaling',
        }),
      );
      await request.response.close();

      logDebug('Ping запрос обработан', tag: _logTag);
    } catch (e) {
      logError('Ошибка обработки ping запроса', error: e, tag: _logTag);
    }
  }

  /// Настраивает CORS заголовки
  void _setCorsHeaders(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
    response.headers.set('Access-Control-Max-Age', '86400');
  }
}
