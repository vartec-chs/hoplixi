import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hoplixi/core/logger/app_logger.dart';

class HttpSignalingService {
  static const _logTag = 'HttpSignalingService';
  HttpServer? _httpServer;
  WebSocket? _clientSocket; // если мы подключились как клиент
  final List<WebSocket> _clients = []; // для режима server
  final _onMessageWs =
      StreamController<
        Map<String, dynamic>
      >.broadcast(); // Сообщения от клиента/сервера

  Stream<Map<String, dynamic>> get onMessageWs =>
      _onMessageWs.stream; // Поток входящих сообщений

  Future<void> startServer({int port = 53317}) async {
    if (_httpServer != null) {
      logWarning('Сервер уже запущен', tag: _logTag);
      return;
    }
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _httpServer!.listen((HttpRequest req) async {
      // Ожидаем апгрейд на websocket
      try {
        if (WebSocketTransformer.isUpgradeRequest(req)) {
          final ws = await WebSocketTransformer.upgrade(req);
          _registerClient(ws);
        } else {
          req.response
            ..statusCode = HttpStatus.forbidden
            ..close();
        }
      } catch (e, stackTrace) {
        logError(
          'Ошибка при апгрейде до WebSocket: $e',
          tag: _logTag,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    });
  }

  void _registerClient(WebSocket ws) {
    _clients.add(ws);
    ws.listen(
      (data) {
        try {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          _onMessageWs.add(msg);
        } catch (e, stackTrace) {
          logError(
            'Ошибка при обработке сообщения: $e',
            tag: _logTag,
            stackTrace: stackTrace,
          );
        }
      },
      onDone: () {
        _clients.remove(ws);
      },
      onError: (_) {
        _clients.remove(ws);
      },
    );
  }

  // Connect as a client to remote websocket server
  Future<void> connect(String uri) async {
    _clientSocket = await WebSocket.connect(uri.replaceAll('http', 'ws'));
    _clientSocket!.listen(
      (data) {
        try {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          _onMessageWs.add(msg);
        } catch (e, stackTrace) {
          logError(
            'Ошибка при обработке сообщения: $e',
            tag: _logTag,
            stackTrace: stackTrace,
          );
        }
      },
      onDone: () {
        _clientSocket = null;
      },
      onError: (e) {
        _clientSocket = null;
      },
    );
  }

  // Close server and all connections
  Future<void> send(Map<String, dynamic> json) async {
    final text = jsonEncode(json);
    // if client mode
    if (_clientSocket != null) {
      _clientSocket!.add(text);
      return;
    }
    // else broadcast to all connected clients (server mode)
    for (final c in List<WebSocket>.from(_clients)) {
      try {
        c.add(text);
      } catch (e) {
        _clients.remove(c);
      }
    }
  }

  Future<void> stop() async {
    for (final c in List<WebSocket>.from(_clients)) {
      await c.close();
    }
    _clients.clear();
    if (_clientSocket != null) {
      await _clientSocket!.close();
      _clientSocket = null;
    }
    if (_httpServer != null) {
      await _httpServer!.close(force: true);
      _httpServer = null;
    }
    await _onMessageWs.close();
  }
}
