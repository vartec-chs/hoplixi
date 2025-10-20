import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hoplixi/core/lib/oauth2restclient/src/exception/oauth2_exception.dart';
import 'package:hoplixi/core/lib/oauth2restclient/src/exception/oauth2_exception_type.dart';
import 'package:hoplixi/core/utils/result_pattern/common_errors.dart';
import 'package:hoplixi/core/utils/result_pattern/result.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/lib/dropbox_api/dropbox_api.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';

class ExportSuccessData {
  final String fileName;
  final int exportTime;

  ExportSuccessData({required this.fileName, required this.exportTime});
}

class CreateArchiveResult {
  final String archivePath;
  final String checksum;

  CreateArchiveResult({required this.archivePath, required this.checksum});
}

class DropboxExportService {
  static const String _logTag = 'DropboxExportService';
  final OAuth2AccountService _accountService;

  DropboxExportService(this._accountService);

  final String storagesRootCloudPath =
      '/${MainConstants.appFolderName}/storages';

  DropboxApi? _dropbox;

  /// Последовательный экспорт в Dropbox
  ///
  /// Используйте методы в следующем порядке:
  /// 1. [initializeDropboxConnection] - инициализация подключения
  /// 2. [ensureRootFolder] - создание корневой папки (опционально)
  /// 3. [ensureStorageFolder] - создание папки для хранилища
  /// 4. [createArchive] - создание архива из хранилища
  /// 5. [uploadArchiveToDropbox] - загрузка архива с отслеживанием прогресса
  ///
  /// Каждый метод возвращает [Result], проверяйте успешность перед вызовом следующего.
  ///
  /// Пример:
  /// ```dart
  /// final service = DropboxExportService(accountService);
  /// final initResult = await service.initializeDropboxConnection(clientKey, onError);
  /// if (initResult.isFailure) return;
  ///
  /// final rootResult = await service.ensureRootFolder(onError);
  /// if (rootResult.isFailure) return;
  ///
  /// final storageFolderResult = await service.ensureStorageFolder(exportPath, onError);
  /// if (storageFolderResult.isFailure) return;
  ///
  /// final archiveResult = await service.createArchive(
  ///   storagePath: pathToDb,
  ///   password: encryptionKey,
  /// );
  /// if (archiveResult.isFailure) return;
  ///
  /// final uploadResult = await service.uploadArchiveToDropbox(
  ///   exportCloudPath: exportPath,
  ///   exportArchivePath: archiveResult.dataOrNull!.archivePath,
  ///   exportTime: DateTime.now().microsecondsSinceEpoch,
  ///   onFileProgress: (percent, message) => print('$percent%: $message'),
  /// );
  /// ```

  /// Инициализирует подключение к Dropbox API
  Future<Result<void, String>> initializeDropboxConnection(
    String clientKey,
    void Function(String error)? onError,
  ) async {
    try {
      final account = _accountService.clients[clientKey];
      if (account == null) {
        final errorMsg = 'No Dropbox account found for the key';
        onError?.call(errorMsg);
        return Result.failure(errorMsg);
      }
      // Безопасно переинициализируем, если уже был инициализирован
      _dropbox = DropboxRestApi(account);
      return Result.success(null);
    } catch (e, st) {
      final errorMsg = 'Ошибка инициализации Dropbox: ${e.toString()}';
      logError(
        'Ошибка инициализации Dropbox',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );
      onError?.call(errorMsg);
      return Result.failure(errorMsg);
    }
  }

  /// Создаёт корневую папку для хранилищ
  Future<Result<void, String>> ensureRootFolder() async {
    try {
      if (_dropbox == null) {
        final errorMsg = 'Dropbox connection not initialized';
        return Result.failure(errorMsg);
      }
      await _dropbox!.createFolder(storagesRootCloudPath);
      logInfo(
        'Создана корневая папка для хранилищ',
        tag: _logTag,
        data: {'path': storagesRootCloudPath},
      );
      return Result.success(null);
    } catch (e) {
      if (e is OAuth2ExceptionF) {
        if (e.type == OAuth2ExceptionType.canceled) {
          logInfo(
            'Создание корневой папки отменено пользователем',
            tag: _logTag,
            data: {'path': storagesRootCloudPath},
          );
          return Result.success(null);
        } else if (e.type == OAuth2ExceptionType.unauthorized) {
          final errorMsg = 'Unauthorized access while creating root folder';
          logError(
            'Ошибка авторизации при создании корневой папки',
            error: e,
            tag: _logTag,
            data: {'path': storagesRootCloudPath},
          );
          return Result.failure(errorMsg);
        }
      }
      // Игнорируем ошибку 409 (папка уже существует)
      if (e.toString().contains('409') || e.toString().contains('Conflict')) {
        logInfo(
          'Корневая папка для хранилищ уже существует',
          tag: _logTag,
          data: {'path': storagesRootCloudPath},
        );
        return Result.success(null);
      } else {
        final errorMsg = 'Ошибка создания корневой папки: ${e.toString()}';
        logError(
          'Ошибка создания корневой папки',
          error: e,
          tag: _logTag,
          data: {'path': storagesRootCloudPath},
        );

        return Result.failure(errorMsg);
      }
    }
  }

