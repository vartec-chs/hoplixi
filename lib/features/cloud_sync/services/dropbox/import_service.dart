import 'dart:async';
import 'dart:io';

import 'package:hoplixi/core/lib/oauth2restclient/src/exception/oauth2_exception.dart';
import 'package:hoplixi/core/utils/result_pattern/result.dart';
import 'package:path/path.dart' as p;

import 'package:archive/archive_io.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/lib/dropbox_api/dropbox_api.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

class CloudVersionInfo {
  final DateTime timestamp;
  final String fileName;
  final String cloudPath;
  final bool isNewer;
  final int? fileSize;

  CloudVersionInfo({
    required this.timestamp,
    required this.fileName,
    required this.cloudPath,
    required this.isNewer,
    this.fileSize,
  });
}

class ImportDropboxService {
  CloudSyncDataService get _cloudSyncDataService => CloudSyncDataService();

  final OAuth2AccountService _accountService;
  final String tag = 'ImportDropboxService';
  final String storagesRoot = '/${MainConstants.appFolderName}/storages';

  ImportDropboxService(this._accountService);

  DropboxApi? _dropbox;

  /// Проверяет наличие новой версии базы данных в облаке
  ///
  /// [metadata] - метаданные базы данных для синхронизации
  /// [clientKey] - ключ клиента OAuth2
  ///
  /// Возвращает [CloudVersionInfo] если найдена более новая версия, иначе null
  Future<Result<CloudVersionInfo?, String>> checkForNewVersion({
    required DatabaseMetaForSync metadata,
    required String clientKey,
  }) async {
    final account = _accountService.clients[clientKey];
    if (account == null) {
      final errorMsg = 'No Dropbox account found for the key';
      return Result.failure(errorMsg);
    }
    _dropbox = _dropbox ?? DropboxRestApi(account);

    // Создаём корневую папку для хранилищ (игнорируем если уже существует)
    try {
      await _dropbox!.createFolder(storagesRoot);
      final errorMsg =
          'Ожидался ответ 409 (папка уже существует), но createFolder завершился успешно';
      logError(
        'Непредвиденное создание папки',
        tag: tag,
        data: {'path': storagesRoot},
      );
      return Result.failure(errorMsg);
    } catch (e, st) {
      if (e.toString().contains('409') || e.toString().contains('Conflict')) {
        logInfo(
          'Корневая папка для хранилищ уже существует (409)',
          tag: tag,
          data: {'path': storagesRoot},
        );
      } else {
        if (e is OAuth2ExceptionF) {
          logError(
            'OAuth2Exception при создании корневой папки',
            error: e,
            stackTrace: st,
            tag: tag,
            data: {'path': storagesRoot, 'type': e.type.toString()},
          );
          return Result.failure(e.message ?? e.toString());
        }
        logError(
          'Ошибка при создании корневой папки',
          error: e,
          stackTrace: st,
          tag: tag,
          data: {'path': storagesRoot},
        );
        rethrow;
      }
    }

    final storeFolderName =
        '${metadata.name.replaceAll(' ', '_')}_${metadata.id}';
    final exportCloudPath = '$storagesRoot/$storeFolderName';

    // Создаём папку для конкретного хранилища (игнорируем если уже существует)
    try {
      await _dropbox!.createFolder(exportCloudPath);
      final errorMsg =
          'Ожидался ответ 409 (папка уже существует), но createFolder завершился успешно';
      logError(
        'Непредвиденное создание папки',
        tag: tag,
        data: {'path': exportCloudPath},
      );
      return Result.failure(errorMsg);
    } catch (e, st) {
      if (e.toString().contains('409') || e.toString().contains('Conflict')) {
        logInfo(
          'Папка для хранилища уже существует (409)',
          tag: tag,
          data: {'path': exportCloudPath},
        );
      } else {
        logError(
          'Ошибка при создании папки для хранилища',
          error: e,
          stackTrace: st,
          tag: tag,
          data: {'path': exportCloudPath},
        );
        rethrow;
      }
    }

    // Получаем список файлов в папке хранилища
    DropboxFolderContents cloudFiles;
    try {
      cloudFiles = await _dropbox!.listFolder(exportCloudPath);
      logInfo(
        'Список файлов в облаке получен',
        tag: tag,
        data: {'path': exportCloudPath, 'fileCount': cloudFiles.entries.length},
      );
    } catch (e, st) {
      final errorMsg = 'Ошибка при получении списка файлов из облака: $e';
      logError(
        'Ошибка при listFiles',
        error: e,
        stackTrace: st,
        tag: tag,
        data: {'path': exportCloudPath},
      );
      return Result.failure(errorMsg);
    }

    // Если нет файлов в облаке
    if (cloudFiles.entries.isEmpty) {
      logInfo(
        'В облаке нет файлов для импорта',
        tag: tag,
        data: {'path': exportCloudPath},
      );
      return Result.success(null);
    }

    // Ищем самый новый файл по имени (формат: timestamp.zip)
    cloudFiles.entries.sort((a, b) => b.name.compareTo(a.name));
    final latestFile = cloudFiles.entries.first;
    final DateTime timestampLastExporting = DateTime.fromMicrosecondsSinceEpoch(
      int.parse(latestFile.name.split('_').last.split('.').first),
    );

    // Получаем информацию о последнем экспорте из локальной БД
    final exportingEntry = await _cloudSyncDataService.getItem(metadata.id);

    if (!exportingEntry.success) {
      final errorMsg =
          'Ошибка при получении данных синхронизации из локальной БД: ${exportingEntry.message}';
      logError(
        'Ошибка при поиске записи CloudSyncData',
        tag: tag,
        data: {'name': metadata.name},
      );
      return Result.failure(errorMsg);
    }

    // Проверяем, есть ли более новая версия в облаке
    final bool isNewer =
        exportingEntry.data?.exportedAt == null ||
        timestampLastExporting.isAfter(exportingEntry.data!.exportedAt!);

    if (!isNewer) {
      logInfo(
        'В облаке нет новых версий для импорта',
        tag: tag,
        data: {
          'localLast': exportingEntry.data?.exportedAt.toString(),
          'cloudLast': timestampLastExporting.toString(),
        },
      );
      return Result.success(null);
    }

    // Формируем информацию о новой версии
    final versionInfo = CloudVersionInfo(
      timestamp: timestampLastExporting,
      fileName: latestFile.name,
      cloudPath: '$exportCloudPath/${latestFile.name}',
      isNewer: true,
      fileSize: latestFile.size,
    );

    logInfo(
      'Найдена новая версия в облаке',
      tag: tag,
      data: {
        'cloudTimestamp': timestampLastExporting.toString(),
        'fileName': latestFile.name,
        'size': latestFile.size,
      },
    );

    return Result.success(versionInfo);
  }

