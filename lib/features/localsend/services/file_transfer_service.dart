import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/models/file_transfer.dart';

/// Сервис для управления передачей файлов через WebRTC DataChannel
class FileTransferService {
  static const String _logTag = 'FileTransferService';
  static const int _defaultChunkSize = 64 * 1024; // 64KB

  final _uuid = const Uuid();
  final Map<String, FileTransfer> _activeTransfers = {};
  final Map<String, StreamController<FileTransfer>> _transferControllers = {};
  final Map<String, Timer?> _speedTimers = {};
  final Map<String, int> _lastTransferredBytes = {};
  final Map<String, File> _incomingFiles = {};
  final Map<String, List<Uint8List>> _receivedChunks = {};

  /// Поток обновлений передач файлов
  final _transferUpdatesController = StreamController<FileTransfer>.broadcast();
  Stream<FileTransfer> get transferUpdates => _transferUpdatesController.stream;

  /// Callback для отправки данных через DataChannel
  Future<void> Function(Map<String, dynamic> data)? onSendData;

  /// Получить список активных передач
  List<FileTransfer> get activeTransfers => _activeTransfers.values.toList();

  /// Получить передачу по ID
  FileTransfer? getTransfer(String transferId) => _activeTransfers[transferId];

  /// Выбрать файлы для отправки
  Future<List<FileTransfer>?> selectFilesToSend() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final transfers = <FileTransfer>[];
      for (final platformFile in result.files) {
        if (platformFile.path == null) continue;

        final file = File(platformFile.path!);
        if (!file.existsSync()) continue;

        final metadata = FileMetadata(
          name: platformFile.name,
          size: platformFile.size,
          mimeType: _getMimeType(platformFile.name),
          extension: _getFileExtension(platformFile.name),
          md5Hash: await _calculateFileMD5(file),
        );

        final transfer = FileTransfer(
          id: _uuid.v4(),
          metadata: metadata,
          direction: FileTransferDirection.outgoing,
          state: FileTransferState.pending,
          localPath: file.path,
          chunkSize: _defaultChunkSize,
          totalChunks: (metadata.size / _defaultChunkSize).ceil(),
        );

        transfers.add(transfer);
        _activeTransfers[transfer.id] = transfer;

        logInfo(
          'Файл выбран для отправки',
          tag: _logTag,
          data: {
            'transferId': transfer.id,
            'fileName': metadata.name,
            'fileSize': metadata.size,
            'totalChunks': transfer.totalChunks,
          },
        );
      }

