import 'dart:io';
import 'dart:convert';
import 'package:archive/archive_io.dart';
import 'package:hoplixi/core/index.dart';
import 'package:path/path.dart' as path;

/// Результат экспорта бокса
class BoxExportResult {
  /// Путь до архива
  final String archivePath;

  /// Имя бокса
  final String boxName;

  /// Ключ шифрования архива (base64)
  final String encryptionKey;

  BoxExportResult({
    required this.archivePath,
    required this.boxName,
    required this.encryptionKey,
  });

  Map<String, dynamic> toJson() => {
    'archivePath': archivePath,
    'boxName': boxName,
    'encryptionKey': encryptionKey,
  };

  factory BoxExportResult.fromJson(Map<String, dynamic> json) =>
      BoxExportResult(
        archivePath: json['archivePath'] as String,
        boxName: json['boxName'] as String,
        encryptionKey: json['encryptionKey'] as String,
      );

  @override
  String toString() =>
      'BoxExport(boxName: $boxName, archive: $archivePath, key: ${encryptionKey.substring(0, 10)}...)';
}

/// Менеджер для управления несколькими базами данных
class BoxManager {
  final String basePath;
  final SecureStorage _secureStorage;
  final Map<String, BoxDB> _openBoxes = {};

  BoxManager({required this.basePath, SecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? FlutterSecureStorageImpl();

  /// Создать новую базу данных
  ///
  /// Автоматически генерируется случайный ключ шифрования
  /// и сохраняется в SecureStorage.
  Future<BoxDB<T>> createBox<T>({
    required String name,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  }) async {
    // Проверить, не открыта ли уже БД
    if (_openBoxes.containsKey(name)) {
      throw BoxManagerException('БД "$name" уже открыта');
    }

    // Генерируем случайный ключ
    final encryption = await EncryptionService.generate();
    final exportedKey = await encryption.exportKey();

    // Сохраняем в SecureStorage для будущего использования
    await _secureStorage.write('box_password_$name', exportedKey);

    // Создать БД (без пароля, чтобы BoxDB сам сгенерировал и сохранил в meta.json)
    final db = await BoxDB.create<T>(
      name: name,
      basePath: basePath,
      password: exportedKey,
      fromJson: fromJson,
      toJson: toJson,
      getId: getId,
    );

    // Сохранить в списке открытых
    _openBoxes[name] = db;

    return db;
  }

  /// Открыть существующую базу данных
  ///
  /// Ключ автоматически загружается из SecureStorage.
  Future<BoxDB<T>> openBox<T>({
    required String name,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  }) async {
    // Проверить, не открыта ли уже БД
    if (_openBoxes.containsKey(name)) {
      return _openBoxes[name] as BoxDB<T>;
    }

    // Загрузить ключ из SecureStorage
    final storedPassword = await _secureStorage.read('box_password_$name');

    // Если ключа нет в SecureStorage, БД будет использовать ключ из meta.json
    // (который был сохранён при создании без пароля)

    // Открыть БД
    final db = await BoxDB.open<T>(
      name: name,
      basePath: basePath,
      password: storedPassword,
      fromJson: fromJson,
      toJson: toJson,
      getId: getId,
    );

    // Сохранить в списке открытых
    _openBoxes[name] = db;

    return db;
  }

  /// Получить открытую БД по имени
  BoxDB<T>? getBox<T>(String name) {
    return _openBoxes[name] as BoxDB<T>?;
  }

  /// Проверить, открыта ли БД
  bool isBoxOpen(String name) {
    return _openBoxes.containsKey(name);
  }

  /// Закрыть конкретную БД
  Future<void> closeBox(String name) async {
    final box = _openBoxes[name];
    if (box != null) {
      await box.close();
      _openBoxes.remove(name);
    }
  }

  /// Закрыть все открытые БД
  Future<void> closeAll() async {
    final futures = <Future>[];

    for (final box in _openBoxes.values) {
      futures.add(box.close());
    }

    await Future.wait(futures);
    _openBoxes.clear();
  }

  /// Удалить ключ БД из SecureStorage
  Future<void> deleteBoxKey(String name) async {
    await _secureStorage.delete('box_key_$name');
  }

  /// Получить список открытых БД
  List<String> get openBoxNames => _openBoxes.keys.toList();

  /// Количество открытых БД
  int get openBoxCount => _openBoxes.length;

  /// Сохранить ключ для БД в SecureStorage
  ///
  /// Полезно для сохранения пароля или ключа шифрования
  Future<void> saveBoxKey(String name, String key) async {
    await _secureStorage.write('box_key_$name', key);
  }

  /// Загрузить ключ БД из SecureStorage
  Future<String?> loadBoxKey(String name) async {
    return await _secureStorage.read('box_key_$name');
  }

  /// Проверить наличие сохранённого ключа для БД
  Future<bool> hasBoxKey(String name) async {
    return await _secureStorage.containsKey('box_key_$name');
  }

  /// Очистить все сохранённые ключи
  Future<void> clearAllKeys() async {
    await _secureStorage.deleteAll();
  }

  /// Экспортировать бокс в зашифрованный архив
  ///
  /// Создаёт zip-архив с содержимым бокса и шифрует его.
  /// Перед экспортом выполняет компактификацию бокса.
  /// Создаёт файл box_key.txt с ключом шифрования бокса.
  /// Возвращает [BoxExportResult] с путём к архиву, именем бокса и ключом шифрования.
  ///
  /// [name] - имя бокса для экспорта
  /// [outputPath] - путь для сохранения архива (опционально, по умолчанию basePath)
  /// [fromJson] - функция десериализации (требуется для компактификации)
  /// [toJson] - функция сериализации (требуется для компактификации)
  /// [getId] - функция получения ID (требуется для компактификации)
  Future<BoxExportResult> exportBox<T>({
    required String name,
    String? outputPath,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  }) async {
    // Проверить, что бокс существует
    final boxDir = Directory(path.join(basePath, name));
    if (!await boxDir.exists()) {
      throw BoxManagerException('Бокс "$name" не найден');
    }

    // Открыть бокс, если он закрыт (нужно для компактификации)
    final wasOpen = isBoxOpen(name);
    BoxDB<T>? db;

    if (!wasOpen) {
      db = await openBox<T>(
        name: name,
        fromJson: fromJson,
        toJson: toJson,
        getId: getId,
      );
    } else {
      db = getBox<T>(name);
    }

    // Выполнить компактификацию перед экспортом
    if (db != null) {
      await db.compact();
    }

    // Закрыть бокс после компактификации
    if (db != null) {
      await closeBox(name);
    }

    // Прочитать ключ шифрования бокса из meta.json
    final metaFile = File(path.join(boxDir.path, 'meta.json'));
    String? boxEncryptionKey;

    if (await metaFile.exists()) {
      final metaContent = await metaFile.readAsString();
      final meta = jsonDecode(metaContent) as Map<String, dynamic>;
      boxEncryptionKey = meta['encryption_key'] as String?;
    }

    // Создать временный архив
    final archive = Archive();

    // Добавить все файлы бокса в архив
    await for (final entity in boxDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: boxDir.path);
        final bytes = await entity.readAsBytes();
        final archiveFile = ArchiveFile(relativePath, bytes.length, bytes);
        archive.addFile(archiveFile);
      }
    }

    // Добавить файл box_key.txt с ключом шифрования бокса
    if (boxEncryptionKey != null) {
      final keyFileContent = boxEncryptionKey;
      final keyFileBytes = utf8.encode(keyFileContent);
      final keyArchiveFile = ArchiveFile(
        'box_key.txt',
        keyFileBytes.length,
        keyFileBytes,
      );
      archive.addFile(keyArchiveFile);
    }

    // Сгенерировать случайный ключ шифрования для архива
    final encryptionService = await EncryptionService.generate();
    final encryptionKey = await encryptionService.exportKey();

    // Закодировать архив в zip
    final zipData = ZipEncoder().encode(archive);

    // Зашифровать архив (конвертируем в строку base64)
    final zipDataString = base64Encode(zipData);
    final encryptedArchive = await encryptionService.encrypt(zipDataString);

    // Определить путь для сохранения
    final savePath = outputPath ?? basePath;
    final archiveDir = Directory(savePath);
    if (!await archiveDir.exists()) {
      await archiveDir.create(recursive: true);
    }

    // Сохранить зашифрованный архив
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final archivePath = path.join(savePath, '${name}_export_$timestamp.boxz');
    final archiveFile = File(archivePath);

    // Записать зашифрованные данные
    await archiveFile.writeAsString(jsonEncode(encryptedArchive.toJson()));

    return BoxExportResult(
      archivePath: archivePath,
      boxName: name,
      encryptionKey: encryptionKey,
    );
  }