  /// Создаёт папку для конкретного хранилища
  Future<Result<void, String>> ensureStorageFolder(
    String folderPath,
    void Function(String error)? onError,
  ) async {
    try {
      if (_dropbox == null) {
        final errorMsg = 'Dropbox connection not initialized';
        onError?.call(errorMsg);
        return Result.failure(errorMsg);
      }
      await _dropbox!.createFolder(folderPath);
      logInfo(
        'Создана папка для хранилища',
        tag: _logTag,
        data: {'path': folderPath},
      );
      return Result.success(null);
    } catch (e) {
      // Игнорируем ошибку 409 (папка уже существует)
      if (e.toString().contains('409') || e.toString().contains('Conflict')) {
        logInfo(
          'Папка для хранилища уже существует',
          tag: _logTag,
          data: {'path': folderPath},
        );
        return Result.success(null);
      } else {
        final errorMsg = 'Ошибка создания папки для хранилища: ${e.toString()}';
        logError(
          'Ошибка создания папки для хранилища',
          error: e,
          tag: _logTag,
          data: {'path': folderPath},
        );
        onError?.call(errorMsg);
        return Result.failure(errorMsg);
      }
    }
  }

  /// Загружает архив в Dropbox с отслеживанием прогресса файла
  Future<Result<DropboxFile, String>> uploadArchiveToDropbox({
    required String exportCloudPath,
    required String exportArchivePath,
    required int exportTime,
    void Function(String progress, String message)? onFileProgress,
    void Function(String error)? onError,
  }) async {
    try {
      if (_dropbox == null) {
        final errorMsg = 'Dropbox connection not initialized';
        onError?.call(errorMsg);
        return Result.failure(errorMsg);
      }
      final stream = File(exportArchivePath).openRead();

      final uploadResult = await _dropbox!.upload(
        '$exportCloudPath/$exportTime.zip',
        stream,
        onProgress: (uploaded, total) {
          if (total != null && total > 0) {
            final uploadedMB = (uploaded / 1024 / 1024).toStringAsFixed(2);
            final totalMB = (total / 1024 / 1024).toStringAsFixed(2);
            final percent = ((uploaded / total) * 100).toStringAsFixed(1);

            onFileProgress?.call(
              percent,
              'Загрузка: $uploadedMB МБ / $totalMB МБ ($percent%)',
            );
          }
        },
      );

      if (uploadResult.name.isEmpty) {
        final errorMsg = 'Failed to upload archive to Dropbox';
        onError?.call(errorMsg);
        return Result.failure(errorMsg);
      }

      logInfo(
        'Архив успешно загружен в Dropbox',
        tag: _logTag,
        data: {
          'remotePath': '$exportCloudPath/$exportTime.zip',
          'fileName': uploadResult.name,
        },
      );

      return Result.success(uploadResult);
    } catch (e, st) {
      final errorMsg = 'Ошибка при загрузке архива: ${e.toString()}';
      logError(
        'Ошибка при загрузке архива',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );
      onError?.call(errorMsg);
      return Result.failure(errorMsg);
    }
  }

