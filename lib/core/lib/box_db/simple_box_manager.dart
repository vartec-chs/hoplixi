import 'dart:io';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'simple_box.dart';
import 'types.dart';
import 'crypto_box.dart';
import 'box_key_manager.dart';
import 'errors.dart';

/// Упрощенный singleton менеджер для простых коробок без сегментации
class SimpleBoxManager {
  static SimpleBoxManager? _instance;
  static final Completer<SimpleBoxManager> _completer =
      Completer<SimpleBoxManager>();

  final Map<String, SimpleBox> _openBoxes = {};
  final Directory _baseDirectory;
  final BoxKeyManager _keyManager;
  bool _isInitialized = false;
  bool _isShuttingDown = false;

  SimpleBoxManager._(this._baseDirectory, this._keyManager);

  /// Получить singleton instance
  static Future<SimpleBoxManager> getInstance({
    Directory? baseDirectory,
    FlutterSecureStorage? secureStorage,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    if (_completer.isCompleted) {
      return _completer.future;
    }

    try {
      final baseDir = baseDirectory ?? Directory('./storage');
      final keyManager = BoxKeyManager(secureStorage);

      _instance = SimpleBoxManager._(baseDir, keyManager);
      await _instance!._initialize();

      _completer.complete(_instance!);
      return _instance!;
    } catch (e) {
      _completer.completeError(e);
      rethrow;
    }
  }

  /// Инициализация менеджера
  Future<void> _initialize() async {
    if (_isInitialized) return;

    // Создаем базовую директорию если не существует
    if (!await _baseDirectory.exists()) {
      await _baseDirectory.create(recursive: true);
    }

    _isInitialized = true;
  }

  /// Открыть коробку с автоматическим шифрованием
  Future<SimpleBox<T>> openBox<T>({
    required String boxName,
    required FromMapFn<T> fromMap,
    required ToMapFn<T> toMap,
    bool encrypted = true,
  }) async {
    _ensureNotShuttingDown();

    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName]! as SimpleBox<T>;
    }

    CryptoBox? crypto;
    if (encrypted) {
      final rawKey = await _keyManager.getOrCreateKey(boxName);
      crypto = CryptoBox.fromRawKey(rawKey);
    }

    final box = await SimpleBox.open<T>(
      baseDir: _baseDirectory,
      boxName: boxName,
      fromMap: fromMap,
      toMap: toMap,
      crypto: crypto,
    );