      return transfers;
    } catch (e, st) {
      logError('Ошибка выбора файлов', error: e, stackTrace: st, tag: _logTag);
      return null;
    }
  }

  /// Начать отправку файла
  Future<bool> startFileTransfer(String transferId) async {
    final transfer = _activeTransfers[transferId];
    if (transfer == null) {
      logError('Передача не найдена: $transferId', tag: _logTag);
      return false;
    }

    if (transfer.direction != FileTransferDirection.outgoing) {
      logError('Попытка отправки входящего файла: $transferId', tag: _logTag);
      return false;
    }

    try {
      // Отправляем запрос на передачу
      final requestMessage = FileTransferMessage.request(
        transferId: transferId,
        metadata: transfer.metadata,
      );

      await _sendMessage(requestMessage);

      final updatedTransfer = transfer.copyWithState(FileTransferState.pending);
      _updateTransfer(updatedTransfer);

      logInfo(
        'Запрос на передачу файла отправлен',
        tag: _logTag,
        data: {'transferId': transferId},
      );

      return true;
    } catch (e, st) {
      logError(
        'Ошибка начала передачи файла',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );

      final failedTransfer = transfer.fail('Ошибка отправки запроса: $e');
      _updateTransfer(failedTransfer);
      return false;
    }
  }

  /// Принять входящий файл
  Future<bool> acceptFileTransfer(String transferId) async {
    final transfer = _activeTransfers[transferId];
    if (transfer == null) return false;

    try {
      // Создаем локальный файл для записи
      final downloadsDir =
          await getDownloadsDirectory() ??
          await getExternalStorageDirectories(
            type: StorageDirectory.downloads,
          ).then((dirs) => dirs?.first) ??
          await getApplicationDocumentsDirectory();
      final localFile = File('${downloadsDir.path}/${transfer.metadata.name}');

      _incomingFiles[transferId] = localFile;
      _receivedChunks[transferId] = List.filled(
        transfer.totalChunks ?? 0,
        Uint8List(0),
      );

      // Отправляем подтверждение
      final acceptMessage = FileTransferMessage.accept(transferId: transferId);
      await _sendMessage(acceptMessage);

      final updatedTransfer = transfer.copyWith(
        localPath: localFile.path,
        state: FileTransferState.transferring,
        startTime: DateTime.now(),
      );

      _updateTransfer(updatedTransfer);
      _startSpeedCalculation(transferId);

      logInfo(
        'Передача файла принята',
        tag: _logTag,
        data: {'transferId': transferId, 'localPath': localFile.path},
      );

      return true;
    } catch (e, st) {
      logError('Ошибка принятия файла', error: e, stackTrace: st, tag: _logTag);

      await rejectFileTransfer(transferId, 'Ошибка создания файла');
      return false;
    }
  }

  /// Отклонить входящий файл
  Future<bool> rejectFileTransfer(String transferId, [String? reason]) async {
    try {
      final rejectMessage = FileTransferMessage.reject(
        transferId: transferId,
        reason: reason,
      );
      await _sendMessage(rejectMessage);

      final transfer = _activeTransfers[transferId];
      if (transfer != null) {
        final rejectedTransfer = transfer.copyWithState(
          FileTransferState.cancelled,
          errorMessage: reason ?? 'Отклонено пользователем',
        );
        _updateTransfer(rejectedTransfer);
      }

      _cleanup(transferId);
      return true;
    } catch (e, st) {
      logError(
        'Ошибка отклонения файла',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );
      return false;
    }
  }

  /// Отменить передачу файла
  Future<bool> cancelFileTransfer(String transferId, [String? reason]) async {
    try {
      final cancelMessage = FileTransferMessage.cancel(
        transferId: transferId,
        reason: reason,
      );
      await _sendMessage(cancelMessage);

      final transfer = _activeTransfers[transferId];
      if (transfer != null) {
        final cancelledTransfer = transfer.cancel();
        _updateTransfer(cancelledTransfer);
      }

      _cleanup(transferId);
      return true;
    } catch (e, st) {
      logError(
        'Ошибка отмены передачи',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );
      return false;
    }
  }

  /// Приостановить передачу файла
  Future<bool> pauseFileTransfer(String transferId) async {
    final transfer = _activeTransfers[transferId];
    if (transfer == null || !transfer.state.canPause) return false;

    try {
      final pauseMessage = FileTransferMessage(
        type: FileTransferMessageType.pause,
        transferId: transferId,
        timestamp: DateTime.now(),
      );
      await _sendMessage(pauseMessage);

      final pausedTransfer = transfer.pause();
      _updateTransfer(pausedTransfer);
      _stopSpeedCalculation(transferId);

      return true;
    } catch (e, st) {
      logError(
        'Ошибка приостановки передачи',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );
      return false;
    }
  }

  /// Возобновить передачу файла
  Future<bool> resumeFileTransfer(String transferId) async {
    final transfer = _activeTransfers[transferId];
    if (transfer == null || !transfer.state.canResume) return false;

    try {
      final resumeMessage = FileTransferMessage(
        type: FileTransferMessageType.resume,
        transferId: transferId,
        timestamp: DateTime.now(),
      );
      await _sendMessage(resumeMessage);

      final resumedTransfer = transfer.resume();
      _updateTransfer(resumedTransfer);
      _startSpeedCalculation(transferId);

      return true;
    } catch (e, st) {
      logError(
        'Ошибка возобновления передачи',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );
      return false;
    }
  }

  /// Обработать входящее сообщение о передаче файла
  Future<void> handleFileTransferMessage(
    Map<String, dynamic> messageData,
  ) async {
    try {
      final message = FileTransferMessage.fromJson(messageData);
      logInfo(
        'Получено сообщение передачи файла',
        tag: _logTag,
        data: {'type': message.type.name, 'transferId': message.transferId},
      );

      switch (message.type) {
        case FileTransferMessageType.request:
          await _handleTransferRequest(message);
          break;
        case FileTransferMessageType.accept:
          await _handleTransferAccept(message);
          break;
        case FileTransferMessageType.reject:
          await _handleTransferReject(message);
          break;
        case FileTransferMessageType.chunk:
          await _handleChunkReceived(message);
          break;
        case FileTransferMessageType.ack:
          await _handleChunkAck(message);
          break;
        case FileTransferMessageType.cancel:
          await _handleTransferCancel(message);
          break;
        case FileTransferMessageType.error:
          await _handleTransferError(message);
          break;
        case FileTransferMessageType.complete:
          await _handleTransferComplete(message);
          break;
        case FileTransferMessageType.pause:
          await _handleTransferPause(message);
          break;
        case FileTransferMessageType.resume:
          await _handleTransferResume(message);
          break;
      }
    } catch (e, st) {
      logError(
        'Ошибка обработки сообщения передачи файла',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );
    }
  }

  /// Обработать запрос на передачу файла
  Future<void> _handleTransferRequest(FileTransferMessage message) async {
    if (message.data == null || message.data!['metadata'] == null) return;

    final metadata = FileMetadata.fromJson(
      message.data!['metadata'] as Map<String, dynamic>,
    );

    final transfer = FileTransfer(
      id: message.transferId,
      metadata: metadata,
      direction: FileTransferDirection.incoming,
      state: FileTransferState.pending,
      chunkSize: _defaultChunkSize,
      totalChunks: (metadata.size / _defaultChunkSize).ceil(),
    );

    _activeTransfers[message.transferId] = transfer;
    _updateTransfer(transfer);

    logInfo(
      'Получен запрос на передачу файла',
      tag: _logTag,
      data: {
        'transferId': message.transferId,
        'fileName': metadata.name,
        'fileSize': metadata.size,
      },
    );
  }

  /// Обработать принятие передачи
  Future<void> _handleTransferAccept(FileTransferMessage message) async {
    final transfer = _activeTransfers[message.transferId];
    if (transfer == null ||
        transfer.direction != FileTransferDirection.outgoing)
      return;

    final updatedTransfer = transfer.start();
    _updateTransfer(updatedTransfer);
    _startSpeedCalculation(message.transferId);

    // Начинаем отправку файла
    await _startSendingFile(message.transferId);
  }

  /// Начать отправку файла по чанкам
  Future<void> _startSendingFile(String transferId) async {
    final transfer = _activeTransfers[transferId];
    if (transfer == null || transfer.localPath == null) return;

    try {
      final file = File(transfer.localPath!);
      if (!file.existsSync()) {
        throw FileSystemException('Файл не найден', transfer.localPath!);
      }

      final fileBytes = await file.readAsBytes();
      final totalChunks = (fileBytes.length / transfer.chunkSize).ceil();

      for (int i = 0; i < totalChunks; i++) {
        final currentTransfer = _activeTransfers[transferId];
        if (currentTransfer == null ||
            currentTransfer.state != FileTransferState.transferring) {
          break; // Передача была отменена или приостановлена
        }

        final offset = i * transfer.chunkSize;
        final end = (offset + transfer.chunkSize < fileBytes.length)
            ? offset + transfer.chunkSize
            : fileBytes.length;

        final chunkData = fileBytes.sublist(offset, end);
        final chunk = FileChunk(
          transferId: transferId,
          chunkIndex: i,
          totalChunks: totalChunks,
          data: Uint8List.fromList(chunkData),
          size: chunkData.length,
          offset: offset,
          isLast: i == totalChunks - 1,
          md5Hash: md5.convert(chunkData).toString(),
        );

        final chunkMessage = FileTransferMessage.chunk(
          transferId: transferId,
          chunk: chunk,
        );

        await _sendMessage(chunkMessage);

        // Обновляем прогресс
        final newTransferredBytes = offset + chunkData.length;
        final updatedTransfer = currentTransfer.copyWithProgress(
          newTransferredBytes,
        );
        _updateTransfer(updatedTransfer);

        // Небольшая задержка между чанками для стабильности
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Отправляем сообщение о завершении
      final completeMessage = FileTransferMessage.complete(
        transferId: transferId,
      );
      await _sendMessage(completeMessage);
    } catch (e, st) {
      logError('Ошибка отправки файла', error: e, stackTrace: st, tag: _logTag);

      final errorMessage = FileTransferMessage.error(
        transferId: transferId,
        error: e.toString(),
      );
      await _sendMessage(errorMessage);

      final failedTransfer = transfer.fail(e.toString());
      _updateTransfer(failedTransfer);
    }
  }

  /// Обработать получение чанка
  Future<void> _handleChunkReceived(FileTransferMessage message) async {
    if (message.data == null) return;

    final chunk = FileChunk.fromJson(message.data!);
    final transfer = _activeTransfers[chunk.transferId];
    if (transfer == null ||
        transfer.direction != FileTransferDirection.incoming)
      return;

    try {
      // Сохраняем чанк
      final chunks = _receivedChunks[chunk.transferId];
      if (chunks != null && chunk.chunkIndex < chunks.length) {
        chunks[chunk.chunkIndex] = chunk.data;

        // Обновляем прогресс
        final newTransferredBytes = (chunk.chunkIndex + 1) * transfer.chunkSize;
        final actualTransferredBytes =
            newTransferredBytes > transfer.metadata.size
            ? transfer.metadata.size
            : newTransferredBytes;

        final updatedTransfer = transfer.copyWithProgress(
          actualTransferredBytes,
        );
        _updateTransfer(updatedTransfer);

        // Отправляем подтверждение
        final ackMessage = FileTransferMessage.ack(
          transferId: chunk.transferId,
          chunkIndex: chunk.chunkIndex,
        );
        await _sendMessage(ackMessage);

        // Если это последний чанк, собираем файл
        if (chunk.isLast) {
          await _assembleFile(chunk.transferId);
        }
      }
    } catch (e, st) {
      logError(
        'Ошибка обработки чанка',
        error: e,
        stackTrace: st,
        tag: _logTag,
      );

      final errorMessage = FileTransferMessage.error(
        transferId: chunk.transferId,
        error: e.toString(),
      );
      await _sendMessage(errorMessage);
    }
  }

  /// Собрать файл из полученных чанков
  Future<void> _assembleFile(String transferId) async {
    final transfer = _activeTransfers[transferId];
    final chunks = _receivedChunks[transferId];
    final file = _incomingFiles[transferId];

    if (transfer == null || chunks == null || file == null) return;

    try {
      final fileBytes = <int>[];
      for (final chunk in chunks) {
        fileBytes.addAll(chunk);
      }

      await file.writeAsBytes(fileBytes);

      // Проверяем целостность файла
      final calculatedHash = await _calculateFileMD5(file);
      if (transfer.metadata.md5Hash != null &&
          calculatedHash != transfer.metadata.md5Hash) {
        throw Exception('Нарушена целостность файла');
      }

      final completedTransfer = transfer.copyWithState(
        FileTransferState.completed,
      );
      _updateTransfer(completedTransfer);

      logInfo(
        'Файл успешно получен и собран',
        tag: _logTag,
        data: {
          'transferId': transferId,
          'fileName': transfer.metadata.name,
          'localPath': file.path,
          'fileSize': transfer.metadata.size,
        },
      );

      _cleanup(transferId);
    } catch (e, st) {
      logError('Ошибка сборки файла', error: e, stackTrace: st, tag: _logTag);

      final failedTransfer = transfer.fail(e.toString());
      _updateTransfer(failedTransfer);
      _cleanup(transferId);
    }
  }

  /// Обработать подтверждение чанка
  Future<void> _handleChunkAck(FileTransferMessage message) async {
    // Здесь можно реализовать логику обработки подтверждений
    // Например, для повышения надежности передачи
  }

  /// Обработать отклонение передачи
  Future<void> _handleTransferReject(FileTransferMessage message) async {
    final transfer = _activeTransfers[message.transferId];
    if (transfer == null) return;

    final reason =
        message.data?['reason'] as String? ?? 'Отклонено получателем';
    final rejectedTransfer = transfer.copyWithState(
      FileTransferState.cancelled,
      errorMessage: reason,
    );
    _updateTransfer(rejectedTransfer);
    _cleanup(message.transferId);
  }

  /// Обработать отмену передачи
  Future<void> _handleTransferCancel(FileTransferMessage message) async {
    final transfer = _activeTransfers[message.transferId];
    if (transfer == null) return;

    final reason =
        message.data?['reason'] as String? ?? 'Отменено отправителем';
    final cancelledTransfer = transfer.copyWithState(
      FileTransferState.cancelled,
      errorMessage: reason,
    );
    _updateTransfer(cancelledTransfer);
    _cleanup(message.transferId);
  }

  /// Обработать ошибку передачи
  Future<void> _handleTransferError(FileTransferMessage message) async {
    final transfer = _activeTransfers[message.transferId];
    if (transfer == null) return;

    final error = message.data?['error'] as String? ?? 'Неизвестная ошибка';
    final failedTransfer = transfer.fail(error);
    _updateTransfer(failedTransfer);
    _cleanup(message.transferId);
  }

  /// Обработать завершение передачи
  Future<void> _handleTransferComplete(FileTransferMessage message) async {
    final transfer = _activeTransfers[message.transferId];
    if (transfer == null) return;

    if (transfer.direction == FileTransferDirection.outgoing) {
      final completedTransfer = transfer.copyWithState(
        FileTransferState.completed,
      );
      _updateTransfer(completedTransfer);
      _cleanup(message.transferId);
    }
  }

  /// Обработать приостановку передачи
  Future<void> _handleTransferPause(FileTransferMessage message) async {
    final transfer = _activeTransfers[message.transferId];
    if (transfer == null) return;

    final pausedTransfer = transfer.pause();
    _updateTransfer(pausedTransfer);
    _stopSpeedCalculation(message.transferId);
  }

  /// Обработать возобновление передачи
  Future<void> _handleTransferResume(FileTransferMessage message) async {
    final transfer = _activeTransfers[message.transferId];
    if (transfer == null) return;

    final resumedTransfer = transfer.resume();
    _updateTransfer(resumedTransfer);
    _startSpeedCalculation(message.transferId);
  }

  /// Отправить сообщение через DataChannel
  Future<void> _sendMessage(FileTransferMessage message) async {
    if (onSendData == null) {
      throw Exception('DataChannel callback не установлен');
    }

    final messageData = {'type': 'file_transfer', 'payload': message.toJson()};

    await onSendData!(messageData);
  }

  /// Обновить передачу и уведомить слушателей
  void _updateTransfer(FileTransfer transfer) {
    _activeTransfers[transfer.id] = transfer;
    _transferUpdatesController.add(transfer);
  }

  /// Начать расчет скорости передачи
  void _startSpeedCalculation(String transferId) {
    _stopSpeedCalculation(transferId);

    final transfer = _activeTransfers[transferId];
    if (transfer == null) return;

    _lastTransferredBytes[transferId] = transfer.transferredBytes;

    _speedTimers[transferId] = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      final currentTransfer = _activeTransfers[transferId];
      if (currentTransfer == null || !currentTransfer.isActive) {
        timer.cancel();
        return;
      }

      final lastBytes = _lastTransferredBytes[transferId] ?? 0;
      final currentBytes = currentTransfer.transferredBytes;
      final speed = (currentBytes - lastBytes).toDouble();

      _lastTransferredBytes[transferId] = currentBytes;

      final updatedTransfer = currentTransfer.copyWith(speed: speed);
      _updateTransfer(updatedTransfer);
    });
  }

  /// Остановить расчет скорости передачи
  void _stopSpeedCalculation(String transferId) {
    _speedTimers[transferId]?.cancel();
    _speedTimers.remove(transferId);
    _lastTransferredBytes.remove(transferId);
  }

  /// Очистить ресурсы для передачи
  void _cleanup(String transferId) {
    _stopSpeedCalculation(transferId);
    _transferControllers[transferId]?.close();
    _transferControllers.remove(transferId);
    _incomingFiles.remove(transferId);
    _receivedChunks.remove(transferId);
  }

  /// Вычислить MD5 хеш файла
  Future<String> _calculateFileMD5(File file) async {
    final bytes = await file.readAsBytes();
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Получить MIME тип файла
  String? _getMimeType(String fileName) {
    final extension = _getFileExtension(fileName);
    if (extension == null) return null;

    final mimeTypes = {
      'txt': 'text/plain',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'svg': 'image/svg+xml',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'mp4': 'video/mp4',
      'avi': 'video/avi',
      'mov': 'video/quicktime',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
    };

    return mimeTypes[extension.toLowerCase()];
  }

  /// Получить расширение файла
  String? _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == fileName.length - 1) return null;
    return fileName.substring(lastDot + 1);
  }

  /// Очистить все ресурсы
  void dispose() {
    for (final transferId in _activeTransfers.keys.toList()) {
      _cleanup(transferId);
    }
    _activeTransfers.clear();
    _transferUpdatesController.close();
  }
}