  /// Экспортирует хранилище в архив
  ///
  /// [storagePath] - полный путь к папке хранилища (где лежит .${MainConstants.dbExtension} файл)
  /// [destinationPath] - путь, куда сохранить архив (опционально)
  /// [password] - пароль для защиты архива (опционально)
  ///
  /// Возвращает [Result] с путём к созданному архиву и контрольной суммой
  Future<Result<CreateArchiveResult, String>> createArchive({
    required String storagePath,
    String? destinationPath,
    String? password,
  }) async {
    const String operation = 'exportStorage';

    try {
      logInfo(
        'Начало экспорта хранилища',
        tag: 'StorageExportService',
        data: {'storagePath': storagePath},
      );

      // Получаем директорию хранилища
      final storageDir = Directory(storagePath);
      if (!await storageDir.exists()) {
        logError(
          'Директория хранилища не найдена',
          tag: 'StorageExportService',
          data: {'storageDir': storageDir.path},
        );
        return Result.failure('Директория хранилища не найдена');
      }

      final storageName = p.basename(storageDir.path);

      final downloadDir = await getDownloadsDirectory();

      String archivePath;

      if (downloadDir != null) {
        archivePath =
            destinationPath ??
            p.join(
              downloadDir.path,
              '${storageName}_${DateTime.now().millisecondsSinceEpoch}.zip',
            );
      } else {
        archivePath =
            destinationPath ??
            p.join(
              storageDir.parent.path,
              '${storageName}_${DateTime.now().millisecondsSinceEpoch}.zip',
            );
      }

      logDebug(
        'Создание архива',
        tag: 'StorageExportService',
        data: {
          'archivePath': archivePath,
          'storageDir': storageDir.path,
          'withPassword': password != null && password.isNotEmpty,
        },
      );

      // Создаём архив
      final archive = Archive();

      // найти файл .${MainConstants.dbExtension} в директории хранилища
      final dbFiles = storageDir
          .listSync(recursive: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.${MainConstants.dbExtension}'))
          .toList();

      if (dbFiles.isEmpty) {
        logError(
          'Файл базы данных не найден',
          tag: 'StorageExportService',
          data: {'storageDir': storageDir.path},
        );
        return Result.failure('Файл базы данных не найден');
      }

      // Добавляем файл .${MainConstants.dbExtension}
      final storageFileBytes = await dbFiles.first.readAsBytes();
      final relativePath = p.relative(
        dbFiles.first.path,
        from: storageDir.parent.path,
      );
      archive.addFile(
        ArchiveFile(relativePath, storageFileBytes.length, storageFileBytes),
      );

      logDebug(
        'Добавлен файл базы данных в архив',
        tag: 'StorageExportService',
        data: {'file': storagePath, 'archivePath': relativePath},
      );

      // Добавляем все остальные файлы и подпапки из директории хранилища
      logInfo(
        'Начало обхода директории хранилища',
        tag: 'StorageExportService',
        data: {
          'storageDir': storageDir.path,
          'basePath': storageDir.parent.path,
        },
      );

      await _addDirectoryToArchive(archive, storageDir, storageDir.parent.path);

      // Кодируем архив в ZIP
      final zipEncoder = password != null && password.isNotEmpty
          ? ZipEncoder(password: password)
          : ZipEncoder();
      final zipData = zipEncoder.encode(archive);

      // Записываем архив в файл
      await File(archivePath).writeAsBytes(zipData);

      // Проверяем, что архив создан
      final archiveOutputFile = File(archivePath);
      if (!await archiveOutputFile.exists()) {
        logError(
          'Не удалось создать архив',
          tag: 'StorageExportService',
          data: {'archivePath': archivePath},
        );
        return Result.failure('Не удалось создать архив');
      }

      final archiveSize = await archiveOutputFile.length();
      logInfo(
        'Архив успешно создан',
        tag: 'StorageExportService',
        data: {'archivePath': archivePath, 'size': archiveSize},
      );

      final checksum = await calculateFileChecksum(archiveOutputFile);

      return Result.success(
        CreateArchiveResult(archivePath: archivePath, checksum: checksum),
      );
    } catch (e, st) {
      logError(
        'Ошибка при экспорте хранилища',
        error: e,
        stackTrace: st,
        tag: 'StorageExportService',
        data: {'operation': operation, 'storagePath': storagePath},
      );
      return Result.failure('Ошибка при экспорте хранилища: ${e.toString()}');
    }
  }

  /// Рекурсивно добавляет файлы из директории в архив
  Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath,
  ) async {
    try {
      logInfo(
        'Обработка директории',
        tag: 'StorageExportService',
        data: {'directory': dir.path, 'basePath': basePath},
      );

      final entities = await dir.list(recursive: false).toList();

      logInfo(
        'Найдено элементов в директории',
        tag: 'StorageExportService',
        data: {'directory': dir.path, 'count': entities.length},
      );

      for (final entity in entities) {
        logDebug(
          'Обработка элемента',
          tag: 'StorageExportService',
          data: {
            'path': entity.path,
            'type': entity is File ? 'File' : 'Directory',
          },
        );

        if (entity is File) {
          // Пропускаем .hxdb файл (он добавляется отдельно)
          if (entity.path.endsWith('.${MainConstants.dbExtension}')) {
            logDebug(
              'Пропущен .hxdb файл',
              tag: 'StorageExportService',
              data: {'file': entity.path},
            );
            continue;
          }

          // Сохраняем относительный путь от basePath
          final relativePath = p.relative(entity.path, from: basePath);
          final fileBytes = await entity.readAsBytes();

          archive.addFile(
            ArchiveFile(relativePath, fileBytes.length, fileBytes),
          );

          logInfo(
            'Добавлен файл в архив',
            tag: 'StorageExportService',
            data: {'file': entity.path, 'archivePath': relativePath},
          );
        } else if (entity is Directory) {
          // Рекурсивно обрабатываем подпапки
          logInfo(
            'Начало рекурсивного обхода подпапки',
            tag: 'StorageExportService',
            data: {'directory': entity.path},
          );
          await _addDirectoryToArchive(archive, entity, basePath);
        }
      }

      logInfo(
        'Завершена обработка директории',
        tag: 'StorageExportService',
        data: {'directory': dir.path},
      );
    } catch (e, st) {
      logError(
        'Ошибка при добавлении директории в архив',
        error: e,
        stackTrace: st,
        tag: 'StorageExportService',
        data: {'directory': dir.path},
      );
    }
  }

  Future<String> calculateFileChecksum(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
