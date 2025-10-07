/// Интерфейс для хранилища ключей
abstract class SecureStorage {
  /// Прочитать значение по ключу
  Future<String?> read(String key);

  /// Записать значение
  Future<void> write(String key, String value);

  /// Удалить значение
  Future<void> delete(String key);

  /// Проверить существование ключа
  Future<bool> containsKey(String key);

  /// Очистить все значения
  Future<void> deleteAll();
}

/// Заглушка для SecureStorage (для использования без Flutter)
/// В будущем можно заменить на FlutterSecureStorage
class MemorySecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async {
    return _storage.containsKey(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  /// Получить количество сохранённых ключей (для отладки)
  int get length => _storage.length;

  /// Получить все ключи (для отладки)
  List<String> get keys => _storage.keys.toList();
}
