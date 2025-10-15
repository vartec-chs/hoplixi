import 'dart:async';
import 'dart:io';

import 'package:hoplixi/core/lib/oauth2restclient/src/exception/oauth2_exception.dart';
import 'package:hoplixi/core/lib/oauth2restclient/src/exception/oauth2_exception_type.dart';
import 'package:path/path.dart' as p;

import 'package:archive/archive_io.dart';
import 'package:hoplixi/core/app_paths.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/lib/dropbox_api/dropbox_api.dart';
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

class ImportDropboxService {
  CloudSyncDataService get _cloudSyncDataService => CloudSyncDataService();

  final OAuth2AccountService _accountService;
  final String tag = 'ImportDropboxService';
  final String storagesRoot = '/${MainConstants.appFolderName}/storages';

  ImportDropboxService(this._accountService);

  DropboxApi? _dropbox;

  /// Импорт базы данных из Dropbox
  ///
  /// [metadata] - метаданные базы данных для синхронизации
  /// [pathToDbFolder] - путь к папке с БД
  /// [encryptionKeyArchive] - опциональный ключ шифрования архива
  Future<ServiceResult<void>> importFromDropbox({
    required DatabaseMetaForSync metadata,
    required String pathToDbFolder,
    required String clientKey,
    String? encryptionKeyArchive,
    void Function(double progress, String message)? onProgress,
    void Function(double progress, String message)? onFileProgress,
    void Function(String error)? onError,
  }) async {
    final account = _accountService.clients[clientKey];
    if (account == null) {
      final errorMsg = 'No Dropbox account found for the key';
      onError?.call(errorMsg);
      return ServiceResult.failure(errorMsg);
    }
    _dropbox = _dropbox ?? DropboxRestApi(account);

    onProgress?.call(0.1, 'Проверка папок в облаке...');

    // Создаём корневую папку для хранилищ (игнорируем если уже существует)
    try {
      await _dropbox!.createFolder(storagesRoot);
      // Если выполнилось без исключения — считаем это ненормальным
      final errorMsg =
          'Ожидался ответ 409 (папка уже существует), но createFolder завершился успешно';
      logError(
        'Непредвиденное создание папки',
        tag: tag,
        data: {'path': storagesRoot},
      );
      onError?.call(errorMsg);
      return ServiceResult.failure(errorMsg);
    } catch (e, st) {
      if (e.toString().contains('409') || e.toString().contains('Conflict')) {
        // нормальный путь — получили 409
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
          onError?.call(e.message ?? e.toString());
          return ServiceResult.failure(e.message ?? e.toString());
        }
        // любые другие ошибки — логируем / реройзим, в зависимости от логики
        logError(
          'Ошибка при создании корневой папки',
          error: e,
          stackTrace: st,
          tag: tag,
          data: {'path': storagesRoot},
        );
        onError?.call(e.toString());
        rethrow;
      }
    }

    onProgress?.call(0.15, 'Создание папки для хранилища...');

    final storeFolderName =
        '${metadata.name.replaceAll(' ', '_')}_${metadata.id}';
    final exportCloudPath = '$storagesRoot/$storeFolderName';

    // Создаём папку для конкретного хранилища (игнорируем если уже существует)
    try {
      await _dropbox!.createFolder(exportCloudPath);
      // Если выполнилось без исключения — считаем это ненормальным
      final errorMsg =
          'Ожидался ответ 409 (папка уже существует), но createFolder завершился успешно';
      logError(
        'Непредвиденное создание папки',
        tag: tag,
        data: {'path': exportCloudPath},
      );
      onError?.call(errorMsg);
      return ServiceResult.failure(errorMsg);
    } catch (e, st) {
      if (e.toString().contains('409') || e.toString().contains('Conflict')) {
        // нормальный путь — получили 409
        logInfo(
          'Папка для хранилища уже существует (409)',
          tag: tag,
          data: {'path': exportCloudPath},
        );
      } else {
        // любые другие ошибки — логируем / реройзим, в зависимости от логики
        logError(
          'Ошибка при создании папки для хранилища',
          error: e,
          stackTrace: st,
          tag: tag,
          data: {'path': exportCloudPath},
        );
        onError?.call(e.toString());
        rethrow;
      }
    }

