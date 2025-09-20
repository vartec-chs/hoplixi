/// 1) Типизированный ключ.
class PrefKey<T> {
  final String key;
  const PrefKey(this.key);
}

/// Пример списка ключей
class Keys {
  static const PrefKey<String> token = PrefKey<String>('token');
  static const PrefKey<bool> isLogged = PrefKey<bool>('is_logged');
  static const PrefKey<int> counter = PrefKey<int>('counter');
  static const PrefKey<List<String>> favorites = PrefKey<List<String>>(
    'favorites',
  );
  static const PrefKey<String> userJson = PrefKey<String>(
    'user_json',
  ); // для сериализации объектов
  static const PrefKey<bool> autoOpenLastStorage = PrefKey<bool>(
    'auto_open_last_storage',
  );
  //theme 
  static const PrefKey<String> themeMode = PrefKey<String>('theme_mode');
}
