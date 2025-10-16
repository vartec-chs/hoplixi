import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

/// Менеджер для работы с файловой системой
class StorageManager {
  final String dbPath;
  late final File _dataFile;
  late final File _indexFile;
  late final File _metaFile;
  late final Directory _backupDir;

  StorageManager(this.dbPath) {
    _dataFile = File(path.join(dbPath, 'data.jsonl'));
    _indexFile = File(path.join(dbPath, 'index.json'));
    _metaFile = File(path.join(dbPath, 'meta.json'));
    _backupDir = Directory(path.join(dbPath, 'backup'));
  }

  /// Инициализировать структуру БД
  Future<void> initialize() async {
    final dir = Directory(dbPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    if (!await _dataFile.exists()) {
      await _dataFile.create();
    }

    if (!await _indexFile.exists()) {
      await _indexFile.writeAsString('{}');
    }

    if (!await _metaFile.exists()) {
      await _writeMeta({'created': DateTime.now().toIso8601String()});
    }

    if (!await _backupDir.exists()) {
      await _backupDir.create();
    }
  }

  /// Создать резервную копию
  Future<void> createBackup() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupSubDir = Directory(path.join(_backupDir.path, '$timestamp'));

    try {
      // Удалить директорию, если она уже существует
      if (await backupSubDir.exists()) {
        await backupSubDir.delete(recursive: true);
      }

      await backupSubDir.create(recursive: true);

      if (await _dataFile.exists()) {
        final backupData = File(path.join(backupSubDir.path, 'data.jsonl'));
        // Используем writeAsBytes вместо copy, чтобы избежать ошибок
        final bytes = await _dataFile.readAsBytes();
        await backupData.writeAsBytes(bytes);
      }

      if (await _indexFile.exists()) {
        final backupIndex = File(path.join(backupSubDir.path, 'index.json'));
        final bytes = await _indexFile.readAsBytes();
        await backupIndex.writeAsBytes(bytes);
      }

      if (await _metaFile.exists()) {
        final backupMeta = File(path.join(backupSubDir.path, 'meta.json'));
        final bytes = await _metaFile.readAsBytes();
        await backupMeta.writeAsBytes(bytes);
      }

      // Сохранить только последние 5 бэкапов
      await _cleanOldBackups(5);
    } catch (e) {
      // Если произошла ошибка при создании бэкапа, просто логируем её
      // и продолжаем работу (бэкап не критичен)
      print('Warning: Failed to create backup: $e');
    }
  }

  /// Восстановить из последней резервной копии
  Future<bool> restoreFromBackup() async {
    final backups = await _getBackupDirectories();
    if (backups.isEmpty) {
      return false;
    }

    final latestBackup = backups.last;
    final backupData = File(path.join(latestBackup.path, 'data.jsonl'));
    final backupIndex = File(path.join(latestBackup.path, 'index.json'));
    final backupMeta = File(path.join(latestBackup.path, 'meta.json'));

    if (await backupData.exists()) {
      await backupData.copy(_dataFile.path);
    }

    if (await backupIndex.exists()) {
      await backupIndex.copy(_indexFile.path);
    }

    if (await backupMeta.exists()) {
      await backupMeta.copy(_metaFile.path);
    }

    return true;
  }

  /// Удалить старые бэкапы, оставить только последние N
  Future<void> _cleanOldBackups(int keepCount) async {
    final backups = await _getBackupDirectories();
    if (backups.length <= keepCount) {
      return;
    }

    final toDelete = backups.take(backups.length - keepCount);
    for (final dir in toDelete) {
      await dir.delete(recursive: true);
    }
  }

  /// Получить список директорий бэкапов, отсортированных по времени
  Future<List<Directory>> _getBackupDirectories() async {
    if (!await _backupDir.exists()) {
      return [];
    }

    final entries = await _backupDir.list().toList();
    final dirs = entries.whereType<Directory>().toList();

    // Сортировка по имени (timestamp)
    dirs.sort((a, b) {
      final aName = path.basename(a.path);
      final bName = path.basename(b.path);
      final aTime = int.tryParse(aName) ?? 0;
      final bTime = int.tryParse(bName) ?? 0;
      return aTime.compareTo(bTime);
    });

    return dirs;
  }

