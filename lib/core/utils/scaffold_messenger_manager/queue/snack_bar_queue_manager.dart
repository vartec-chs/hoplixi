import 'dart:collection';
import '../models/snack_bar_data.dart';

abstract class SnackBarQueueManager {
  void enqueue(SnackBarData data);
  SnackBarData? dequeue();
  bool get isEmpty;
  bool get isNotEmpty;
  int get length;
  void clear();

  // Методы для управления состоянием инициализации
  void setInitialized(bool initialized);
  bool get isInitialized;

  // Обработка очереди после инициализации
  List<SnackBarData> flushPendingQueue();
}

class DefaultSnackBarQueueManager implements SnackBarQueueManager {
  final Queue<SnackBarData> _queue = Queue<SnackBarData>();
  final Queue<SnackBarData> _pendingQueue = Queue<SnackBarData>();
  bool _isInitialized = false;

  @override
  void enqueue(SnackBarData data) {
    if (_isInitialized) {
      _queue.addLast(data);
    } else {
      // Если приложение еще не инициализировано, сохраняем в отдельную очередь
      _pendingQueue.addLast(data);
    }
  }

  @override
  SnackBarData? dequeue() {
    if (_queue.isEmpty) return null;
    return _queue.removeFirst();
  }

  @override
  bool get isEmpty => _queue.isEmpty;

  @override
  bool get isNotEmpty => _queue.isNotEmpty;

  @override
  int get length => _queue.length;

  @override
  void clear() {
    _queue.clear();
    _pendingQueue.clear();
  }

  @override
  void setInitialized(bool initialized) {
    _isInitialized = initialized;

    if (initialized && _pendingQueue.isNotEmpty) {
      // Перемещаем все сообщения из pending очереди в основную
      while (_pendingQueue.isNotEmpty) {
        _queue.addLast(_pendingQueue.removeFirst());
      }
    }
  }

  @override
  bool get isInitialized => _isInitialized;

  @override
  List<SnackBarData> flushPendingQueue() {
    final List<SnackBarData> pendingItems = _pendingQueue.toList();

    // Перемещаем все элементы из pending в основную очередь
    while (_pendingQueue.isNotEmpty) {
      _queue.addLast(_pendingQueue.removeFirst());
    }

    return pendingItems;
  }

  // Дополнительные методы для отладки и мониторинга

  /// Получить количество сообщений в pending очереди
  int get pendingLength => _pendingQueue.length;

  /// Проверить есть ли сообщения в pending очереди
  bool get hasPendingMessages => _pendingQueue.isNotEmpty;

  /// Получить общее количество сообщений (основная очередь + pending)
  int get totalLength => _queue.length + _pendingQueue.length;
}
