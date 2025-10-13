import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/repository/service_results.dart';
import '../models/sync_metadata.dart';

/// Сервис для работы с мета-информацией синхронизации
/// Общий для всех облачных провайдеров (Dropbox, Google Drive и т.д.)
class SyncMetadataService {
  static const String _tag = 'SyncMetadataService';
  static const String _metadataFileName = 'sync_metadata.json';

  /// Вычисляет SHA-256 контрольную сумму файла
  Future<ServiceResult<String>> calculateChecksum(String filePath) async {
    try {
      logDebug('Вычисление контрольной суммы файла: $filePath', tag: _tag);

      final file = File(filePath);
      if (!await file.exists()) {
        return ServiceResult.error('Файл не найден: $filePath');
      }

      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      final checksum = digest.toString();

      logDebug(
        'Контрольная сумма вычислена: $checksum',
        tag: _tag,
        data: {'filePath': filePath, 'size': bytes.length},
      );

      return ServiceResult.success(data: checksum);
    } catch (e, stackTrace) {
      logError(
        'Ошибка вычисления контрольной суммы',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка вычисления контрольной суммы: $e');
    }
  }

  /// Проверяет контрольную сумму файла
  Future<ServiceResult<bool>> verifyChecksum(
    String filePath,
    String expectedChecksum,
  ) async {
    try {
      logDebug(
        'Проверка контрольной суммы файла: $filePath',
        tag: _tag,
        data: {'expectedChecksum': expectedChecksum},
      );

      final result = await calculateChecksum(filePath);
      if (!result.success || result.data == null) {
        return ServiceResult.error(result.message ?? 'Ошибка вычисления');
      }

      final isValid = result.data == expectedChecksum;

      if (!isValid) {
        logError(
          'Контрольная сумма не совпадает',
          tag: _tag,
          data: {'expected': expectedChecksum, 'actual': result.data},
        );
        return ServiceResult.error('Контрольная сумма файла не совпадает');
      }

      logInfo('Контрольная сумма файла корректна', tag: _tag);
      return ServiceResult.success(data: true);
    } catch (e, stackTrace) {
      logError(
        'Ошибка проверки контрольной суммы',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка проверки контрольной суммы: $e');
    }
  }

  /// Парсит имя архива и извлекает timestamp
  /// Формат: name_timestampunix.zip
  int? parseTimestampFromFileName(String fileName) {
    try {
      final nameWithoutExt = fileName.replaceAll('.zip', '');
      final parts = nameWithoutExt.split('_');

      if (parts.length < 2) {
        logError('Неверный формат имени файла: $fileName', tag: _tag);
        return null;
      }

      final timestampStr = parts.last;
      return int.tryParse(timestampStr);
    } catch (e) {
      logError(
        'Ошибка парсинга timestamp из имени файла',
        error: e,
        tag: _tag,
        data: {'fileName': fileName},
      );
      return null;
    }
  }

  /// Создает имя архива с timestamp
  /// Формат: name_timestampunix.zip
  String generateArchiveName(String baseName, int timestamp) {
    return '${baseName}_$timestamp.zip';
  }

  /// Создает метаданные архива
  Future<ServiceResult<ArchiveMetadata>> createArchiveMetadata({
    required String fileName,
    required String localFilePath,
    required String cloudPath,
  }) async {
    try {
      logDebug(
        'Создание метаданных архива: $fileName',
        tag: _tag,
        data: {'cloudPath': cloudPath},
      );

      final timestamp = parseTimestampFromFileName(fileName);
      if (timestamp == null) {
        return ServiceResult.error(
          'Не удалось извлечь timestamp из имени файла',
        );
      }

      final file = File(localFilePath);
      if (!await file.exists()) {
        return ServiceResult.error('Локальный файл не найден');
      }

      final size = await file.length();
      final checksumResult = await calculateChecksum(localFilePath);

      if (!checksumResult.success || checksumResult.data == null) {
        return ServiceResult.error(
          checksumResult.message ?? 'Ошибка вычисления контрольной суммы',
        );
      }

      final metadata = ArchiveMetadata(
        fileName: fileName,
        timestamp: timestamp,
        size: size,
        checksum: checksumResult.data!,
        uploadedAt: DateTime.now(),
        cloudPath: cloudPath,
      );

      logInfo(
        'Метаданные архива созданы успешно',
        tag: _tag,
        data: {'fileName': fileName, 'timestamp': timestamp, 'size': size},
      );

      return ServiceResult.success(data: metadata);
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания метаданных архива',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка создания метаданных: $e');
    }
  }

  /// Парсит метаданные из JSON строки
  ServiceResult<SyncMetadata> parseMetadata(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final metadata = SyncMetadata.fromJson(json);

      logDebug(
        'Метаданные успешно распарсены',
        tag: _tag,
        data: {'archivesCount': metadata.archives.length},
      );

      return ServiceResult.success(data: metadata);
    } catch (e, stackTrace) {
      logError(
        'Ошибка парсинга метаданных',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка парсинга метаданных: $e');
    }
  }

  /// Сериализует метаданные в JSON строку
  ServiceResult<String> serializeMetadata(SyncMetadata metadata) {
    try {
      final json = metadata.toJson();
      final jsonString = jsonEncode(json);

      logDebug('Метаданные успешно сериализованы', tag: _tag);

      return ServiceResult.success(data: jsonString);
    } catch (e, stackTrace) {
      logError(
        'Ошибка сериализации метаданных',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка сериализации метаданных: $e');
    }
  }

  /// Обновляет метаданные, добавляя новый архив и удаляя старые
  /// Хранит максимум 2 архива (текущий и предыдущий)
  ServiceResult<SyncMetadata> updateMetadata(
    SyncMetadata currentMetadata,
    ArchiveMetadata newArchive,
  ) {
    try {
      logDebug(
        'Обновление метаданных синхронизации',
        tag: _tag,
        data: {
          'currentArchivesCount': currentMetadata.archives.length,
          'newArchive': newArchive.fileName,
        },
      );

      // Добавляем новый архив
      var archives = [...currentMetadata.archives, newArchive];

      // Сортируем по timestamp (новые первыми)
      archives.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Оставляем только 2 последних архива
      if (archives.length > 2) {
        final toRemove = archives.sublist(2);
        logInfo(
          'Удаление старых архивов из метаданных',
          tag: _tag,
          data: {'toRemove': toRemove.map((a) => a.fileName).toList()},
        );
        archives = archives.take(2).toList();
      }

      final updatedMetadata = SyncMetadata(
        archives: archives,
        lastUpdated: DateTime.now(),
        version: currentMetadata.version,
      );

      logInfo(
        'Метаданные обновлены успешно',
        tag: _tag,
        data: {'archivesCount': archives.length},
      );

      return ServiceResult.success(data: updatedMetadata);
    } catch (e, stackTrace) {
      logError(
        'Ошибка обновления метаданных',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка обновления метаданных: $e');
    }
  }

  /// Получает самый новый архив из метаданных
  ServiceResult<ArchiveMetadata> getLatestArchive(SyncMetadata metadata) {
    try {
      if (metadata.archives.isEmpty) {
        return ServiceResult.error('Нет доступных архивов');
      }

      // Архивы уже отсортированы по timestamp при обновлении
      final latest = metadata.archives.first;

      logDebug(
        'Получен самый новый архив',
        tag: _tag,
        data: {'fileName': latest.fileName, 'timestamp': latest.timestamp},
      );

      return ServiceResult.success(data: latest);
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения последнего архива',
        error: e,
        stackTrace: stackTrace,
        tag: _tag,
      );
      return ServiceResult.error('Ошибка получения последнего архива: $e');
    }
  }

  /// Возвращает имя файла метаданных
  String get metadataFileName => _metadataFileName;
}
