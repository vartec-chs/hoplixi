import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:riverpod/riverpod.dart';

import '../flutter_secure_storageo_impl.dart';
import 'encrypted_key_value_storage.dart';
import 'secure_storage_models.dart';

/// Типизированное хранилище для списка баз данных
class DatabaseListStorage {
  final EncryptedKeyValueStorage _storage;
  static const String _storageKey = 'database_list';

  DatabaseListStorage(this._storage);

  Future<void> addDatabase(DatabaseEntry database) async {
    await _storage.write<DatabaseEntry>(
      storageKey: _storageKey,
      key: database.id,
      data: database,
      toJson: (db) => db.toJson(),
    );
  }

  Future<DatabaseEntry?> getDatabase(String id) async {
    return await _storage.read<DatabaseEntry>(
      storageKey: _storageKey,
      key: id,
      fromJson: (json) => DatabaseEntry.fromJson(json),
    );
  }

  Future<List<DatabaseEntry>> getAllDatabases() async {
    final databases = await _storage.readAll<DatabaseEntry>(
      storageKey: _storageKey,
      fromJson: (json) => DatabaseEntry.fromJson(json),
    );
    return databases.values.toList()
      ..sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
  }

  Future<void> updateDatabase(DatabaseEntry database) async {
    await addDatabase(database);
  }

  Future<void> removeDatabase(String id) async {
    await _storage.delete(storageKey: _storageKey, key: id);
  }

  Future<void> clearAllDatabases() async {
    await _storage.deleteAll(storageKey: _storageKey);
  }

  Future<bool> containsDatabase(String id) async {
    return await _storage.containsKey(storageKey: _storageKey, key: id);
  }

  Future<List<String>> getDatabaseIds() async {
    return await _storage.getKeys(storageKey: _storageKey);
  }

  Future<void> updateLastAccessed(String id) async {
    final database = await getDatabase(id);
    if (database != null) {
      final updatedDatabase = database.copyWith(lastAccessed: DateTime.now());
      await updateDatabase(updatedDatabase);
    }
  }
}

/// Типизированное хранилище для сессий авторизации
class AuthSessionStorage {
  final EncryptedKeyValueStorage _storage;
  static const String _storageKey = 'auth_sessions';

  AuthSessionStorage(this._storage);

  Future<void> saveSession(AuthSession session) async {
    await _storage.write<AuthSession>(
      storageKey: _storageKey,
      key: session.sessionId,
      data: session,
      toJson: (session) => session.toJson(),
    );
  }

  Future<AuthSession?> getSession(String sessionId) async {
    return await _storage.read<AuthSession>(
      storageKey: _storageKey,
      key: sessionId,
      fromJson: (json) => AuthSession.fromJson(json),
    );
  }

  Future<List<AuthSession>> getAllSessions() async {
    final sessions = await _storage.readAll<AuthSession>(
      storageKey: _storageKey,
      fromJson: (json) => AuthSession.fromJson(json),
    );
    return sessions.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<AuthSession>> getActiveSessions() async {
    final sessions = await getAllSessions();
    final now = DateTime.now();
    return sessions.where((session) => session.expiresAt.isAfter(now)).toList();
  }

  Future<void> removeSession(String sessionId) async {
    await _storage.delete(storageKey: _storageKey, key: sessionId);
  }

  Future<void> clearExpiredSessions() async {
    final sessions = await getAllSessions();
    final now = DateTime.now();

    for (final session in sessions) {
      if (session.expiresAt.isBefore(now)) {
        await removeSession(session.sessionId);
      }
    }
  }

  Future<void> clearAllSessions() async {
    await _storage.deleteAll(storageKey: _storageKey);
  }

  Future<bool> isSessionValid(String sessionId) async {
    final session = await getSession(sessionId);
    if (session == null) return false;

    return session.expiresAt.isAfter(DateTime.now());
  }

  Future<AuthSession?> getCurrentSession() async {
    final sessions = await getActiveSessions();
    return sessions.isNotEmpty ? sessions.first : null;
  }
}

/// Поставщики для Riverpod
final encryptedStorageProvider = Provider<EncryptedKeyValueStorage>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  return EncryptedKeyValueStorage(
    secureStorage: secureStorage,
    appName: MainConstants.appName,
    enableCache: true,
  );
});

final databaseListStorageProvider = Provider<DatabaseListStorage>((ref) {
  final storage = ref.read(encryptedStorageProvider);
  return DatabaseListStorage(storage);
});

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  final storage = ref.read(encryptedStorageProvider);
  return AuthSessionStorage(storage);
});

/// Инициализация хранилища
final storageInitializationProvider = FutureProvider<void>((ref) async {
  final storage = ref.read(encryptedStorageProvider);
  await storage.initialize();
});
