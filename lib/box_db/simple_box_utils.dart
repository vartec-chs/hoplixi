import 'dart:io';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'simple_box.dart';
import 'simple_box_manager.dart';
import 'types.dart';
import 'crypto_box.dart';
import 'box_key_manager.dart';

/// Вспомогательные функции для работы с простыми коробками

/// Открыть коробку с автоматическим ключом шифрования
Future<SimpleBox<T>> openSimpleBoxAutoKey<T>({
  required Directory baseDir,
  required String boxName,
  required FromMapFn<T> fromMap,
  required ToMapFn<T> toMap,
  FlutterSecureStorage? secureStore,
}) async {
  final keyManager = BoxKeyManager(secureStore);
  final rawKey = await keyManager.getOrCreateKey(boxName);
  final crypto = CryptoBox.fromRawKey(rawKey);

  return SimpleBox.open(
    baseDir: baseDir,
    boxName: boxName,
    fromMap: fromMap,
    toMap: toMap,
    crypto: crypto,
  );
}

/// Открыть незашифрованную коробку
Future<SimpleBox<T>> openSimpleBoxPlain<T>({
  required Directory baseDir,
  required String boxName,
  required FromMapFn<T> fromMap,
  required ToMapFn<T> toMap,
}) async {
  return SimpleBox.open(
    baseDir: baseDir,
    boxName: boxName,
    fromMap: fromMap,
    toMap: toMap,
    crypto: null,
  );
}

/// Быстрый доступ к менеджеру коробок
Future<SimpleBoxManager> getSimpleBoxManager({
  Directory? baseDirectory,
  FlutterSecureStorage? secureStorage,
}) async {
  return SimpleBoxManager.getInstance(
    baseDirectory: baseDirectory,
    secureStorage: secureStorage,
  );
}

/// Создать и открыть временную коробку в памяти (для тестов)
Future<SimpleBox<T>> createTempBox<T>({
  required FromMapFn<T> fromMap,
  required ToMapFn<T> toMap,
  bool encrypted = false,
}) async {
  final tempDir = await Directory.systemTemp.createTemp('simple_box_');

  CryptoBox? crypto;
  if (encrypted) {
    final keyManager = BoxKeyManager(null);
    final rawKey = await keyManager.getOrCreateKey('temp_box');
    crypto = CryptoBox.fromRawKey(rawKey);
  }

  return SimpleBox.open(
    baseDir: tempDir,
    boxName: 'temp',
    fromMap: fromMap,
    toMap: toMap,
    crypto: crypto,
  );
}

/// Экспорт данных коробки в JSON файл
Future<void> exportBoxToJson<T>(
  SimpleBox<T> box,
  String filePath,
  Map<String, dynamic> Function(T) toExportMap,
) async {
  final file = File(filePath);
  final sink = file.openWrite();

  try {
    sink.writeln('[');
    bool first = true;

    await for (final item in box.getAll()) {
      if (!first) {
        sink.writeln(',');
      }
      first = false;

      final exportMap = toExportMap(item);
      sink.write('  ${_prettyJson(exportMap)}');
    }

    sink.writeln();
    sink.writeln(']');
  } finally {
    await sink.close();
  }
}

/// Импорт данных из JSON файла в коробку
Future<void> importBoxFromJson<T>(
  SimpleBox<T> box,
  String filePath,
  T Function(Map<String, dynamic>) fromImportMap,
  String Function(T) getIdFromObject,
) async {
  final file = File(filePath);

  if (!await file.exists()) {
    throw ArgumentError('Import file does not exist: $filePath');
  }

  final content = await file.readAsString();
  final List<dynamic> jsonList = json.decode(content);

  for (final item in jsonList) {
    if (item is Map<String, dynamic>) {
      final object = fromImportMap(item);
      final id = getIdFromObject(object);
      await box.put(id, object);
    }
  }
}

/// Создание красивого JSON для экспорта
String _prettyJson(Map<String, dynamic> map) {
  const encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(map);
}

/// Статистика всех коробок в директории
Future<Map<String, dynamic>> getDirectoryStats(Directory baseDir) async {
  if (!await baseDir.exists()) {
    return {'error': 'Directory does not exist'};
  }

  final boxStats = <String, Map<String, dynamic>>{};
  int totalBoxes = 0;
  int totalFiles = 0;
  int totalSize = 0;

  await for (final entity in baseDir.list(followLinks: false)) {
    if (entity is Directory) {
      final boxName = entity.path.split(Platform.pathSeparator).last;
      totalBoxes++;

      try {
        final dataFile = File('${entity.path}/data.jsonl');
        final backupFile = File('${entity.path}/data.backup.jsonl');

        int boxSize = 0;
        int boxFiles = 0;

        if (await dataFile.exists()) {
          final stat = await dataFile.stat();
          boxSize += stat.size;
          boxFiles++;
          totalFiles++;
        }

        if (await backupFile.exists()) {
          final stat = await backupFile.stat();
          boxSize += stat.size;
          boxFiles++;
          totalFiles++;
        }

        totalSize += boxSize;

        boxStats[boxName] = {
          'files': boxFiles,
          'size': boxSize,
          'hasData': await dataFile.exists(),
          'hasBackup': await backupFile.exists(),
        };
      } catch (e) {
        boxStats[boxName] = {'error': e.toString()};
      }
    }
  }

  return {
    'totalBoxes': totalBoxes,
    'totalFiles': totalFiles,
    'totalSize': totalSize,
    'boxes': boxStats,
  };
}