  /// Импортировать бокс из зашифрованного архива
  ///
  /// Расшифровывает архив и извлекает содержимое бокса в basePath.
  ///
  /// [boxName] - имя для импортированного бокса
  /// [encryptionKey] - ключ шифрования архива (base64)
  /// [archivePath] - путь к зашифрованному архиву
  /// [overwrite] - перезаписать существующий бокс (по умолчанию false)
  Future<void> importBox({
    required String boxName,
    required String encryptionKey,
    required String archivePath,
    bool overwrite = false,
  }) async {
    // Проверить, что архив существует
    final archiveFile = File(archivePath);
    if (!await archiveFile.exists()) {
      throw BoxManagerException('Архив не найден: $archivePath');
    }

    // Проверить, не существует ли уже бокс
    final boxDir = Directory(path.join(basePath, boxName));
    if (await boxDir.exists() && !overwrite) {
      throw BoxManagerException(
        'Бокс "$boxName" уже существует. Используйте overwrite: true для перезаписи',
      );
    }

    // Закрыть бокс, если он открыт
    if (isBoxOpen(boxName)) {
      await closeBox(boxName);
    }

    // Прочитать зашифрованный архив
    final encryptedDataJson =
        jsonDecode(await archiveFile.readAsString()) as Map<String, dynamic>;
    final encryptedData = EncryptedData.fromJson(encryptedDataJson);

    // Создать сервис шифрования из ключа
    final encryptionService = EncryptionService.fromExportedKey(encryptionKey);

    // Расшифровать архив (получаем base64 строку)
    final decryptedBase64 = await encryptionService.decrypt(encryptedData);

    // Декодировать из base64 в байты
    final zipData = base64Decode(decryptedBase64);

    // Декодировать zip
    final archive = ZipDecoder().decodeBytes(zipData);

    // Найти и извлечь ключ из box_key.txt
    String? boxEncryptionKey;
    for (final file in archive.files) {
      if (file.name == 'box_key.txt' && file.isFile) {
        final keyContent = utf8.decode(file.content as List<int>);
        boxEncryptionKey = keyContent;
        break;
      }
    }

    // Сохранить ключ в SecureStorage
    if (boxEncryptionKey != null) {
      await _secureStorage.write('box_key_$boxName', boxEncryptionKey);
    }

    // Удалить существующий бокс, если требуется перезапись
    if (await boxDir.exists()) {
      await boxDir.delete(recursive: true);
    }

    // Создать директорию бокса
    await boxDir.create(recursive: true);

    // Извлечь все файлы (кроме box_key.txt)
    for (final file in archive.files) {
      if (file.isFile && file.name != 'box_key.txt') {
        final filePath = path.join(boxDir.path, file.name);
        final outputFile = File(filePath);

        // Создать директории, если нужно
        await outputFile.parent.create(recursive: true);

        // Записать файл
        await outputFile.writeAsBytes(file.content as List<int>);
      }
    }

    // удалить временный архив
    await archiveFile.delete();
  }

  /// Полностью удалить бокс
  ///
  /// Удаляет директорию бокса, закрывает его (если открыт)
  /// и удаляет сохранённые ключи из SecureStorage.
  ///
  /// [name] - имя бокса для удаления
  /// [deleteKeys] - удалить ключи из SecureStorage (по умолчанию true)
  Future<void> deleteBox(String name, {bool deleteKeys = true}) async {
    // Закрыть бокс, если он открыт
    if (isBoxOpen(name)) {
      await closeBox(name);
    }

    // Удалить директорию бокса
    final boxDir = Directory(path.join(basePath, name));
    if (await boxDir.exists()) {
      await boxDir.delete(recursive: true);
    }

    // Удалить ключи из SecureStorage
    if (deleteKeys) {
      await _secureStorage.delete('box_key_$name');
      await _secureStorage.delete('box_password_$name');
    }
  }
}

/// Исключение менеджера БД
class BoxManagerException implements Exception {
  final String message;
  BoxManagerException(this.message);

  @override
  String toString() => 'BoxManagerException: $message';
}
