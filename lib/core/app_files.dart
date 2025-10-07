import 'dart:io';

import 'package:hoplixi/core/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<String> getApplicationPath() async {
  final appDir = await getApplicationDocumentsDirectory();
  final basePath = p.join(appDir.path, MainConstants.appFolderName, 'storages');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}

Future<String> getTempPath() async {
  final tempDir = await getTemporaryDirectory() ;
  final basePath = p.join(tempDir.path, MainConstants.appFolderName, 'temp');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}

Future<void> clearTempDirectory() async {
  try {
    final tempPath = await getTempPath();
    final tempDir = Directory(tempPath);

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
      await tempDir.create(recursive: true);
      logInfo('Временная директория очищена', tag: 'AppFiles');
    }
  } catch (e) {
    logError('Ошибка при очистке временной директории: $e', tag: 'AppFiles');
  }
}

Future<String> getBoxDbPath() async {
  final appDir = await getApplicationDocumentsDirectory();
  final basePath = p.join(appDir.path, MainConstants.appFolderName, 'box_db');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}
