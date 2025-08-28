import 'package:riverpod/riverpod.dart';
import '../secure_storage/encrypted_key_value_storage.dart';
import '../secure_storage/secure_storage_models.dart';
import '../flutter_secure_storageo_impl.dart';
import '../constants/main_constants.dart';

/// Глобальный провайдер для безопасного хранилища
final globalSecureStorageProvider = Provider<EncryptedKeyValueStorage>((ref) {
  final secureStorage = FlutterSecureStorageImpl();
  final storage = EncryptedKeyValueStorage(
    secureStorage: secureStorage,
    appName: MainConstants.appName,
    enableCache: true,
  );

  // Автоматическая инициализация при первом обращении
  ref.onDispose(() {
    storage.dispose();
  });

  return storage;
});

/// Провайдер для инициализации хранилища
final storageInitProvider = FutureProvider<void>((ref) async {
  final storage = ref.read(globalSecureStorageProvider);
  await storage.initialize();
});

/// Сервис-локатор для удобного доступа ко всем функциям хранилища
class StorageServiceLocator {
  static ProviderContainer? _container;

  // Константы для ключей хранилища
  static const String _databaseListKey = 'database_list';
  static const String _authSessionsKey = 'auth_sessions';

  static void initialize(ProviderContainer container) {
    _container = container;
  }

  static EncryptedKeyValueStorage get _storage {
    if (_container == null) {
      throw StateError(
        'StorageServiceLocator not initialized. Call initialize() first.',
      );
    }
    return _container!.read(globalSecureStorageProvider);
  }

  static Future<void> initializeStorage() async {
    if (_container == null) {
      throw StateError('StorageServiceLocator not initialized.');
    }
    await _container!.read(storageInitProvider.future);
  }

  // === МЕТОДЫ ДЛЯ РАБОТЫ С БАЗАМИ ДАННЫХ ===

  /// Добавляет базу данных в список
  static Future<void> addDatabase(DatabaseEntry database) async {
    await _storage.write<DatabaseEntry>(
      storageKey: _databaseListKey,
      key: database.id,
      data: database,
      toJson: (db) => db.toJson(),
    );
  }

  /// Получает базу данных по ID
  static Future<DatabaseEntry?> getDatabase(String id) async {
    return await _storage.read<DatabaseEntry>(
      storageKey: _databaseListKey,
      key: id,
      fromJson: (json) => DatabaseEntry.fromJson(json),
    );
  }

  /// Получает все базы данных, отсортированные по времени последнего доступа
  static Future<List<DatabaseEntry>> getAllDatabases() async {
    final databases = await _storage.readAll<DatabaseEntry>(
      storageKey: _databaseListKey,
      fromJson: (json) => DatabaseEntry.fromJson(json),
    );
    return databases.values.toList()
      ..sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
  }

  /// Обновляет базу данных
  static Future<void> updateDatabase(DatabaseEntry database) async {
    await addDatabase(database);
  }

  /// Удаляет базу данных из списка
  static Future<void> removeDatabase(String id) async {
    await _storage.delete(storageKey: _databaseListKey, key: id);
  }

  /// Очищает весь список баз данных
  static Future<void> clearAllDatabases() async {
    await _storage.deleteAll(storageKey: _databaseListKey);
  }

  /// Проверяет, существует ли база данных с данным ID
  static Future<bool> containsDatabase(String id) async {
    return await _storage.containsKey(storageKey: _databaseListKey, key: id);
  }

  /// Получает список ID всех баз данных
  static Future<List<String>> getDatabaseIds() async {
    return await _storage.getKeys(storageKey: _databaseListKey);
  }

  /// Обновляет время последнего доступа к базе данных
  static Future<void> updateLastAccessed(String id) async {
    final database = await getDatabase(id);
    if (database != null) {
      final updatedDatabase = database.copyWith(lastAccessed: DateTime.now());
      await updateDatabase(updatedDatabase);
    }
  }

  // === МЕТОДЫ ДЛЯ РАБОТЫ С СЕССИЯМИ АВТОРИЗАЦИИ ===

  /// Сохраняет сессию авторизации
  static Future<void> saveSession(AuthSession session) async {
    await _storage.write<AuthSession>(
      storageKey: _authSessionsKey,
      key: session.sessionId,
      data: session,
      toJson: (session) => session.toJson(),
    );
  }

  /// Получает сессию по ID
  static Future<AuthSession?> getSession(String sessionId) async {
    return await _storage.read<AuthSession>(
      storageKey: _authSessionsKey,
      key: sessionId,
      fromJson: (json) => AuthSession.fromJson(json),
    );
  }