  /// Скачивает архив с базой данных из облака
  ///
  /// [versionInfo] - информация о версии для скачивания
  /// [metadata] - метаданные базы данных
  /// [onProgress] - callback для отслеживания прогресса скачивания
  ///
  /// Возвращает путь к скачанному файлу
  Future<Result<String, String>> downloadArchive({
    required CloudVersionInfo versionInfo,
    required DatabaseMetaForSync metadata,
    void Function(double progress, String message)? onProgress,
  }) async {
    onProgress?.call(0.0, 'Начало скачивания...');

    final storagesDir = await AppPaths.appStoragePath;
    final fileName =
        '${metadata.name.replaceAll(' ', '_')}_${metadata.id}_download.zip';
    final downloadPath = p.join(storagesDir, fileName);

    // Скачиваем файл
    Stream<List<int>> fileStream;
    try {
      fileStream = await _dropbox!.download(versionInfo.cloudPath);
      logInfo(
        'Начало скачивания файла из облака',
        tag: tag,
        data: {'cloudPath': versionInfo.cloudPath, 'localPath': downloadPath},
      );
    } catch (e, st) {
      final errorMsg = 'Ошибка при скачивании файла из облака: $e';
      logError(
        'Ошибка при downloadFile',
        error: e,
        stackTrace: st,
        tag: tag,
        data: {'path': downloadPath},
      );
      return Result.failure(errorMsg);
    }

    // Сохраняем файл локально с отслеживанием прогресса
    final file = File(downloadPath);
    final sink = file.openWrite();
    int downloadedBytes = 0;
    final totalBytes = versionInfo.fileSize ?? 0;
    final completer = Completer<void>();

    fileStream.listen(
      (data) {
        downloadedBytes += data.length;
        sink.add(data);

        // Вычисляем прогресс
        final progress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
        final mbDownloaded = (downloadedBytes / (1024 * 1024)).toStringAsFixed(
          2,
        );
        final mbTotal = totalBytes > 0
            ? (totalBytes / (1024 * 1024)).toStringAsFixed(2)
            : '?';

        onProgress?.call(progress, 'Скачано $mbDownloaded МБ из $mbTotal МБ');
      },
      onDone: () async {
        await sink.flush();
        await sink.close();
        completer.complete();
      },
      onError: (e) {
        completer.completeError(e);
      },
      cancelOnError: true,
    );

    try {
      await completer.future;
      logInfo(
        'Файл успешно скачан и сохранён',
        tag: tag,
        data: {'path': downloadPath, 'size': downloadedBytes},
      );
      onProgress?.call(1.0, 'Скачивание завершено');
      return Result.success(downloadPath);
    } catch (e, st) {
      final errorMsg = 'Ошибка при сохранении файла локально: $e';
      logError(
        'Ошибка при сохранении файла',
        error: e,
        stackTrace: st,
        tag: tag,
        data: {'path': downloadPath},
      );
      return Result.failure(errorMsg);
    }
  }

