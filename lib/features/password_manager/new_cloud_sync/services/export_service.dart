import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/lib/dropbox_api/dropbox_api.dart';
import 'package:hoplixi/core/model/cloud_sync_data.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

class ServiceResult<T> {
  final bool success;
  final String? message;
  final T? data;

  const ServiceResult._(this.success, this.message, this.data);

  factory ServiceResult.success({T? data, String? message}) {
    return ServiceResult._(true, message, data);
  }

  factory ServiceResult.failure(String message) {
    return ServiceResult._(false, message, null);
  }
}

class ExportDropboxService {
  CloudSyncDataService get _cloudSyncDataService => CloudSyncDataService();

  final OAuth2AccountService _accountService;
  final String tag = 'ExportDropboxService';
  final String storagesRoot = '/${MainConstants.appFolderName}/storages';

  ExportDropboxService(this._accountService);

  late final DropboxApi _dropbox;

  Future<ServiceResult<String>> exportToDropbox(
    DatabaseMetaForSync metadata,
    String clientKey,
    String pathToDbFolder,
    String? encryptionKeyArchive,
  ) async {
    final account = _accountService.clients[clientKey];
    if (account == null) {
      return ServiceResult.failure('No Dropbox account found for the key');
    }
    _dropbox = DropboxRestApi(account);

    await _dropbox.createFolder(storagesRoot);

    final storeFolderName =
        '${metadata.name.replaceAll(' ', '_')}_${metadata.id}';
    final exportCloudPath = '$storagesRoot/$storeFolderName';

    await _dropbox.createFolder(exportCloudPath);

    final exportTime = DateTime.now().microsecondsSinceEpoch;

    final exportPathDir = await AppPaths.exportStoragesPath;
    final exportPath = p.join(exportPathDir, '$exportTime.zip');

    final archiveResult = await createArchive(
      storagePath: pathToDbFolder,
      destinationPath: exportPath,
      password: encryptionKeyArchive,
    );

    if (!archiveResult.success || archiveResult.data == null) {
      return ServiceResult.failure(
        'Failed to create archive: ${archiveResult.message}',
      );
    }

    final CloudSyncDataItem newItem = CloudSyncDataItem(
      id: metadata.id,
      name: metadata.name,
      path: pathToDbFolder,
      checksum: archiveResult.data?.$2 ?? '',
      exportedAt: DateTime.fromMicrosecondsSinceEpoch(exportTime),
    );

    final stream = Stream.value(await File(exportPath).readAsBytes());

    final uploadResult = await _dropbox.upload(
      '$exportCloudPath$exportTime.zip',
      stream,
    );

    if (uploadResult.name.isEmpty) {
      return ServiceResult.failure('Failed to upload archive to Dropbox');
    }

    await _cloudSyncDataService.updateOrCreate(newItem);

    logInfo(
      'Cloud sync item exported to Dropbox',
      tag: tag,
      data: {'id': metadata.id},
    );

    return ServiceResult.success(data: uploadResult.name);
  }

  /// Экспортирует хранилище в архив
  ///
  /// [storagePath] - полный путь к папке хранилища (где лежит .${MainConstants.dbExtension} файл)
  /// [destinationPath] - путь, куда сохранить архив (опционально)
  /// [password] - пароль для защиты архива (опционально)
  ///
  /// Возвращает [ServiceResult] с путём к созданному архиву
  Future<ServiceResult<(String archivePath, String checksum)>> createArchive({
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
        return ServiceResult.failure('Директория хранилища не найдена');
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
        return ServiceResult.failure('Файл базы данных не найден');
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
        return ServiceResult.failure('Не удалось создать архив');
      }

      final archiveSize = await archiveOutputFile.length();
      logInfo(
        'Архив успешно создан',
        tag: 'StorageExportService',
        data: {'archivePath': archivePath, 'size': archiveSize},
      );

      final checksum = await calculateFileChecksum(archiveOutputFile);

      return ServiceResult.success(
        data: (archivePath, checksum),
        message: 'Хранилище успешно экспортировано',
      );
    } catch (e, st) {
      logError(
        'Ошибка при экспорте хранилища',
        error: e,
        stackTrace: st,
        tag: 'StorageExportService',
        data: {'operation': operation, 'storagePath': storagePath},
      );
      return ServiceResult.failure(
        'Ошибка при экспорте хранилища: ${e.toString()}',
      );
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

  /// Вычисляет контрольную сумму файла с использованием SHA-256
  Future<String> calculateFileChecksum(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
