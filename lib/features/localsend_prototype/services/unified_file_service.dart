import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend_prototype/models/index.dart';

/// Внутреннее состояние передачи для resume функциональности
class _TransferState {
  final String transferId;
  final String filePath;
  final int fileSize;
  final String fileHash;
  final int completedChunks;
  final Set<int> receivedChunks;
  final DateTime lastActivity;

  _TransferState({
    required this.transferId,
    required this.filePath,
    required this.fileSize,
    required this.fileHash,
    this.completedChunks = 0,
    Set<int>? receivedChunks,
    DateTime? lastActivity,
  }) : receivedChunks = receivedChunks ?? <int>{},
       lastActivity = lastActivity ?? DateTime.now();

  _TransferState copyWith({
    int? completedChunks,
    Set<int>? receivedChunks,
    DateTime? lastActivity,
  }) {
    return _TransferState(
      transferId: transferId,
      filePath: filePath,
      fileSize: fileSize,
      fileHash: fileHash,
      completedChunks: completedChunks ?? this.completedChunks,
      receivedChunks: receivedChunks ?? this.receivedChunks,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  /// Конвертирует в JSON для сохранения состояния
  Map<String, dynamic> toJson() {
    return {
      'transferId': transferId,
      'filePath': filePath,
      'fileSize': fileSize,
      'fileHash': fileHash,
      'completedChunks': completedChunks,
      'receivedChunks': receivedChunks.toList(),
      'lastActivity': lastActivity.millisecondsSinceEpoch,
    };
  }

  /// Создает из JSON
  static _TransferState fromJson(Map<String, dynamic> json) {
    return _TransferState(
      transferId: json['transferId'],
      filePath: json['filePath'],
      fileSize: json['fileSize'],
      fileHash: json['fileHash'],
      completedChunks: json['completedChunks'] ?? 0,
      receivedChunks: Set<int>.from(json['receivedChunks'] ?? []),
      lastActivity: DateTime.fromMillisecondsSinceEpoch(json['lastActivity']),
    );
  }
}

/// Объединенный сервис для работы с файлами LocalSend
/// Включает функционал выбора файлов, chunked transfer с resume и проверки целостности
class UnifiedFileService {
  static const String _logTag = 'UnifiedFileService';

  // Конфигурация chunk размеров для разных операций
  static const int _defaultChunkSize = 16384; // 16KB для WebRTC DataChannel
  static const int _streamChunkSize = 65536; // 64KB для File streams

  static const String _transferStateExt = '.localsend_state';
  static const String _tempFileExt = '.localsend_temp';

  // Внутренние состояния для resume функциональности и управления файлами
  final Map<String, _TransferState> _activeTransfers = {};
  final Map<String, RandomAccessFile> _openFiles = {};

  /// Контроллер для уведомлений о прогрессе передач
  final StreamController<Map<String, dynamic>> _progressController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Поток прогресса передач файлов
  Stream<Map<String, dynamic>> get transferProgress =>
      _progressController.stream;

  // ========== Методы выбора и управления файлами ==========

  /// Выбирает файлы для отправки через FilePicker
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

  /// Получает информацию о файле
  Future<Map<String, dynamic>?> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final fileName = filePath.split(Platform.pathSeparator).last;

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

  // ========== Методы создания FileTransfer ==========

  /// Создает FileTransfer для отправки файла
  Future<FileTransfer> createFileTransferForSending({
    required File file,
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final fileStat = await file.stat();
      final fileName = file.path.split(Platform.pathSeparator).last;
      final fileHash = await _calculateFileHash(file.path);

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
      logError(
        'Ошибка создания FileTransfer для отправки',
        error: e,
        tag: _logTag,
      );
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

  // ========== WebRTC DataChannel методы с resume ==========

  /// Отправляет файл по частям через DataChannel с поддержкой resume
  Future<bool> sendFileChunked({
    required RTCDataChannel dataChannel,
    required String filePath,
    required String transferId,
    Function(double)? onProgress,
    int? chunkSize,
  }) async {
    final effectiveChunkSize = chunkSize ?? _defaultChunkSize;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        logError('Файл не найден: $filePath', tag: _logTag);
        return false;
      }

      final fileSize = await file.length();
      final fileName = filePath.split(Platform.pathSeparator).last;

      // Вычисляем хеш файла для проверки целостности
      final fileHash = await _calculateFileHash(filePath);

      // Создаем или восстанавливаем состояние передачи
      final transferState = await _getOrCreateTransferState(
        transferId: transferId,
        filePath: filePath,
        fileSize: fileSize,
        fileHash: fileHash,
      );

      logInfo(
        'Начало chunked отправки файла',
        tag: _logTag,
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
          'chunkSize': effectiveChunkSize,
          'totalChunks': (fileSize / effectiveChunkSize).ceil(),
          'resumeFrom': transferState.completedChunks,
        },
      );

      // Отправляем метаданные файла
      await _sendFileMetadata(
        dataChannel,
        fileName,
        fileSize,
        fileHash,
        transferId,
      );

      final totalChunks = (fileSize / effectiveChunkSize).ceil();
      final raf = await file.open();
      _openFiles[transferId] = raf;

      try {
        // Начинаем с последнего завершенного чанка для resume
        for (
          int chunkIndex = transferState.completedChunks;
          chunkIndex < totalChunks;
          chunkIndex++
        ) {
          final offset = chunkIndex * effectiveChunkSize;
          final remainingBytes = fileSize - offset;
          final currentChunkSize = remainingBytes < effectiveChunkSize
              ? remainingBytes
              : effectiveChunkSize;

          await raf.setPosition(offset);
          final chunkData = await raf.read(currentChunkSize);

          // Создаем заголовок чанка
          final chunkHeader = {
            'type': 'file_chunk',
            'transferId': transferId,
            'chunkIndex': chunkIndex,
            'totalChunks': totalChunks,
            'chunkSize': currentChunkSize,
            'isLast': chunkIndex == totalChunks - 1,
          };

          // Отправляем заголовок и данные
          dataChannel.send(RTCDataChannelMessage(jsonEncode(chunkHeader)));
          dataChannel.send(RTCDataChannelMessage.fromBinary(chunkData));

          // Обновляем состояние
          final updatedState = transferState.copyWith(
            completedChunks: chunkIndex + 1,
            lastActivity: DateTime.now(),
          );
          _activeTransfers[transferId] = updatedState;
          await _saveTransferState(updatedState);

          // Уведомляем о прогрессе
          final progress = (chunkIndex + 1) / totalChunks;
          onProgress?.call(progress);
          _progressController.add({
            'type': 'send_progress',
            'transferId': transferId,
            'progress': progress,
            'chunkIndex': chunkIndex + 1,
            'totalChunks': totalChunks,
          });

          // Небольшая пауза для избежания перегрузки канала
          await Future.delayed(const Duration(microseconds: 100));
        }

        // Отправляем сигнал завершения
        final completionMessage = {
          'type': 'file_complete',
          'transferId': transferId,
          'fileHash': fileHash,
        };
        dataChannel.send(RTCDataChannelMessage(jsonEncode(completionMessage)));

        logInfo(
          'Файл отправлен успешно',
          tag: _logTag,
          data: {'transferId': transferId, 'fileName': fileName},
        );

        // Очищаем состояние после успешной отправки
        await _cleanupTransfer(transferId);
        return true;
      } finally {
        await raf.close();
        _openFiles.remove(transferId);
      }
    } catch (e) {
      logError('Ошибка chunked отправки файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Получает файл по частям с поддержкой resume
  Future<bool> receiveFileChunked({
    required String message,
    required String transferId,
    Function(double)? onProgress,
  }) async {
    try {
      final data = jsonDecode(message);
      final messageType = data['type'] as String?;

      switch (messageType) {
        case 'file_metadata':
          return await _handleFileMetadata(data, transferId, onProgress);

        case 'file_chunk':
          return await _handleFileChunk(data, transferId, onProgress);

        case 'file_complete':
          return await _handleFileComplete(data, transferId);

        default:
          logWarning('Неизвестный тип сообщения: $messageType', tag: _logTag);
          return false;
      }
    } catch (e) {
      logError('Ошибка получения файла по частям', error: e, tag: _logTag);
      return false;
    }
  }

  /// Обработка binary данных чанка
  Future<bool> handleChunkData({
    required Uint8List chunkData,
    required String transferId,
    required int chunkIndex,
    Function(double)? onProgress,
  }) async {
    try {
      final transferState = _activeTransfers[transferId];
      if (transferState == null) {
        logError('Состояние передачи не найдено: $transferId', tag: _logTag);
        return false;
      }

      final raf = _openFiles[transferId];
      if (raf == null) {
        logError('Файл не открыт для передачи: $transferId', tag: _logTag);
        return false;
      }

      // Записываем чанк в правильную позицию
      final offset = chunkIndex * _defaultChunkSize;
      await raf.setPosition(offset);
      await raf.writeFrom(chunkData);
      await raf.flush();

      // Обновляем состояние
      final newReceivedChunks = Set<int>.from(transferState.receivedChunks)
        ..add(chunkIndex);

      final updatedState = transferState.copyWith(
        receivedChunks: newReceivedChunks,
        lastActivity: DateTime.now(),
      );
      _activeTransfers[transferId] = updatedState;
      await _saveTransferState(updatedState);

      // Уведомляем о прогрессе
      final totalChunks = (transferState.fileSize / _defaultChunkSize).ceil();
      final progress = newReceivedChunks.length / totalChunks;
      onProgress?.call(progress);
      _progressController.add({
        'type': 'receive_progress',
        'transferId': transferId,
        'progress': progress,
        'receivedChunks': newReceivedChunks.length,
        'totalChunks': totalChunks,
      });

      return true;
    } catch (e) {
      logError('Ошибка обработки данных чанка', error: e, tag: _logTag);
      return false;
    }
  }

  // ========== Stream-based методы (для локальных операций) ==========

  /// Читает файл по чанкам для отправки через Stream
  Stream<FileChunk> readFileAsChunks(FileTransfer transfer) async* {
    try {
      final file = File(transfer.filePath!);
      final randomAccessFile = await file.open(mode: FileMode.read);

      try {
        int chunkIndex = 0;
        final totalChunks = (transfer.fileSize / _streamChunkSize).ceil();

        logInfo(
          'Начало чтения файла по чанкам',
          tag: _logTag,
          data: {'fileName': transfer.fileName, 'totalChunks': totalChunks},
        );

        while (true) {
          final chunkData = await randomAccessFile.read(_streamChunkSize);
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

  /// Записывает чанк файла при получении через Stream
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

  // ========== Resume и управление передачами ==========

  /// Возобновляет прерванную передачу
  Future<bool> resumeTransfer(String transferId) async {
    try {
      final transferState = await _loadTransferState(transferId);
      if (transferState == null) {
        logError(
          'Состояние передачи для resume не найдено: $transferId',
          tag: _logTag,
        );
        return false;
      }

      // Проверяем, что временный файл существует
      final tempFilePath = '${transferState.filePath}$_tempFileExt';
      if (!await File(tempFilePath).exists()) {
        logError(
          'Временный файл не найден для resume: $tempFilePath',
          tag: _logTag,
        );
        return false;
      }

      // Восстанавливаем состояние в активные передачи
      _activeTransfers[transferId] = transferState;

      logInfo(
        'Передача возобновлена',
        tag: _logTag,
        data: {
          'transferId': transferId,
          'completedChunks': transferState.completedChunks,
          'receivedChunks': transferState.receivedChunks.length,
        },
      );

      return true;
    } catch (e) {
      logError('Ошибка возобновления передачи', error: e, tag: _logTag);
      return false;
    }
  }

  /// Отменяет передачу и очищает состояние
  Future<void> cancelTransfer(String transferId) async {
    try {
      final transferState = _activeTransfers[transferId];

      // Закрываем открытый файл
      final raf = _openFiles[transferId];
      await raf?.close();
      _openFiles.remove(transferId);

      // Удаляем временный файл если он существует
      if (transferState != null) {
        final tempFilePath = '${transferState.filePath}$_tempFileExt';
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      // Очищаем состояние
      await _cleanupTransfer(transferId);

      _progressController.add({
        'type': 'transfer_cancelled',
        'transferId': transferId,
      });

      logInfo(
        'Передача отменена',
        tag: _logTag,
        data: {'transferId': transferId},
      );
    } catch (e) {
      logError('Ошибка отмены передачи', error: e, tag: _logTag);
    }
  }

  /// Получает статус всех активных передач
  Map<String, Map<String, dynamic>> getActiveTransfersStatus() {
    final status = <String, Map<String, dynamic>>{};

    for (final entry in _activeTransfers.entries) {
      final state = entry.value;
      final totalChunks = (state.fileSize / _defaultChunkSize).ceil();

      status[entry.key] = {
        'filePath': state.filePath,
        'fileSize': state.fileSize,
        'fileHash': state.fileHash,
        'completedChunks': state.completedChunks,
        'receivedChunks': state.receivedChunks.length,
        'totalChunks': totalChunks,
        'sendProgress': state.completedChunks / totalChunks,
        'receiveProgress': state.receivedChunks.length / totalChunks,
        'lastActivity': state.lastActivity.millisecondsSinceEpoch,
      };
    }

    return status;
  }

  // ========== Проверка целостности ==========

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

      final actualHash = await _calculateFileHash(transfer.filePath!);
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

  // ========== Утилиты ==========

  /// Форматирует размер файла для отображения
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  // ========== Cleanup и dispose ==========

  /// Закрывает все активные передачи и очищает ресурсы
  Future<void> dispose() async {
    try {
      logInfo('Начало dispose UnifiedFileService', tag: _logTag);

      // Закрываем все открытые файлы
      for (final entry in _openFiles.entries) {
        try {
          await entry.value.close();
          logDebug('Закрыт файл: ${entry.key}', tag: _logTag);
        } catch (e) {
          logWarning('Ошибка закрытия файла ${entry.key}', tag: _logTag);
        }
      }
      _openFiles.clear();

      // Сохраняем состояния всех активных передач для возможного resume
      for (final state in _activeTransfers.values) {
        await _saveTransferState(state);
      }

      // Очищаем активные передачи
      _activeTransfers.clear();

      // Закрываем контроллер прогресса
      await _progressController.close();

      logInfo('UnifiedFileService disposed', tag: _logTag);
    } catch (e) {
      logError('Ошибка при dispose', error: e, tag: _logTag);
    }
  }

  // ========== Приватные методы ==========

  /// Обработка метаданных файла
  Future<bool> _handleFileMetadata(
    Map<String, dynamic> data,
    String transferId,
    Function(double)? onProgress,
  ) async {
    try {
      final fileName = data['fileName'] as String;
      final fileSize = data['fileSize'] as int;
      final fileHash = data['fileHash'] as String;

      // Получаем директорию для сохранения
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/LocalSend');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final filePath = '${downloadsDir.path}/$fileName';

      // Создаем или восстанавливаем состояние передачи
      final transferState = await _getOrCreateTransferState(
        transferId: transferId,
        filePath: filePath,
        fileSize: fileSize,
        fileHash: fileHash,
      );

      // Создаем временный файл для получения
      final tempFile = File('$filePath$_tempFileExt');
      final raf = await tempFile.open(mode: FileMode.write);
      _openFiles[transferId] = raf;

      // Устанавливаем размер файла
      await raf.truncate(fileSize);

      logInfo(
        'Готов к получению файла',
        tag: _logTag,
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
          'resumeFrom': transferState.receivedChunks.length,
        },
      );

      _progressController.add({
        'type': 'receive_started',
        'transferId': transferId,
        'fileName': fileName,
        'fileSize': fileSize,
      });

      return true;
    } catch (e) {
      logError('Ошибка обработки метаданных файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Обработка чанка файла
  Future<bool> _handleFileChunk(
    Map<String, dynamic> data,
    String transferId,
    Function(double)? onProgress,
  ) async {
    try {
      final chunkIndex = data['chunkIndex'] as int;

      final transferState = _activeTransfers[transferId];
      if (transferState == null) {
        logError('Состояние передачи не найдено: $transferId', tag: _logTag);
        return false;
      }

      // Проверяем, не получили ли мы уже этот чанк
      if (transferState.receivedChunks.contains(chunkIndex)) {
        logDebug('Чанк уже получен: $chunkIndex', tag: _logTag);
        return true;
      }

      final raf = _openFiles[transferId];
      if (raf == null) {
        logError('Файл не открыт для передачи: $transferId', tag: _logTag);
        return false;
      }

      // Эта функция подготавливает к получению binary данных
      // Фактическая запись происходит в handleChunkData
      return true;
    } catch (e) {
      logError('Ошибка обработки чанка файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Обработка завершения файла
  Future<bool> _handleFileComplete(
    Map<String, dynamic> data,
    String transferId,
  ) async {
    try {
      final expectedHash = data['fileHash'] as String;
      final transferState = _activeTransfers[transferId];

      if (transferState == null) {
        logError('Состояние передачи не найдено: $transferId', tag: _logTag);
        return false;
      }

      // Закрываем файл
      final raf = _openFiles[transferId];
      await raf?.close();
      _openFiles.remove(transferId);

      // Проверяем целостность
      final tempFilePath = '${transferState.filePath}$_tempFileExt';
      final actualHash = await _calculateFileHash(tempFilePath);

      if (actualHash != expectedHash) {
        logError(
          'Проверка целостности файла не прошла',
          tag: _logTag,
          data: {'expected': expectedHash, 'actual': actualHash},
        );

        // Удаляем поврежденный файл
        await File(tempFilePath).delete();

        _progressController.add({
          'type': 'transfer_failed',
          'transferId': transferId,
          'error': 'Проверка целостности файла не прошла',
        });

        return false;
      }

      // Перемещаем временный файл в финальное место
      await File(tempFilePath).rename(transferState.filePath);

      logInfo(
        'Файл получен успешно',
        tag: _logTag,
        data: {
          'filePath': transferState.filePath,
          'size': transferState.fileSize,
        },
      );

      _progressController.add({
        'type': 'transfer_completed',
        'transferId': transferId,
        'filePath': transferState.filePath,
      });

      // Очищаем состояние
      await _cleanupTransfer(transferId);
      return true;
    } catch (e) {
      logError('Ошибка завершения получения файла', error: e, tag: _logTag);
      return false;
    }
  }

  /// Получает или создает состояние передачи
  Future<_TransferState> _getOrCreateTransferState({
    required String transferId,
    required String filePath,
    required int fileSize,
    required String fileHash,
  }) async {
    // Проверяем активные передачи
    if (_activeTransfers.containsKey(transferId)) {
      return _activeTransfers[transferId]!;
    }

    // Пытаемся загрузить сохраненное состояние
    final savedState = await _loadTransferState(transferId);
    if (savedState != null) {
      _activeTransfers[transferId] = savedState;
      return savedState;
    }

    // Создаем новое состояние
    final newState = _TransferState(
      transferId: transferId,
      filePath: filePath,
      fileSize: fileSize,
      fileHash: fileHash,
    );

    _activeTransfers[transferId] = newState;
    await _saveTransferState(newState);

    return newState;
  }

  /// Сохраняет состояние передачи на диск
  Future<void> _saveTransferState(_TransferState state) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stateDir = Directory('${directory.path}/LocalSend/transfers');
      if (!await stateDir.exists()) {
        await stateDir.create(recursive: true);
      }

      final stateFile = File(
        '${stateDir.path}/${state.transferId}$_transferStateExt',
      );
      await stateFile.writeAsString(jsonEncode(state.toJson()));
    } catch (e) {
      logError('Ошибка сохранения состояния передачи', error: e, tag: _logTag);
    }
  }

  /// Загружает состояние передачи с диска
  Future<_TransferState?> _loadTransferState(String transferId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stateFile = File(
        '${directory.path}/LocalSend/transfers/$transferId$_transferStateExt',
      );

      if (!await stateFile.exists()) {
        return null;
      }

      final jsonString = await stateFile.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      return _TransferState.fromJson(json);
    } catch (e) {
      logError('Ошибка загрузки состояния передачи', error: e, tag: _logTag);
      return null;
    }
  }

  /// Очищает состояние передачи
  Future<void> _cleanupTransfer(String transferId) async {
    try {
      // Закрываем открытый файл
      final raf = _openFiles[transferId];
      await raf?.close();
      _openFiles.remove(transferId);

      // Удаляем из активных передач
      _activeTransfers.remove(transferId);

      // Удаляем файл состояния
      final directory = await getApplicationDocumentsDirectory();
      final stateFile = File(
        '${directory.path}/LocalSend/transfers/$transferId$_transferStateExt',
      );
      if (await stateFile.exists()) {
        await stateFile.delete();
      }
    } catch (e) {
      logError('Ошибка очистки состояния передачи', error: e, tag: _logTag);
    }
  }

  /// Отправляет метаданные файла через DataChannel
  Future<void> _sendFileMetadata(
    RTCDataChannel dataChannel,
    String fileName,
    int fileSize,
    String fileHash,
    String transferId,
  ) async {
    final metadata = {
      'type': 'file_metadata',
      'transferId': transferId,
      'fileName': fileName,
      'fileSize': fileSize,
      'fileHash': fileHash,
    };

    dataChannel.send(RTCDataChannelMessage(jsonEncode(metadata)));
  }

  /// Вычисляет SHA-256 хеш файла
  Future<String> _calculateFileHash(String filePath) async {
    try {
      final file = File(filePath);
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

      var savePath = '${downloadsDir.path}$delimiter$fileName';
      var counter = 1;

      // Если файл уже существует, добавляем счетчик
      while (await File(savePath).exists()) {
        final extension = fileName.contains('.')
            ? '.${fileName.split('.').last}'
            : '';
        final baseName = fileName.contains('.')
            ? fileName.substring(0, fileName.lastIndexOf('.'))
            : fileName;

        savePath =
            '${downloadsDir.path}$delimiter$baseName ($counter)$extension';
        counter++;
      }

      return savePath;
    } catch (e) {
      logError('Ошибка получения пути сохранения', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Получает правильный разделитель пути для текущей платформы
  String get delimiter => Platform.pathSeparator;
}
