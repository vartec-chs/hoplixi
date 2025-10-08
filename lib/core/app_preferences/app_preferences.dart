import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'keys.dart';
import 'package:shared_preferences/shared_preferences.dart';



/// 2) Сервис-обёртка
class Prefs {
  static late SharedPreferences _prefs;
  static final Map<String, ValueNotifier<dynamic>> _notifiers = {};

  /// Вызывать в main() до runApp
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  

  static bool contains(PrefKey key) => _prefs.containsKey(key.key);

  static Future<bool> remove(PrefKey key) => _prefs.remove(key.key);

  static Future<bool> clear() => _prefs.clear();

  static Future<bool> set<T>(PrefKey<T> key, T value) async {
    final k = key.key;
    bool result;
    if (T == String) {
      result = await _prefs.setString(k, value as String);
    } else if (T == int) {
      result = await _prefs.setInt(k, value as int);
    } else if (T == double) {
      result = await _prefs.setDouble(k, value as double);
    } else if (T == bool) {
      result = await _prefs.setBool(k, value as bool);
    } else if (T == List<String>) {
      result = await _prefs.setStringList(k, value as List<String>);
    } else {
      throw UnsupportedError('Unsupported type for SharedPreferences: $T');
    }

    // обновляем нотифаер если кто-то слушает
    if (_notifiers.containsKey(k)) _notifiers[k]!.value = value;
    return result;
  }

  /// Синхронный get (SharedPreferences уже инициализирован)
  static T? get<T>(PrefKey<T> key) {
    final k = key.key;
    if (!_prefs.containsKey(k)) return null;

    if (T == String) return _prefs.getString(k) as T?;
    if (T == int) return _prefs.getInt(k) as T?;
    if (T == double) return _prefs.getDouble(k) as T?;
    if (T == bool) return _prefs.getBool(k) as T?;
    if (T == List<String>) return _prefs.getStringList(k) as T?;
    throw UnsupportedError('Unsupported type for SharedPreferences: $T');
  }

  /// Простой listen/notify: ValueListenable для ключа
  static ValueListenable<T?> listen<T>(PrefKey<T> key) {
    final k = key.key;
    if (!_notifiers.containsKey(k)) {
      final initial = get<T>(key);
      _notifiers[k] = ValueNotifier<T?>(initial);
    }
    return _notifiers[k] as ValueListenable<T?>;
  }

  /// Сохранение сложного объекта как JSON (нужны сериализаторы)
  static Future<void> setObject<T>(
    PrefKey<String> key,
    T object,
    String Function(T) toJson,
  ) {
    return set<String>(key, toJson(object));
  }

  static T? getObject<T>(
    PrefKey<String> key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final s = get<String>(key);
    if (s == null) return null;
    final map = jsonDecode(s) as Map<String, dynamic>;
    return fromJson(map);
  }
}
