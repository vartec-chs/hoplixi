import 'dart:io';

import 'package:hoplixi/core/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppPaths {
  static Future<String> get appStoragePath async =>
      await _getApplicationStoragePath();
  static Future<String> get tempPath async => await _getTempPath();
  static Future<String> get boxDbPath async => await _getBoxDbPath();
  static Future<void> clearTempDirectory() async => await _clearTempDirectory();
  static Future<Directory> get appPath async => await _getAppPath();
}

/// Получение пути к директории приложения
Future<Directory> _getAppPath() async {
  final appDir = await getApplicationDocumentsDirectory();
  final basePath = p.join(appDir.path, MainConstants.appFolderName);

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return directory;
}

/// Получение пути к директории для хранения данных приложения
Future<String> _getApplicationStoragePath() async {
  final appDir = await _getAppPath();
  final basePath = p.join(appDir.path, MainConstants.appFolderName, 'storages');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}

/// Получение пути к временной директории приложения
Future<String> _getTempPath() async {
  final tempDir = await getTemporaryDirectory();
  final basePath = p.join(tempDir.path, MainConstants.appFolderName, 'temp');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}

/// Очистка временной директории приложения
Future<void> _clearTempDirectory() async {
  try {
    final tempPath = await _getTempPath();
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

/// Получение пути к директории для хранения базы данных Box
Future<String> _getBoxDbPath() async {
  final appDir = await _getAppPath();
  final basePath = p.join(appDir.path, MainConstants.appFolderName, 'box_db');

  // Создаем директорию если её нет
  final directory = Directory(basePath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return basePath;
}
