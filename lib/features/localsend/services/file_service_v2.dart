import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:hoplixi/features/localsend/models/index.dart';

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

/// Сервис для работы с файлами в LocalSend с поддержкой resume
class FileServiceV2 {
  static const String _logTag = 'FileServiceV2';
  static const int _chunkSize = 16384; // 16KB
  static const String _transferStateExt = '.localsend_state';
  static const String _tempFileExt = '.localsend_temp';

  // Внутренние карты для отслеживания состояния
  final Map<String, _TransferState> _activeTransfers = {};
  final Map<String, RandomAccessFile> _openFiles = {};

  /// Контроллер для уведомлений о прогрессе
  final StreamController<Map<String, dynamic>> _progressController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Поток прогресса передач файлов
  Stream<Map<String, dynamic>> get transferProgress =>
      _progressController.stream;

  /// Отправляет файл по частям через DataChannel с поддержкой resume
  Future<bool> sendFileChunked({
    required RTCDataChannel dataChannel,
    required String filePath,
    required String transferId,
    Function(double)? onProgress,
    int chunkSize = 16384, // 16KB chunks
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        logError('File not found: $filePath', tag: _logTag);
        return false;
      }

      final fileSize = await file.length();
      final fileName = file.path.split(Platform.pathSeparator).last;

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
        'Starting chunked file send',
        tag: _logTag,
        data: {
          'fileName': fileName,
          'fileSize': fileSize,
          'chunks': (fileSize / chunkSize).ceil(),
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

      final totalChunks = (fileSize / chunkSize).ceil();
      final raf = await file.open();
      _openFiles[transferId] = raf;

      try {
        // Начинаем с последнего завершенного чанка
        for (
          int chunkIndex = transferState.completedChunks;
          chunkIndex < totalChunks;
          chunkIndex++
        ) {
          final offset = chunkIndex * chunkSize;
          final remainingBytes = fileSize - offset;
          final currentChunkSize = remainingBytes < chunkSize
              ? remainingBytes
              : chunkSize;

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

          // Отправляем заголовок
          dataChannel.send(RTCDataChannelMessage(jsonEncode(chunkHeader)));

          // Отправляем данные чанка
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
          'File sent successfully',
          tag: _logTag,
          data: {'transferId': transferId},
        );

        // Очищаем состояние после успешной отправки
        await _cleanupTransfer(transferId);
        return true;
      } finally {
        await raf.close();
        _openFiles.remove(transferId);
      }
    } catch (e) {
      logError('Failed to send file chunked', error: e, tag: _logTag);
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
          logWarning('Unknown message type: $messageType', tag: _logTag);
          return false;
      }
    } catch (e) {
      logError('Failed to receive file chunk', error: e, tag: _logTag);
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
        logError('Transfer state not found: $transferId', tag: _logTag);
        return false;
      }

      final raf = _openFiles[transferId];
      if (raf == null) {
        logError('File not open for transfer: $transferId', tag: _logTag);
        return false;
      }

      // Записываем чанк в правильную позицию
      final offset = chunkIndex * _chunkSize;
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
      final totalChunks = (transferState.fileSize / _chunkSize).ceil();
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
      logError('Failed to handle chunk data', error: e, tag: _logTag);
      return false;
    }
  }

  /// Возобновляет прерванную передачу
  Future<bool> resumeTransfer(String transferId) async {
    try {
      final transferState = await _loadTransferState(transferId);
      if (transferState == null) {
        logError(
          'No transfer state found for resume: $transferId',
          tag: _logTag,
        );
        return false;
      }

      // Проверяем, что временный файл существует
      final tempFilePath = '${transferState.filePath}$_tempFileExt';
      if (!await File(tempFilePath).exists()) {
        logError(
          'Temporary file not found for resume: $tempFilePath',
          tag: _logTag,
        );
        return false;
      }

      // Восстанавливаем состояние в активные передачи
      _activeTransfers[transferId] = transferState;

      logInfo(
        'Transfer resumed',
        tag: _logTag,
        data: {
          'transferId': transferId,
          'completedChunks': transferState.completedChunks,
          'receivedChunks': transferState.receivedChunks.length,
        },
      );

      return true;
    } catch (e) {
      logError('Failed to resume transfer', error: e, tag: _logTag);
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
        'Transfer cancelled',
        tag: _logTag,
        data: {'transferId': transferId},
      );
    } catch (e) {
      logError('Failed to cancel transfer', error: e, tag: _logTag);
    }
  }

  /// Получает статус всех активных передач
  Map<String, Map<String, dynamic>> getActiveTransfersStatus() {
    final status = <String, Map<String, dynamic>>{};

    for (final entry in _activeTransfers.entries) {
      final state = entry.value;
      final totalChunks = (state.fileSize / _chunkSize).ceil();

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

  // Private helper methods

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
        'Ready to receive file',
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
      logError('Failed to handle file metadata', error: e, tag: _logTag);
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
        logError('Transfer state not found: $transferId', tag: _logTag);
        return false;
      }

      // Проверяем, не получили ли мы уже этот чанк
      if (transferState.receivedChunks.contains(chunkIndex)) {
        logDebug('Chunk already received: $chunkIndex', tag: _logTag);
        return true;
      }

      final raf = _openFiles[transferId];
      if (raf == null) {
        logError('File not open for transfer: $transferId', tag: _logTag);
        return false;
      }

      // Эта функция подготавливает к получению binary данных
      // Фактическая запись происходит в handleChunkData
      return true;
    } catch (e) {
      logError('Failed to handle file chunk', error: e, tag: _logTag);
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
        logError('Transfer state not found: $transferId', tag: _logTag);
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
          'File integrity check failed',
          tag: _logTag,
          data: {'expected': expectedHash, 'actual': actualHash},
        );

        // Удаляем поврежденный файл
        await File(tempFilePath).delete();

        _progressController.add({
          'type': 'transfer_failed',
          'transferId': transferId,
          'error': 'File integrity check failed',
        });

        return false;
      }

      // Перемещаем временный файл в финальное место
      await File(tempFilePath).rename(transferState.filePath);

      logInfo(
        'File received successfully',
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
      logError('Failed to handle file complete', error: e, tag: _logTag);
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
      logError('Failed to save transfer state', error: e, tag: _logTag);
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
      logError('Failed to load transfer state', error: e, tag: _logTag);
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
      logError('Failed to cleanup transfer', error: e, tag: _logTag);
    }
  }

  /// Отправляет метаданные файла
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
      logError('Failed to calculate file hash', error: e, tag: _logTag);
      rethrow;
    }
  }

  /// Закрывает все активные передачи и очищает ресурсы
  Future<void> dispose() async {
    try {
      // Закрываем все открытые файлы
      for (final raf in _openFiles.values) {
        await raf.close();
      }
      _openFiles.clear();

      // Сохраняем состояния всех активных передач
      for (final state in _activeTransfers.values) {
        await _saveTransferState(state);
      }

      // Закрываем контроллер
      await _progressController.close();

      logInfo('FileServiceV2 disposed', tag: _logTag);
    } catch (e) {
      logError('Error during dispose', error: e, tag: _logTag);
    }
  }

  /// Создает FileTransfer для отправки файла
  Future<FileTransfer> createFileTransferForSending({
    required String filePath,
    required String senderId,
    required String receiverId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final stat = await file.stat();
    final fileName = filePath.split(Platform.pathSeparator).last;

    return FileTransfer.sending(
      senderId: senderId,
      receiverId: receiverId,
      fileName: fileName,
      filePath: filePath,
      fileSize: stat.size,
    );
  }

  /// Форматирует размер файла в человеко-читаемый формат
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }
}