  /// Получает все сессии, отсортированные по времени создания
  static Future<List<AuthSession>> getAllSessions() async {
    final sessions = await _storage.readAll<AuthSession>(
      storageKey: _authSessionsKey,
      fromJson: (json) => AuthSession.fromJson(json),
    );
    return sessions.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Получает только активные (не истекшие) сессии
  static Future<List<AuthSession>> getActiveSessions() async {
    final sessions = await getAllSessions();
    final now = DateTime.now();
    return sessions.where((session) => session.expiresAt.isAfter(now)).toList();
  }

  /// Удаляет сессию
  static Future<void> removeSession(String sessionId) async {
    await _storage.delete(storageKey: _authSessionsKey, key: sessionId);
  }

  /// Очищает просроченные сессии
  static Future<void> clearExpiredSessions() async {
    final sessions = await getAllSessions();
    final now = DateTime.now();

    for (final session in sessions) {
      if (session.expiresAt.isBefore(now)) {
        await removeSession(session.sessionId);
      }
    }
  }

  /// Очищает все сессии
  static Future<void> clearAllSessions() async {
    await _storage.deleteAll(storageKey: _authSessionsKey);
  }

  /// Проверяет, валидна ли сессия
  static Future<bool> isSessionValid(String sessionId) async {
    final session = await getSession(sessionId);
    if (session == null) return false;

    return session.expiresAt.isAfter(DateTime.now());
  }

  /// Получает текущую активную сессию (самую новую)
  static Future<AuthSession?> getCurrentSession() async {
    final sessions = await getActiveSessions();
    return sessions.isNotEmpty ? sessions.first : null;
  }

  // === ОБЩИЕ МЕТОДЫ ДЛЯ РАБОТЫ С ХРАНИЛИЩЕМ ===

  /// Получает прямой доступ к базовому хранилищу для расширенных операций
  static EncryptedKeyValueStorage get secureStorage => _storage;

  /// Очищает кэш хранилища
  static Future<void> clearCache() async {
    await _storage.clearCache();
  }

  /// Проверяет целостность всех хранилищ
  static Future<Map<String, bool>> verifyAllStoragesIntegrity() async {
    return await _storage.verifyAllStoragesIntegrity();
  }

  /// Получает размер хранилища в байтах
  static Future<int> getStorageSize(String storageKey) async {
    return await _storage.getStorageSize(storageKey);
  }

  /// Экспортирует зашифрованные данные для резервного копирования
  static Future<Map<String, dynamic>> exportEncryptedData(
    String storageKey,
  ) async {
    return await _storage.exportEncryptedData(storageKey);
  }

  /// Получает метаданные хранилища
  static Future<FileMetadata?> getStorageMetadata(String storageKey) async {
    return await _storage.getStorageMetadata(storageKey);
  }

  /// Проверяет целостность конкретного хранилища
  static Future<bool> verifyStorageIntegrity(String storageKey) async {
    return await _storage.verifyStorageIntegrity(storageKey);
  }

  /// Полностью удаляет хранилище с диска
  static Future<void> deleteStorage(String storageKey) async {
    await _storage.deleteStorage(storageKey: storageKey);
  }

  // === ДОПОЛНИТЕЛЬНЫЕ УТИЛИТЫ ===

  /// Получает статистику по всем хранилищам
  static Future<Map<String, dynamic>> getStorageStatistics() async {
    final databasesSize = await getStorageSize(_databaseListKey);
    final sessionsSize = await getStorageSize(_authSessionsKey);
    final databasesCount = (await getDatabaseIds()).length;
    final sessionsCount = (await getAllSessions()).length;
    final activeSessionsCount = (await getActiveSessions()).length;

    return {
      'databaseStorage': {'size': databasesSize, 'count': databasesCount},
      'sessionStorage': {
        'size': sessionsSize,
        'totalSessions': sessionsCount,
        'activeSessions': activeSessionsCount,
      },
      'totalSize': databasesSize + sessionsSize,
    };
  }

  /// Выполняет полную очистку всех данных (осторожно!)
  static Future<void> clearAllData() async {
    await clearAllDatabases();
    await clearAllSessions();
    await clearCache();
  }

  /// Выполняет автоматическое обслуживание хранилища
  static Future<void> performMaintenance() async {
    // Очищаем просроченные сессии
    await clearExpiredSessions();

    // Очищаем кэш
    await clearCache();

    // Проверяем целостность
    final integrity = await verifyAllStoragesIntegrity();

    // Логируем результаты проверки целостности
    for (final entry in integrity.entries) {
      if (!entry.value) {
        print('Warning: Storage integrity check failed for ${entry.key}');
      }
    }
  }
}
