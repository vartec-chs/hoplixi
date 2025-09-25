import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:typed_data';

part 'file_transfer.freezed.dart';
part 'file_transfer.g.dart';

class Uint8ListBase64Converter extends JsonConverter<Uint8List, String> {
  const Uint8ListBase64Converter();

  @override
  Uint8List fromJson(String json) => base64Decode(json);

  @override
  String toJson(Uint8List object) => base64Encode(object);
}

/// Тип передачи файла
enum FileTransferDirection {
  /// Отправка файла
  sending,

  /// Получение файла
  receiving,
}

/// Статус передачи файла
enum FileTransferStatus {
  /// Ожидание начала передачи
  pending,

  /// Передача в процессе
  inProgress,

  /// Передача завершена успешно
  completed,

  /// Передача отменена
  cancelled,

  /// Ошибка передачи
  failed,

  /// Приостановлена
  paused,
}

/// Информация о передаче файла
@freezed
abstract class FileTransfer with _$FileTransfer {
  const factory FileTransfer({
    /// Уникальный идентификатор передачи
    required String id,

    /// ID устройства-отправителя
    required String senderId,

    /// ID устройства-получателя
    required String receiverId,

    /// Направление передачи
    required FileTransferDirection direction,

    /// Имя файла
    required String fileName,

    /// Размер файла в байтах
    required int fileSize,

    /// MIME тип файла
    String? mimeType,

    /// SHA-256 хеш файла для проверки целостности
    String? fileHash,

    /// Путь к файлу (для отправки) или место сохранения (для получения)
    String? filePath,

    /// Количество переданных байт
    @Default(0) int transferredBytes,

    /// Статус передачи
    @Default(FileTransferStatus.pending) FileTransferStatus status,

    /// Скорость передачи в байтах/сек
    @Default(0) double transferSpeed,

    /// Время начала передачи
    DateTime? startTime,

    /// Время завершения передачи
    DateTime? endTime,

    /// Сообщение об ошибке (если есть)
    String? errorMessage,

    /// Дополнительные метаданные
    Map<String, dynamic>? metadata,
  }) = _FileTransfer;

  factory FileTransfer.fromJson(Map<String, dynamic> json) =>
      _$FileTransferFromJson(json);

  /// Создает новую передачу файла для отправки
  factory FileTransfer.sending({
    required String senderId,
    required String receiverId,
    required String fileName,
    required int fileSize,
    required String filePath,
    String? mimeType,
    String? fileHash,
    Map<String, dynamic>? metadata,
  }) {
    return FileTransfer(
      id: const Uuid().v4(),
      senderId: senderId,
      receiverId: receiverId,
      direction: FileTransferDirection.sending,
      fileName: fileName,
      fileSize: fileSize,
      filePath: filePath,
      mimeType: mimeType,
      fileHash: fileHash,
      metadata: metadata,
    );
  }

  /// Создает новую передачу файла для получения
  factory FileTransfer.receiving({
    required String senderId,
    required String receiverId,
    required String fileName,
    required int fileSize,
    String? savePath,
    String? mimeType,
    String? fileHash,
    Map<String, dynamic>? metadata,
  }) {
    return FileTransfer(
      id: const Uuid().v4(),
      senderId: senderId,
      receiverId: receiverId,
      direction: FileTransferDirection.receiving,
      fileName: fileName,
      fileSize: fileSize,
      filePath: savePath,
      mimeType: mimeType,
      fileHash: fileHash,
      metadata: metadata,
    );
  }
}

/// Информация о чанке файла для передачи
@freezed
abstract class FileChunk with _$FileChunk {
  const factory FileChunk({
    /// ID передачи, к которой относится чанк
    required String transferId,

    /// Порядковый номер чанка
    required int chunkIndex,

    /// Общее количество чанков
    required int totalChunks,

    /// Данные чанка
    @Uint8ListBase64Converter() required Uint8List data,

    /// Размер чанка в байтах
    required int size,

    /// Контрольная сумма чанка для проверки целостности
    String? checksum,
  }) = _FileChunk;

  factory FileChunk.fromJson(Map<String, dynamic> json) =>
      _$FileChunkFromJson(json);
}

/// Расширения для удобства работы с передачей файлов
extension FileTransferExtension on FileTransfer {
  /// Проверяет, является ли передача исходящей для данного устройства
  bool isSending(String currentDeviceId) =>
      senderId == currentDeviceId && direction == FileTransferDirection.sending;

  /// Проверяет, является ли передача входящей для данного устройства
  bool isReceiving(String currentDeviceId) =>
      receiverId == currentDeviceId &&
      direction == FileTransferDirection.receiving;

  /// Вычисляет прогресс передачи в процентах (0.0 - 1.0)
  double get progress {
    if (fileSize == 0) return 0.0;
    return transferredBytes / fileSize;
  }

  /// Вычисляет прогресс передачи в процентах (0 - 100)
  int get progressPercent => (progress * 100).round();

  /// Проверяет, завершена ли передача
  bool get isCompleted => status == FileTransferStatus.completed;

  /// Проверяет, активна ли передача
  bool get isActive => status == FileTransferStatus.inProgress;

  /// Проверяет, есть ли ошибка передачи
  bool get hasFailed => status == FileTransferStatus.failed;

  /// Проверяет, отменена ли передача
  bool get isCancelled => status == FileTransferStatus.cancelled;

  /// Форматирует размер файла для отображения
  String get formattedFileSize => _formatBytes(fileSize);

  /// Форматирует количество переданных байт для отображения
  String get formattedTransferredBytes => _formatBytes(transferredBytes);

  /// Форматирует скорость передачи для отображения
  String get formattedTransferSpeed {
    if (transferSpeed == 0) return '0 B/s';
    return '${_formatBytes(transferSpeed.round())}/s';
  }

  /// Вычисляет оставшееся время передачи
  Duration? get estimatedTimeRemaining {
    if (transferSpeed == 0 || isCompleted) return null;

    final remainingBytes = fileSize - transferredBytes;
    final secondsRemaining = remainingBytes / transferSpeed;

    return Duration(seconds: secondsRemaining.round());
  }

  /// Форматирует оставшееся время для отображения
  String get formattedTimeRemaining {
    final remaining = estimatedTimeRemaining;
    if (remaining == null) return 'Неизвестно';

    if (remaining.inMinutes < 1) {
      return '${remaining.inSeconds} сек';
    } else if (remaining.inHours < 1) {
      return '${remaining.inMinutes} мин ${remaining.inSeconds % 60} сек';
    } else {
      return '${remaining.inHours} ч ${remaining.inMinutes % 60} мин';
    }
  }

  /// Возвращает иконку статуса передачи
  String get statusIcon {
    switch (status) {
      case FileTransferStatus.pending:
        return '⏳';
      case FileTransferStatus.inProgress:
        return '⏬';
      case FileTransferStatus.completed:
        return '✅';
      case FileTransferStatus.cancelled:
        return '⏹️';
      case FileTransferStatus.failed:
        return '❌';
      case FileTransferStatus.paused:
        return '⏸️';
    }
  }
}

/// Утилиты для форматирования
String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024)
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}
