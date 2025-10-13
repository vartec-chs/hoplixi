import 'dart:io';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/core/lib/dropbox_api/dropbox_api.dart';
import 'package:hoplixi/hoplixi_store/repository/service_results.dart';
import '../models/sync_metadata.dart';
import 'sync_metadata_service.dart';

/// Сервис для синхронизации архивов хранилищ с Dropbox
/// Управляет загрузкой/выгрузкой архивов и мета-информацией
class DropboxService {
  static const String _tag = 'DropboxService';

  static const String _rootPath = '/${MainConstants.appFolderName}';
  static const String _storagesPath = '$_rootPath/storages';

  final OAuth2RestClient? _client;
  late SyncMetadataService _metadataService;
  late final DropboxApi? _dropboxApi;

  DropboxService(this._client) {
    _dropboxApi = _client != null ? DropboxRestApi(_client) : null;
    if (_dropboxApi == null) {
      logWarning('Dropbox API not initialized', tag: _tag);
    }
    _metadataService = SyncMetadataService();
  }

  // ==================== ИНИЦИАЛИЗАЦИЯ ====================

  /// Проверяет подключение к Dropbox и создает необходимые папки
  Future<ServiceResult<bool>> initialize() async {
    try {
      if (_dropboxApi == null) {
        return ServiceResult.error('Dropbox API не инициализирован');
      }

      logInfo('Инициализация Dropbox сервиса', tag: _tag);

      // Проверяем подключение
      // final folders = await _dropboxApi.listFolder('/');
      // if (folders != null) {
      //   logInfo(
      //     'Подключение к Dropbox установлено',
      //     tag: _tag,
      //     data: {'rootFolder': folders.entries.length},
      //   );
      // } else {
      //   return ServiceResult.error('Не удалось получить список папок');
      // }

      logInfo('Проверка и создание необходимых папок', tag: _tag);

      // Создаем корневую папку если не существует
      try {
        await _dropboxApi.createFolder(_rootPath);
        logInfo('Создана корневая папка: $_rootPath', tag: _tag);
      } catch (e) {
        // Папка может уже существовать - это нормально
        logDebug('Корневая папка уже существует', tag: _tag);
      }

      // Создаем папку для хранилищ
      try {
        await _dropboxApi.createFolder(_storagesPath);
        logInfo('Создана папка для хранилищ: $_storagesPath', tag: _tag);
      } catch (e) {
        logDebug('Папка для хранилищ уже существует', tag: _tag);
      }

      return ServiceResult.success(
        data: true,
        message: 'Dropbox инициализирован успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка инициализации Dropbox',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка инициализации: $e');
    }
  }

  // ==================== РАБОТА С МЕТАДАННЫМИ ====================

  /// Загружает метаданные синхронизации из облака
  Future<ServiceResult<SyncMetadata>> _downloadMetadata() async {
    try {
      if (_dropboxApi == null) {
        return ServiceResult.error('Dropbox API не инициализирован');
      }

      final metadataPath =
          '$_storagesPath/${_metadataService.metadataFileName}';

      logDebug('Загрузка метаданных из: $metadataPath', tag: _tag);

      try {
        final stream = await _dropboxApi.download(metadataPath);
        final bytes = await stream.expand((chunk) => chunk).toList();
        final jsonString = String.fromCharCodes(bytes);

        final parseResult = _metadataService.parseMetadata(jsonString);
        if (!parseResult.success || parseResult.data == null) {
          return ServiceResult.error(
            parseResult.message ?? 'Ошибка парсинга метаданных',
          );
        }

        logInfo('Метаданные успешно загружены из облака', tag: _tag);
        return ServiceResult.success(data: parseResult.data!);
      } catch (e) {
        // Файл метаданных не существует - создаем пустые
        logDebug('Файл метаданных не найден, создаем новые', tag: _tag);
        return ServiceResult.success(data: emptyMetadata());
      }
    } catch (e, stackTrace) {
      logError(
        'Ошибка загрузки метаданных',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка загрузки метаданных: $e');
    }
  }

  /// Загружает метаданные в облако
  Future<ServiceResult<bool>> _uploadMetadata(SyncMetadata metadata) async {
    try {
      if (_dropboxApi == null) {
        return ServiceResult.error('Dropbox API не инициализирован');
      }

      final serializeResult = _metadataService.serializeMetadata(metadata);
      if (!serializeResult.success || serializeResult.data == null) {
        return ServiceResult.error(
          serializeResult.message ?? 'Ошибка сериализации метаданных',
        );
      }

      final metadataPath =
          '$_storagesPath/${_metadataService.metadataFileName}';
      final bytes = serializeResult.data!.codeUnits;
      final stream = Stream.value(bytes);

      logDebug('Загрузка метаданных в: $metadataPath', tag: _tag);

      await _dropboxApi.upload(
        metadataPath,
        stream,
        mode: 'overwrite',
        autorename: false,
      );

      logInfo('Метаданные успешно загружены в облако', tag: _tag);
      return ServiceResult.success(data: true);
    } catch (e, stackTrace) {
      logError(
        'Ошибка загрузки метаданных в облако',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка загрузки метаданных: $e');
    }
  }

  // ==================== EXPORT ====================

  /// Экспортирует архив в Dropbox
  /// Хранит только 2 последних архива, остальные удаляет
  Future<ServiceResult<String>> export(String archivePath) async {
    try {
      if (_dropboxApi == null) {
        return ServiceResult.error('Dropbox API не инициализирован');
      }

      logInfo('Начало экспорта архива: $archivePath', tag: _tag);

      // Проверяем существование файла
      final file = File(archivePath);
      if (!await file.exists()) {
        return ServiceResult.error('Файл архива не найден: $archivePath');
      }

      final fileName = archivePath.split(Platform.pathSeparator).last;
      final cloudPath = '$_storagesPath/$fileName';

      // Создаем метаданные архива
      final archiveMetadataResult = await _metadataService
          .createArchiveMetadata(
            fileName: fileName,
            localFilePath: archivePath,
            cloudPath: cloudPath,
          );

      if (!archiveMetadataResult.success ||
          archiveMetadataResult.data == null) {
        return ServiceResult.error(
          archiveMetadataResult.message ?? 'Ошибка создания метаданных архива',
        );
      }

      // Загружаем текущие метаданные
      final currentMetadataResult = await _downloadMetadata();
      if (!currentMetadataResult.success ||
          currentMetadataResult.data == null) {
        return ServiceResult.error(
          currentMetadataResult.message ?? 'Ошибка загрузки метаданных',
        );
      }

      final currentMetadata = currentMetadataResult.data!;
      final newArchiveMetadata = archiveMetadataResult.data!;

      // Загружаем архив в облако
      logInfo('Загрузка архива в облако: $cloudPath', tag: _tag);

      final fileBytes = await file.readAsBytes();
      final stream = Stream.value(fileBytes);

      await _dropboxApi.upload(
        cloudPath,
        stream,
        mode: 'overwrite',
        autorename: false,
      );

      logInfo('Архив успешно загружен в облако', tag: _tag);

      // Обновляем метаданные
      final updatedMetadataResult = _metadataService.updateMetadata(
        currentMetadata,
        newArchiveMetadata,
      );

      if (!updatedMetadataResult.success ||
          updatedMetadataResult.data == null) {
        return ServiceResult.error(
          updatedMetadataResult.message ?? 'Ошибка обновления метаданных',
        );
      }

      final updatedMetadata = updatedMetadataResult.data!;

      // Удаляем старые архивы из облака (оставляем только 2)
      await _cleanupOldArchives(currentMetadata, updatedMetadata);

      // Загружаем обновленные метаданные
      final uploadMetadataResult = await _uploadMetadata(updatedMetadata);
      if (!uploadMetadataResult.success) {
        return ServiceResult.error(
          uploadMetadataResult.message ?? 'Ошибка сохранения метаданных',
        );
      }

      logInfo(
        'Экспорт завершен успешно',
        tag: _tag,
        data: {'fileName': fileName, 'cloudPath': cloudPath},
      );

      return ServiceResult.success(
        data: cloudPath,
        message: 'Архив успешно экспортирован',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка экспорта архива',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка экспорта: $e');
    }
  }

  /// Удаляет старые архивы из облака
  Future<void> _cleanupOldArchives(
    SyncMetadata oldMetadata,
    SyncMetadata newMetadata,
  ) async {
    try {
      if (_dropboxApi == null) return;

      // Находим архивы, которых нет в новых метаданных
      final oldPaths = oldMetadata.archives.map((a) => a.cloudPath).toSet();
      final newPaths = newMetadata.archives.map((a) => a.cloudPath).toSet();
      final toDelete = oldPaths.difference(newPaths);

      if (toDelete.isEmpty) {
        logDebug('Нет архивов для удаления', tag: _tag);
        return;
      }

      logInfo(
        'Удаление старых архивов',
        tag: _tag,
        data: {'count': toDelete.length, 'paths': toDelete.toList()},
      );

      for (final path in toDelete) {
        try {
          await _dropboxApi.delete(path);
          logDebug('Удален архив: $path', tag: _tag);
        } catch (e) {
          logError('Ошибка удаления архива: $path', error: e, tag: _tag);
          // Продолжаем удаление остальных файлов
        }
      }
    } catch (e, stackTrace) {
      logError(
        'Ошибка очистки старых архивов',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
    }
  }

  // ==================== IMPORT ====================

  /// Импортирует самый новый архив из Dropbox
  /// Проверяет контрольную сумму перед возвратом
  Future<ServiceResult<String>> import(String destinationPath) async {
    try {
      if (_dropboxApi == null) {
        return ServiceResult.error('Dropbox API не инициализирован');
      }

      logInfo('Начало импорта архива в: $destinationPath', tag: _tag);

      // Загружаем метаданные
      final metadataResult = await _downloadMetadata();
      if (!metadataResult.success || metadataResult.data == null) {
        return ServiceResult.error(
          metadataResult.message ?? 'Ошибка загрузки метаданных',
        );
      }

      final metadata = metadataResult.data!;

      // Получаем самый новый архив
      final latestArchiveResult = _metadataService.getLatestArchive(metadata);
      if (!latestArchiveResult.success || latestArchiveResult.data == null) {
        return ServiceResult.error(
          latestArchiveResult.message ?? 'Нет доступных архивов для импорта',
        );
      }

      final latestArchive = latestArchiveResult.data!;

      logInfo(
        'Загрузка архива из облака',
        tag: _tag,
        data: {
          'fileName': latestArchive.fileName,
          'cloudPath': latestArchive.cloudPath,
        },
      );

      // Скачиваем архив
      final stream = await _dropboxApi.download(latestArchive.cloudPath);
      final bytes = await stream.expand((chunk) => chunk).toList();

      // Формируем путь для сохранения
      final destinationDir = Directory(destinationPath);
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      final filePath =
          '$destinationPath${Platform.pathSeparator}${latestArchive.fileName}';
      final file = File(filePath);

      // Сохраняем файл
      await file.writeAsBytes(bytes);
      logInfo('Архив сохранен локально: $filePath', tag: _tag);

      // Проверяем контрольную сумму
      final verifyResult = await _metadataService.verifyChecksum(
        filePath,
        latestArchive.checksum,
      );

      if (!verifyResult.success || verifyResult.data != true) {
        // Удаляем поврежденный файл
        await file.delete();
        return ServiceResult.error(
          'Контрольная сумма не совпадает. Файл поврежден.',
        );
      }

      logInfo(
        'Импорт завершен успешно',
        tag: _tag,
        data: {'fileName': latestArchive.fileName, 'size': bytes.length},
      );

      return ServiceResult.success(
        data: filePath,
        message: 'Архив успешно импортирован',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка импорта архива',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка импорта: $e');
    }
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Получает список всех архивов в облаке
  Future<ServiceResult<List<ArchiveMetadata>>> listArchives() async {
    try {
      if (_dropboxApi == null) {
        return ServiceResult.error('Dropbox API не инициализирован');
      }

      logDebug('Получение списка архивов из облака', tag: _tag);

      final metadataResult = await _downloadMetadata();
      if (!metadataResult.success || metadataResult.data == null) {
        return ServiceResult.error(
          metadataResult.message ?? 'Ошибка загрузки метаданных',
        );
      }

      final archives = metadataResult.data!.archives;

      logInfo(
        'Список архивов получен',
        tag: _tag,
        data: {'count': archives.length},
      );

      return ServiceResult.success(data: archives);
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения списка архивов',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка получения списка архивов: $e');
    }
  }

  /// Проверяет, инициализирован ли сервис
  bool get isInitialized => _dropboxApi != null;
}
