import 'dart:async';
import 'dart:ui';

/// Утилита для debouncing вызовов функций
class Debouncer {
  /// Таймер для debounce
  Timer? _timer;

  /// Продолжительность задержки
  final Duration delay;

  /// Создает новый debouncer с указанной задержкой
  Debouncer({required this.delay});

  /// Выполняет функцию с debounce
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Отменяет ожидающий вызов
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Проверяет активен ли debouncer
  bool get isActive => _timer?.isActive ?? false;

  /// Освобождает ресурсы
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Расширенная версия debouncer с поддержкой разных типов задержек
class AdvancedDebouncer {
  /// Таймеры для разных ключей
  final Map<String, Timer> _timers = {};

  /// Выполняет функцию с debounce по ключу
  void run(String key, Duration delay, VoidCallback action) {
    _timers[key]?.cancel();
    _timers[key] = Timer(delay, () {
      action();
      _timers.remove(key);
    });
  }

  /// Отменяет ожидающий вызов по ключу
  void cancel(String key) {
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// Отменяет все ожидающие вызовы
  void cancelAll() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// Проверяет активен ли debouncer для ключа
  bool isActive(String key) {
    return _timers[key]?.isActive ?? false;
  }

  /// Освобождает все ресурсы
  void dispose() {
    cancelAll();
  }
}