    _openBoxes[boxName] = box;
    return box;
  }

  /// Открыть коробку с кастомным шифрованием
  Future<SimpleBox<T>> openBoxWithCrypto<T>({
    required String boxName,
    required FromMapFn<T> fromMap,
    required ToMapFn<T> toMap,
    CryptoBox? crypto,
  }) async {
    _ensureNotShuttingDown();

    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName]! as SimpleBox<T>;
    }

    final box = await SimpleBox.open<T>(
      baseDir: _baseDirectory,
      boxName: boxName,
      fromMap: fromMap,
      toMap: toMap,
      crypto: crypto,
    );

    _openBoxes[boxName] = box;
    return box;
  }

  /// Получить уже открытую коробку
  SimpleBox<T>? getBox<T>(String boxName) {
    if (_openBoxes.containsKey(boxName)) {
      return _openBoxes[boxName]! as SimpleBox<T>;
    }
    return null;
  }

  /// Закрыть конкретную коробку
  Future<void> closeBox(String boxName) async {
    final box = _openBoxes.remove(boxName);
    if (box != null) {
      await box.close();
    }
  }

  /// Закрыть все коробки
  Future<void> closeAllBoxes() async {
    final closeFutures = <Future>[];

    for (final box in _openBoxes.values) {
      closeFutures.add(box.close());
    }

    await Future.wait(closeFutures);
    _openBoxes.clear();
  }

  /// Получить список имен открытых коробок
  List<String> getOpenBoxNames() => _openBoxes.keys.toList();

  /// Получить статистику всех открытых коробок
  Future<Map<String, Map<String, dynamic>>> getAllBoxStats() async {
    final stats = <String, Map<String, dynamic>>{};

    for (final entry in _openBoxes.entries) {
      try {
        stats[entry.key] = await entry.value.getStats();
      } catch (e) {
        stats[entry.key] = {'error': e.toString()};
      }
    }

    return stats;
  }

  /// Компактировать все открытые коробки
  Future<void> compactAllBoxes() async {
    final compactFutures = <Future>[];

    for (final box in _openBoxes.values) {
      compactFutures.add(
        box.compact().catchError((e) {
          print('Warning: Failed to compact box: $e');
        }),
      );
    }

    await Future.wait(compactFutures);
  }

  /// Список доступных коробок в базовой директории
  Future<List<String>> listAvailableBoxes() async {
    if (!await _baseDirectory.exists()) {
      return [];
    }

    final boxNames = <String>[];

    await for (final entity in _baseDirectory.list(followLinks: false)) {
      if (entity is Directory) {
        final boxName = entity.path.split(Platform.pathSeparator).last;

        // Проверяем наличие файла данных
        final dataFile = File('${entity.path}/data.jsonl');
        if (await dataFile.exists()) {
          boxNames.add(boxName);
        }
      }
    }

    return boxNames;
  }

  /// Удалить коробку полностью (удаляет все данные)
  Future<void> deleteBox(String boxName) async {
    // Закрываем коробку если она открыта
    await closeBox(boxName);

    // Удаляем директорию коробки
    final boxDir = Directory('${_baseDirectory.path}/$boxName');
    if (await boxDir.exists()) {
      await boxDir.delete(recursive: true);
    }

    // Удаляем ключ шифрования
    try {
      await _keyManager.deleteKey(boxName);
    } catch (e) {
      // Ключ может не существовать, игнорируем ошибку
    }
  }

  /// Создать бэкап коробки
  Future<void> backupBox(String boxName, String backupPath) async {
    final box = _openBoxes[boxName];
    if (box == null) {
      throw ManifestError('Box $boxName is not open');
    }

    final sourceDir = Directory('${_baseDirectory.path}/$boxName');
    final targetDir = Directory(backupPath);

    if (!await sourceDir.exists()) {
      throw ManifestError('Source box directory does not exist');
    }

    // Создаем целевую директорию
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    // Копируем все файлы
    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(sourceDir.path.length + 1);
        final targetFile = File('${targetDir.path}/$relativePath');

        // Создаем поддиректории если нужно
        final targetFileDir = Directory(targetFile.parent.path);
        if (!await targetFileDir.exists()) {
          await targetFileDir.create(recursive: true);
        }

        await entity.copy(targetFile.path);
      }
    }
  }

  /// Восстановить коробку из бэкапа
  Future<void> restoreBox(String boxName, String backupPath) async {
    // Закрываем коробку если открыта
    await closeBox(boxName);

    final sourceDir = Directory(backupPath);
    final targetDir = Directory('${_baseDirectory.path}/$boxName');

    if (!await sourceDir.exists()) {
      throw ManifestError('Backup directory does not exist');
    }

    // Удаляем существующую коробку
    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }

    // Создаем новую директорию
    await targetDir.create(recursive: true);

    // Копируем файлы из бэкапа
    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(sourceDir.path.length + 1);
        final targetFile = File('${targetDir.path}/$relativePath');

        // Создаем поддиректории если нужно
        final targetFileDir = Directory(targetFile.parent.path);
        if (!await targetFileDir.exists()) {
          await targetFileDir.create(recursive: true);
        }

        await entity.copy(targetFile.path);
      }
    }
  }

  /// Завершить работу менеджера и закрыть все коробки
  Future<void> shutdown() async {
    if (_isShuttingDown) return;

    _isShuttingDown = true;

    try {
      await closeAllBoxes();
    } finally {
      _instance = null;
      _isInitialized = false;
      _isShuttingDown = false;
    }
  }

  /// Проверить что менеджер не завершает работу
  void _ensureNotShuttingDown() {
    if (_isShuttingDown) {
      throw ManifestError('SimpleBoxManager is shutting down');
    }
  }

  /// Получить путь к базовой директории
  String get baseDirectoryPath => _baseDirectory.path;

  /// Проверить инициализацию менеджера
  bool get isInitialized => _isInitialized;

  /// Получить количество открытых коробок
  int get openBoxCount => _openBoxes.length;
}
