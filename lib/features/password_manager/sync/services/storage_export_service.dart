import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/hoplixi_store/services/service_results.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Сервис для экспорта и импорта хранилищ
class StorageExportService {
  /// Экспортирует хранилище в архив
  ///
  /// [storagePath] - полный путь к файлу хранилища (.${MainConstants.dbExtension})
  /// [destinationPath] - путь, куда сохранить архив (опционально)
  /// [password] - пароль для защиты архива (опционально)
  ///
  /// Возвращает [ServiceResult] с путём к созданному архиву
  Future<ServiceResult<String>> exportStorage({
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

      // Проверяем существование файла хранилища
      final storageFile = File(storagePath);
      if (!await storageFile.exists()) {
        logError(
          'Файл хранилища не найден',
          tag: 'StorageExportService',
          data: {'storagePath': storagePath},
        );
        return ServiceResult.error('Файл хранилища не найден');
      }

      // Получаем директорию хранилища (родительская директория файла .${MainConstants.dbExtension})
      final storageDir = Directory(p.dirname(storagePath));
      if (!await storageDir.exists()) {
        logError(
          'Директория хранилища не найдена',
          tag: 'StorageExportService',
          data: {'storageDir': storageDir.path},
        );
        return ServiceResult.error('Директория хранилища не найдена');
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

      // Добавляем файл .hxdb
      final storageFileBytes = await storageFile.readAsBytes();
      final relativePath = p.relative(
        storagePath,
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
        return ServiceResult.error('Не удалось создать архив');
      }

      final archiveSize = await archiveOutputFile.length();
      logInfo(
        'Архив успешно создан',
        tag: 'StorageExportService',
        data: {'archivePath': archivePath, 'size': archiveSize},
      );

      return ServiceResult.success(
        data: archivePath,
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
      return ServiceResult.error(
        'Ошибка при экспорте хранилища: ${e.toString()}',
      );
    }
  }

  /// Импортирует хранилище из архива
  ///
  /// [archivePath] - путь к архиву с хранилищем
  /// [destinationDir] - директория, куда распаковать хранилище
  /// [password] - пароль для расшифровки архива (если был установлен при экспорте)
  ///
  /// Возвращает [ServiceResult] с путём к импортированному хранилищу
  Future<ServiceResult<String>> importStorage({
    required String archivePath,
    required String destinationDir,
    String? password,
  }) async {
    const String operation = 'importStorage';

    try {
      logInfo(
        'Начало импорта хранилища',
        tag: 'StorageExportService',
        data: {'archivePath': archivePath, 'destinationDir': destinationDir},
      );

      // Проверяем существование архива
      final archiveFile = File(archivePath);
      if (!await archiveFile.exists()) {
        logError(
          'Архив не найден',
          tag: 'StorageExportService',
          data: {'archivePath': archivePath},
        );
        return ServiceResult.error('Архив не найден');
      }

      // Создаём директорию назначения, если не существует
      final destDir = Directory(destinationDir);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
        logDebug(
          'Создана директория назначения',
          tag: 'StorageExportService',
          data: {'destinationDir': destinationDir},
        );
      }

      // Читаем архив
      final bytes = await archiveFile.readAsBytes();
      Archive archive;

      try {
        archive = password != null && password.isNotEmpty
            ? ZipDecoder().decodeBytes(bytes, password: password)
            : ZipDecoder().decodeBytes(bytes);
      } catch (e) {
        logError(
          'Ошибка при распаковке архива (возможно, неверный пароль)',
          error: e,
          tag: 'StorageExportService',
          data: {'archivePath': archivePath},
        );
        return ServiceResult.error(
          'Не удалось распаковать архив. Проверьте правильность пароля.',
        );
      }

      // Ищем корневую папку хранилища в архиве (папка, содержащая . файл)
      String? storageRootFolder;
      for (final file in archive) {
        if (file.name.endsWith('.${MainConstants.dbExtension}')) {
          final segments = p.split(file.name);
          if (segments.isNotEmpty) {
            storageRootFolder = segments.first;
            break;
          }
        }
      }

      if (storageRootFolder == null) {
        logError(
          'В архиве не найдена корректная структура хранилища',
          tag: 'StorageExportService',
          data: {'archivePath': archivePath},
        );
        return ServiceResult.error(
          'В архиве не найдена корректная структура хранилища',
        );
      }

      // Проверяем, не существует ли уже такая папка
      String finalStorageName = storageRootFolder;
      var targetStorageDir = p.join(destinationDir, finalStorageName);

      if (await Directory(targetStorageDir).exists()) {
        // Добавляем timestamp к имени
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        finalStorageName = '${storageRootFolder}_$timestamp';
        targetStorageDir = p.join(destinationDir, finalStorageName);

        logInfo(
          'Хранилище с таким именем уже существует, используется новое имя',
          tag: 'StorageExportService',
          data: {
            'originalName': storageRootFolder,
            'newName': finalStorageName,
          },
        );
      }

      final finalStoragePath = p.join(
        targetStorageDir,
        '$finalStorageName.${MainConstants.dbExtension}',
      );

      logDebug(
        'Распаковка архива',
        tag: 'StorageExportService',
        data: {'targetDir': targetStorageDir},
      );

      // Распаковываем все файлы
      int filesExtracted = 0;
      for (final file in archive) {
        if (file.isFile) {
          final filename = file.name;

          // Заменяем имя корневой папки на новое (если было переименование)
          String targetPath;
          if (storageRootFolder != finalStorageName) {
            final segments = p.split(filename);
            if (segments.isNotEmpty && segments.first == storageRootFolder) {
              segments[0] = finalStorageName;
              targetPath = p.join(destinationDir, p.joinAll(segments));
            } else {
              targetPath = p.join(destinationDir, filename);
            }
          } else {
            targetPath = p.join(destinationDir, filename);
          }

          // Создаём директории
          final targetFile = File(targetPath);
          await targetFile.parent.create(recursive: true);

          // Записываем файл
          await targetFile.writeAsBytes(file.content as List<int>);
          filesExtracted++;

          logDebug(
            'Файл распакован',
            tag: 'StorageExportService',
            data: {'file': targetPath},
          );
        }
      }

      logInfo(
        'Импорт завершён успешно',
        tag: 'StorageExportService',
        data: {
          'storagePath': finalStoragePath,
          'filesExtracted': filesExtracted,
        },
      );

      return ServiceResult.success(
        data: finalStoragePath,
        message: 'Хранилище успешно импортировано',
      );
    } catch (e, st) {
      logError(
        'Ошибка при импорте хранилища',
        error: e,
        stackTrace: st,
        tag: 'StorageExportService',
        data: {'operation': operation, 'archivePath': archivePath},
      );
      return ServiceResult.error(
        'Ошибка при импорте хранилища: ${e.toString()}',
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
}