  /// Заменяет текущую базу данных на импортированную из архива
  ///
  /// [downloadPath] - путь к скачанному архиву
  /// [metadata] - метаданные базы данных
  /// [onProgress] - callback для отслеживания прогресса
  ///
  /// Возвращает путь к распакованной папке с базой данных
  Future<Result<String, String>> replaceDatabase({
    required String downloadPath,
    required DatabaseMetaForSync metadata,
    void Function(double progress, String message)? onProgress,
  }) async {
    onProgress?.call(0.0, 'Начало распаковки архива...');

    final file = File(downloadPath);
    if (!await file.exists()) {
      return Result.failure('Скачанный файл не найден: $downloadPath');
    }

    try {
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      logInfo(
        'Начало распаковки архива',
        tag: tag,
        data: {'filesInArchive': archive.length},
      );

      // Находим корневую папку в архиве
      String? rootFolderInArchive;
      for (final archiveFile in archive) {
        if (archiveFile.name.contains('/')) {
          rootFolderInArchive = archiveFile.name.split('/').first;
          break;
        }
      }

      logInfo(
        'Найдена корневая папка в архиве',
        tag: tag,
        data: {'rootFolder': rootFolderInArchive ?? 'не найдена'},
      );

      // Создаём новую папку с меткой времени импорта
      final storagesDir = await AppPaths.appStoragePath;
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final importedFolderName =
          '$timestamp ${metadata.name.replaceAll(' ', '_')}_${metadata.id}';
      final importedFolderPath = p.join(storagesDir, importedFolderName);

      int filesExtracted = 0;
      final totalFiles = archive.where((f) => f.isFile).length;

      for (final archiveFile in archive) {
        // Пропускаем служебные файлы
        if (archiveFile.name.startsWith('__MACOSX') ||
            archiveFile.name.contains('.DS_Store')) {
          continue;
        }

        // Получаем путь без префикса корневой папки архива
        String relativePath = archiveFile.name;
        if (rootFolderInArchive != null &&
            relativePath.startsWith('$rootFolderInArchive/')) {
          relativePath = relativePath.substring(rootFolderInArchive.length + 1);
        }

        // Пропускаем пустые пути и папки
        if (relativePath.isEmpty || relativePath.endsWith('/')) {
          continue;
        }

        final filePath = p.join(importedFolderPath, relativePath);

        if (archiveFile.isFile) {
          final outFile = File(filePath);

          // Создаём родительскую директорию
          final parentDir = outFile.parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
          }

          await outFile.writeAsBytes(archiveFile.content as List<int>);
          filesExtracted++;

          // Обновляем прогресс
          final progress = filesExtracted / totalFiles;
          onProgress?.call(
            progress,
            'Распаковано файлов: $filesExtracted из $totalFiles',
          );

          logDebug(
            'Файл распакован',
            tag: tag,
            data: {'path': filePath, 'size': archiveFile.size},
          );
        }
      }

      logInfo(
        'Архив успешно распакован',
        tag: tag,
        data: {'path': importedFolderPath, 'filesExtracted': filesExtracted},
      );

      // Удаляем скачанный архив
      try {
        await file.delete();
        logDebug('Временный архив удалён', tag: tag);
      } catch (e) {
        logWarning(
          'Не удалось удалить временный архив (не критично)',
          tag: tag,
          data: {'error': e.toString()},
        );
      }

      onProgress?.call(1.0, 'Распаковка завершена');
      return Result.success(importedFolderPath);
    } catch (e, st) {
      final errorMsg = 'Ошибка при распаковке архива: $e';
      logError(
        'Ошибка при распаковке архива',
        error: e,
        stackTrace: st,
        tag: tag,
      );
      return Result.failure(errorMsg);
    }
  }
}