  /// Добавить строку в data.jsonl
  Future<int> appendData(Map<String, dynamic> data) async {
    final line = jsonEncode(data);
    final lineNumber = await getLineCount();

    final sink = _dataFile.openWrite(mode: FileMode.append);
    sink.writeln(line);
    await sink.flush();
    await sink.close();

    return lineNumber;
  }

  /// Прочитать строку по номеру
  Future<Map<String, dynamic>?> readLine(int lineNumber) async {
    if (!await _dataFile.exists()) {
      return null;
    }

    final lines = _dataFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    var currentLine = 0;
    await for (final line in lines) {
      if (currentLine == lineNumber) {
        if (line.trim().isEmpty) {
          return null;
        }
        return jsonDecode(line) as Map<String, dynamic>;
      }
      currentLine++;
    }

    return null;
  }

  /// Получить количество строк в файле
  Future<int> getLineCount() async {
    if (!await _dataFile.exists()) {
      return 0;
    }

    var count = 0;
    final lines = _dataFile
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (line.trim().isNotEmpty) {
        count++;
      }
    }

    return count;
  }

  /// Прочитать индекс
  Future<Map<String, dynamic>> readIndex() async {
    if (!await _indexFile.exists()) {
      return {};
    }

    final content = await _indexFile.readAsString();
    if (content.trim().isEmpty) {
      return {};
    }

    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Записать индекс
  Future<void> writeIndex(Map<String, dynamic> index) async {
    final content = jsonEncode(index);
    await _indexFile.writeAsString(content);
  }

  /// Прочитать метаданные
  Future<Map<String, dynamic>> readMeta() async {
    if (!await _metaFile.exists()) {
      return {};
    }

    final content = await _metaFile.readAsString();
    if (content.trim().isEmpty) {
      return {};
    }

    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Записать метаданные
  Future<void> _writeMeta(Map<String, dynamic> meta) async {
    final content = jsonEncode(meta);
    await _metaFile.writeAsString(content);
  }

  /// Обновить метаданные
  Future<void> updateMeta(Map<String, dynamic> updates) async {
    final meta = await readMeta();
    meta.addAll(updates);
    await _writeMeta(meta);
  }

  /// Проверить целостность БД
  Future<bool> verifyIntegrity() async {
    try {
      // Проверяем существование файлов
      if (!await _dataFile.exists() || !await _indexFile.exists()) {
        return false;
      }

      // Проверяем, что индекс можно прочитать
      await readIndex();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Компактифицировать БД (удалить помеченные как удаленные записи)
  Future<void> compact(Map<String, dynamic> validIndex) async {
    final tempFile = File(path.join(dbPath, 'data.jsonl.tmp'));
    final sink = tempFile.openWrite();

    final newIndex = <String, dynamic>{};
    var newLineNumber = 0;

    // Читаем только валидные записи и записываем в новый файл
    for (final entry in validIndex.entries) {
      final indexData = entry.value as Map<String, dynamic>;
      if (indexData['deleted'] == true) {
        continue;
      }

      final lineNumber = indexData['line'] as int;
      final data = await readLine(lineNumber);

      if (data != null) {
        sink.writeln(jsonEncode(data));
        // Сохраняем timestamp из старого индекса
        newIndex[entry.key] = {
          'line': newLineNumber,
          'deleted': false,
          'timestamp': indexData['timestamp'], // Сохраняем временную метку
        };
        newLineNumber++;
      }
    }

    await sink.flush();
    await sink.close();

    // Заменяем старый файл новым
    await _dataFile.delete();
    await tempFile.rename(_dataFile.path);

    // Обновляем индекс
    await writeIndex(newIndex);

    // Очищаем список удалённых строк в meta
    await updateMeta({'deleted_lines': []});
  }
}