    onProgress?.call(0.2, 'Получение списка файлов в облаке...');

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
      onError?.call(errorMsg);
      return ServiceResult.failure(errorMsg);
    }

    // if entries 0
    if (cloudFiles.entries.isEmpty) {
      final errorMsg = 'В облаке нет файлов для импорта';
      logWarning(
        'Нет файлов для импорта',
        tag: tag,
        data: {'path': exportCloudPath},
      );
      onError?.call(errorMsg);
      return ServiceResult.failure(errorMsg);
    }

    // file naming 1760473744499894.zip timestamp

    // Ищем самый новый файл по имени
    cloudFiles.entries.sort((a, b) => b.name.compareTo(a.name));
    final DateTime timestampLastExporting = DateTime.fromMicrosecondsSinceEpoch(
      int.parse(cloudFiles.entries.first.name.split('_').last.split('.').first),
    );

    final exportingEntry = await _cloudSyncDataService.getItem(metadata.id);

    if (!exportingEntry.success) {
      final errorMsg =
          'Ошибка при получении данных синхронизации из локальной БД: ${exportingEntry.message}';
      logError(
        'Ошибка при поиске записи CloudSyncData',
        tag: tag,
        data: {'name': metadata.name},
      );
      onError?.call(errorMsg);
      return ServiceResult.failure(errorMsg);
    }

    if (exportingEntry.data != null &&
        exportingEntry.data!.exportedAt != null &&
        !timestampLastExporting.isAfter(exportingEntry.data!.exportedAt!)) {
      final msg =
          'В облаке нет новых версий базы данных для импорта (последняя локальная: ${exportingEntry.data!.exportedAt}, последняя в облаке: $timestampLastExporting)';
      logInfo(
        'Нет новых версий для импорта',
        tag: tag,
        data: {
          'localLast': exportingEntry.data!.exportedAt.toString(),
          'cloudLast': timestampLastExporting.toString(),
        },
      );
      onError?.call(msg);
      return ServiceResult.failure(msg);
    }

    onProgress?.call(0.25, 'Скачивание файла из облака...');

    // Скачиваем файл
    final storagesDir = await AppPaths.appStoragePath;
    final fileName =
        '${metadata.name.replaceAll(' ', '_')}_${metadata.id}_download.zip';

    final downloadPath = p.join(storagesDir, fileName);
    Stream<List<int>> fileStream;
    try {
      fileStream = await _dropbox!.download(
        '${exportCloudPath}/${cloudFiles.entries.first.name}',
      );
      logInfo(
        'Файл успешно скачан из облака',
        tag: tag,
        data: {'path': downloadPath},
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
      onError?.call(errorMsg);
      return ServiceResult.failure(errorMsg);
    }

    // Сохраняем файл локально
    final file = File(downloadPath);
    final sink = file.openWrite();
    int downloadedBytes = 0;
    final completer = Completer<void>();
    fileStream.listen(
      (data) {
        downloadedBytes += data.length;
        sink.add(data);
        onFileProgress?.call(
          0.25 + (downloadedBytes / (1024 * 1024)) * 0.5,
          'Скачивание файла из облака... ${(downloadedBytes / (1024 * 1024)).toStringAsFixed(2)} МБ',
        );
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
        'Файл успешно сохранён локально',
        tag: tag,
        data: {'path': downloadPath},
      );
    } catch (e, st) {
      final errorMsg = 'Ошибка при сохранении файла локально: $e';
      logError(
        'Ошибка при сохранении файла',
        error: e,
        stackTrace: st,
        tag: tag,
        data: {'path': downloadPath},
      );
      onError?.call(errorMsg);
      return ServiceResult.failure(errorMsg);
    }

    onProgress?.call(0.8, 'Распаковка архива...');

    // Распаковываем архив
    try {
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      logInfo(
        'Начало распаковки архива',
        tag: tag,
        data: {'path': pathToDbFolder, 'filesInArchive': archive.length},
      );

      // Находим корневую папку в архиве (первый сегмент пути)
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

      for (final archiveFile in archive) {
        // Пропускаем служебные файлы macOS
        if (archiveFile.name.startsWith('__MACOSX') ||
            archiveFile.name.contains('.DS_Store')) {
          logDebug(
            'Пропуск служебного файла',
            tag: tag,
            data: {'name': archiveFile.name},
          );
          continue;
        }

        // Получаем путь без префикса корневой папки архива
        String relativePath = archiveFile.name;

        // Убираем корневую папку из архива, чтобы распаковать содержимое
        // напрямую в pathToDbFolder
        if (rootFolderInArchive != null &&
            relativePath.startsWith('$rootFolderInArchive/')) {
          relativePath = relativePath.substring(rootFolderInArchive.length + 1);
        }

        // Добавляем префикс "imported" к корневой директории
        relativePath = '${DateTime.now().microsecondsSinceEpoch} $relativePath';

        // Пропускаем пустые пути и сами папки (они создадутся автоматически)
        if (relativePath.isEmpty || relativePath.endsWith('/')) {
          continue;
        }

        final filePath = p.join(storagesDir, relativePath);

        logDebug(
          'Распаковка файла из архива',
          tag: 'xxxtracting',
          data: {
            'archivePath': archiveFile.name,
            'relativePath': relativePath,
            'outputPath': filePath,
            'size': archiveFile.size,
          },
        );

        if (archiveFile.isFile) {
          final outFile = File(filePath);

          // Создаём родительскую директорию если нужно
          final parentDir = outFile.parent;
          if (!await parentDir.exists()) {
            await parentDir.create(recursive: true);
            logDebug(
              'Создана родительская директория',
              tag: tag,
              data: {'path': parentDir.path},
            );
          }

          await outFile.writeAsBytes(archiveFile.content as List<int>);
          logInfo(
            'Файл из архива успешно распакован',
            tag: tag,
            data: {
              'archivePath': archiveFile.name,
              'relativePath': relativePath,
              'outputPath': filePath,
              'size': archiveFile.size,
            },
          );
        }
      }

      logInfo(
        'Архив успешно распакован',
        tag: tag,
        data: {'path': pathToDbFolder, 'filesExtracted': archive.length},
      );

      // Удаляем скачанный архив после успешной распаковки
      try {
        await file.delete();
        logDebug(
          'Скачанный архив удалён',
          tag: tag,
          data: {'path': downloadPath},
        );
      } catch (e) {
        logWarning(
          'Не удалось удалить временный архив (не критично)',
          tag: tag,
          data: {'path': downloadPath, 'error': e.toString()},
        );
      }
    } catch (e, st) {
      final errorMsg = 'Ошибка при распаковке архива: $e';
      logError(
        'Ошибка при распаковке архива',
        error: e,
        stackTrace: st,
        tag: tag,
        data: {'path': pathToDbFolder},
      );
      onError?.call(errorMsg);
      return ServiceResult.failure(errorMsg);
    }

    onProgress?.call(1.0, 'Импорт завершён');
    return ServiceResult.success();
  }
}
