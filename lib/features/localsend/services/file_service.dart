import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/index.dart';

/// Сервис для работы с файлами: выбор, сохранение, чтение и обработка передач
class FileService {
  static const String _logTag = 'FileService';
  static const int _chunkSize = 64 * 1024; // 64KB

  /// Выбирает файлы для отправки
  Future<List<File>> pickFiles() async {
    try {
      logInfo('Выбор файлов для отправки', tag: _logTag);

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        logDebug('Файлы не выбраны', tag: _logTag);
        return [];
      }

      final files = <File>[];
      for (final file in result.files) {
        if (file.path != null) {
          files.add(File(file.path!));
        }
      }

      logInfo('Выбрано файлов: ${files.length}', tag: _logTag);
      return files;
    } catch (e) {
      logError('Ошибка выбора файлов', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Создает FileTransfer для отправки файла
  Future<FileTransfer> createFileTransferForSending({
    required File file,
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final fileStat = await file.stat();
      final fileName = file.path.split('/').last;
      final fileHash = await _calculateFileHash(file);

      logInfo(
        'Создание FileTransfer для отправки',
        tag: _logTag,
        data: {'fileName': fileName, 'fileSize': fileStat.size},
      );

      return FileTransfer.sending(
        senderId: senderId,
        receiverId: receiverId,
        fileName: fileName,
        fileSize: fileStat.size,
        filePath: file.path,
        fileHash: fileHash,
        metadata: {
          'originalPath': file.path,
          'lastModified': fileStat.modified.millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      logError('Ошибка создания FileTransfer', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Создает FileTransfer для получения файла
  Future<FileTransfer> createFileTransferForReceiving({
    required String senderId,
    required String receiverId,
    required String fileName,
    required int fileSize,
    String? fileHash,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final savePath = await _getSaveFilePath(fileName);

      logInfo(
        'Создание FileTransfer для получения',
        tag: _logTag,
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
          'savePath': savePath,
        },
      );

      return FileTransfer.receiving(
        senderId: senderId,
        receiverId: receiverId,
        fileName: fileName,
        fileSize: fileSize,
        savePath: savePath,
        fileHash: fileHash,
        metadata: metadata,
      );
    } catch (e) {
      logError(
        'Ошибка создания FileTransfer для получения',
        error: e,
        tag: _logTag,
      );
      rethrow;
    }
  }

  /// Читает файл по чанкам для отправки
  Stream<FileChunk> readFileAsChunks(FileTransfer transfer) async* {
    try {
      final file = File(transfer.filePath!);
      final randomAccessFile = await file.open(mode: FileMode.read);

      try {
        int chunkIndex = 0;
        final totalChunks = (transfer.fileSize / _chunkSize).ceil();

        logInfo(
          'Начало чтения файла по чанкам',
          tag: _logTag,
          data: {'fileName': transfer.fileName, 'totalChunks': totalChunks},
        );

        while (true) {
          final chunkData = await randomAccessFile.read(_chunkSize);
          if (chunkData.isEmpty) break;

          final checksum = _calculateChunkChecksum(chunkData);

          final chunk = FileChunk(
            transferId: transfer.id,
            chunkIndex: chunkIndex,
            totalChunks: totalChunks,
            data: Uint8List.fromList(chunkData),
            size: chunkData.length,
            checksum: checksum,
          );

          yield chunk;
          chunkIndex++;

          logDebug('Отправлен чанк $chunkIndex/$totalChunks', tag: _logTag);
        }

        logInfo('Чтение файла завершено', tag: _logTag);
      } finally {
        await randomAccessFile.close();
      }
    } catch (e) {
      logError('Ошибка чтения файла по чанкам', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Записывает чанк файла при получении
  Future<void> writeFileChunk(FileTransfer transfer, FileChunk chunk) async {
    try {
      final file = File(transfer.filePath!);

      // Создаем директорию если не существует
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final randomAccessFile = await file.open(mode: FileMode.writeOnlyAppend);

      try {
        // Проверяем контрольную сумму чанка
        if (chunk.checksum != null) {
          final actualChecksum = _calculateChunkChecksum(chunk.data);
          if (actualChecksum != chunk.checksum) {
            throw Exception(
              'Неверная контрольная сумма чанка ${chunk.chunkIndex}',
            );
          }
        }

        await randomAccessFile.writeFrom(chunk.data);
        await randomAccessFile.flush();

        logDebug(
          'Записан чанк ${chunk.chunkIndex + 1}/${chunk.totalChunks}',
          tag: _logTag,
        );
      } finally {
        await randomAccessFile.close();
      }
    } catch (e) {
      logError('Ошибка записи чанка файла', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Проверяет целостность полученного файла
  Future<bool> verifyFileIntegrity(FileTransfer transfer) async {
    try {
      if (transfer.fileHash == null) {
        logWarning('Нет хеша для проверки целостности файла', tag: _logTag);
        return true; // Считаем файл валидным если хеша нет
      }

      final file = File(transfer.filePath!);
      if (!await file.exists()) {
        return false;
      }

      final fileStat = await file.stat();
      if (fileStat.size != transfer.fileSize) {
        logError(
          'Размер файла не совпадает',
          tag: _logTag,
          data: {'expected': transfer.fileSize, 'actual': fileStat.size},
        );
        return false;
      }

      final actualHash = await _calculateFileHash(file);
      final isValid = actualHash == transfer.fileHash;

      logInfo(
        'Проверка целостности файла',
        tag: _logTag,
        data: {'fileName': transfer.fileName, 'isValid': isValid},
      );

      return isValid;
    } catch (e) {
      logError('Ошибка проверки целостности файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Получает директорию Downloads пользователя
  Future<Directory> getDownloadsDirectory() async {
    try {
      if (Platform.isAndroid) {
        final directory = await getExternalStorageDirectory();
        return Directory('${directory!.path}/Download');
      } else if (Platform.isWindows) {
        final home = Platform.environment['USERPROFILE'];
        return Directory('$home\\Downloads');
      } else if (Platform.isMacOS || Platform.isLinux) {
        final home = Platform.environment['HOME'];
        return Directory('$home/Downloads');
      } else {
        // Fallback для других платформ
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      logError('Ошибка получения директории Downloads', error: e, tag: _logTag);
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Удаляет файл
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        logInfo('Файл удален: $filePath', tag: _logTag);
      }
    } catch (e) {
      logError('Ошибка удаления файла: $filePath', error: e, tag: _logTag);
    }
  }

  /// Получает информацию о файле
  Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final fileName = file.path.split('/').last;

      return {
        'name': fileName,
        'path': filePath,
        'size': stat.size,
        'modified': stat.modified.millisecondsSinceEpoch,
        'type': stat.type.toString(),
      };
    } catch (e) {
      logError(
        'Ошибка получения информации о файле: $filePath',
        error: e,
        tag: _logTag,
      );
      return null;
    }
  }

  /// Форматирует размер файла для отображения
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Вычисляет SHA-256 хеш файла
  Future<String> _calculateFileHash(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      logError('Ошибка вычисления хеша файла', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Вычисляет контрольную сумму чанка
  String _calculateChunkChecksum(Uint8List data) {
    final digest = md5.convert(data);
    return digest.toString();
  }

  /// Получает путь для сохранения файла
  Future<String> _getSaveFilePath(String fileName) async {
    try {
      final downloadsDir = await getDownloadsDirectory();

      // Обеспечиваем существование директории
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      var savePath = '${downloadsDir.path}/$fileName';
      var counter = 1;

      // Если файл уже существует, добавляем счетчик
      while (await File(savePath).exists()) {
        final extension = fileName.contains('.')
            ? '.${fileName.split('.').last}'
            : '';
        final baseName = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;

        savePath = '${downloadsDir.path}/$baseName ($counter)$extension';
        counter++;
      }

      return savePath;
    } catch (e) {
      logError('Ошибка получения пути сохранения', error: e, tag: _logTag);
      rethrow;
    }
  }
}
