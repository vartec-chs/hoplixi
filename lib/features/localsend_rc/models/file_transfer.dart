import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
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

/// Состояния передачи файла
enum FileTransferState {
  /// Ожидание отправки/приёма
  pending,

  /// В процессе передачи
  transferring,

  /// Успешно завершено
  completed,

  /// Отменено пользователем
  cancelled,

  /// Ошибка передачи
  failed,

  /// Приостановлено
  paused,
}

/// Направление передачи файла
enum FileTransferDirection {
  /// Исходящий файл (отправка)
  outgoing,

  /// Входящий файл (получение)
  incoming,
}

/// Расширения для работы с состоянием передачи
extension FileTransferStateExtension on FileTransferState {
  /// Активна ли передача
  bool get isActive {
    switch (this) {
      case FileTransferState.transferring:
        return true;
      case FileTransferState.pending:
      case FileTransferState.completed:
      case FileTransferState.cancelled:
      case FileTransferState.failed:
      case FileTransferState.paused:
        return false;
    }
  }

  /// Можно ли отменить передачу
  bool get canCancel {
    switch (this) {
      case FileTransferState.pending:
      case FileTransferState.transferring:
      case FileTransferState.paused:
        return true;
      case FileTransferState.completed:
      case FileTransferState.cancelled:
      case FileTransferState.failed:
        return false;
    }
  }

  /// Можно ли приостановить/возобновить передачу
  bool get canPause {
    switch (this) {
      case FileTransferState.transferring:
        return true;
      case FileTransferState.pending:
      case FileTransferState.completed:
      case FileTransferState.cancelled:
      case FileTransferState.failed:
      case FileTransferState.paused:
        return false;
    }
  }

  /// Можно ли возобновить передачу
  bool get canResume {
    return this == FileTransferState.paused;
  }

  /// Отображаемое название состояния
  String get displayName {
    switch (this) {
      case FileTransferState.pending:
        return 'Ожидание';
      case FileTransferState.transferring:
        return 'Передача';
      case FileTransferState.completed:
        return 'Завершено';
      case FileTransferState.cancelled:
        return 'Отменено';
      case FileTransferState.failed:
        return 'Ошибка';
      case FileTransferState.paused:
        return 'Приостановлено';
    }
  }

  /// Иконка для состояния
  String get icon {
    switch (this) {
      case FileTransferState.pending:
        return '⏳';
      case FileTransferState.transferring:
        return '🔄';
      case FileTransferState.completed:
        return '✅';
      case FileTransferState.cancelled:
        return '❌';
      case FileTransferState.failed:
        return '🔴';
      case FileTransferState.paused:
        return '⏸️';
    }
  }
}

/// Метаданные файла для передачи
@freezed
abstract class FileMetadata with _$FileMetadata {
  const factory FileMetadata({
    /// Имя файла
    required String name,

    /// Размер файла в байтах
    required int size,

    /// MIME тип файла
    String? mimeType,

    /// Расширение файла
    String? extension,

    /// MD5 хеш файла для проверки целостности
    String? md5Hash,

    /// Дополнительные метаданные
    Map<String, dynamic>? extra,
  }) = _FileMetadata;

  factory FileMetadata.fromJson(Map<String, dynamic> json) =>
      _$FileMetadataFromJson(json);
}

/// Информация о передаче файла
@freezed
abstract class FileTransfer with _$FileTransfer {
  const factory FileTransfer({
    /// Уникальный ID передачи
    required String id,

    /// Метаданные файла
    required FileMetadata metadata,

    /// Направление передачи
    required FileTransferDirection direction,

    /// Текущее состояние передачи
    required FileTransferState state,

    /// Количество переданных байт
    @Default(0) int transferredBytes,

    /// Скорость передачи в байтах/сек
    @Default(0) double speed,

    /// Время начала передачи
    DateTime? startTime,

    /// Время завершения передачи
    DateTime? endTime,

    /// Ошибка передачи (если есть)
    String? error,

    /// Путь к локальному файлу
    String? localPath,

    /// Размер чанка в байтах
    @Default(64 * 1024) int chunkSize, // 64KB по умолчанию
    /// Общее количество чанков
    int? totalChunks,

    /// Текущий чанк
    @Default(0) int currentChunk,

    /// Дополнительные данные
    Map<String, dynamic>? extra,
  }) = _FileTransfer;

  factory FileTransfer.fromJson(Map<String, dynamic> json) =>
      _$FileTransferFromJson(json);
}

/// Расширения для FileTransfer
extension FileTransferExtension on FileTransfer {
  /// Прогресс передачи в процентах (0.0 - 1.0)
  double get progress {
    if (metadata.size == 0) return 0.0;
    return transferredBytes / metadata.size;
  }

  /// Прогресс в процентах (0 - 100)
  int get progressPercent => (progress * 100).round();

  /// Оставшееся количество байт
  int get remainingBytes => metadata.size - transferredBytes;

  /// Оценочное время завершения
  Duration? get estimatedTimeRemaining {
    if (speed == 0 || remainingBytes == 0) return null;
    final seconds = remainingBytes / speed;
    return Duration(seconds: seconds.round());
  }

  /// Прошедшее время передачи
  Duration? get elapsedTime {
    if (startTime == null) return null;
    final endTimeOrNow = endTime ?? DateTime.now();
    return endTimeOrNow.difference(startTime!);
  }

  /// Завершена ли передача
  bool get isCompleted => state == FileTransferState.completed;

  /// Есть ли ошибка
  bool get hasError => state == FileTransferState.failed;

  /// Активна ли передача
  bool get isActive => state.isActive;

  /// Человекочитаемый размер файла
  String get formattedSize => _formatBytes(metadata.size);

  /// Человекочитаемое количество переданных байт
  String get formattedTransferredBytes => _formatBytes(transferredBytes);

  /// Человекочитаемая скорость
  String get formattedSpeed => '${_formatBytes(speed.round())}/с';

  /// Форматирование байт в человекочитаемый вид
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }

  /// Создать копию с обновленным прогрессом
  FileTransfer copyWithProgress(int newTransferredBytes, {double? newSpeed}) {
    return copyWith(
      transferredBytes: newTransferredBytes,
      speed: newSpeed ?? speed,
      state: newTransferredBytes >= metadata.size
          ? FileTransferState.completed
          : FileTransferState.transferring,
      endTime: newTransferredBytes >= metadata.size ? DateTime.now() : endTime,
    );
  }

  /// Создать копию с новым состоянием
  FileTransfer copyWithState(
    FileTransferState newState, {
    String? errorMessage,
  }) {
    return copyWith(
      state: newState,
      error:
          errorMessage ?? (newState == FileTransferState.failed ? error : null),
      endTime:
          newState == FileTransferState.completed ||
              newState == FileTransferState.cancelled ||
              newState == FileTransferState.failed
          ? DateTime.now()
          : null,
    );
  }

  /// Начать передачу
  FileTransfer start() {
    return copyWith(
      state: FileTransferState.transferring,
      startTime: DateTime.now(),
      error: null,
    );
  }

  /// Приостановить передачу
  FileTransfer pause() {
    return copyWithState(FileTransferState.paused);
  }

  /// Возобновить передачу
  FileTransfer resume() {
    return copyWith(state: FileTransferState.transferring);
  }

  /// Отменить передачу
  FileTransfer cancel() {
    return copyWithState(FileTransferState.cancelled);
  }

  /// Завершить с ошибкой
  FileTransfer fail(String errorMessage) {
    return copyWithState(FileTransferState.failed, errorMessage: errorMessage);
  }
}

/// Чанк файла для передачи
@freezed
abstract class FileChunk with _$FileChunk {
  const factory FileChunk({
    /// ID передачи файла
    required String transferId,

    /// Номер чанка (начиная с 0)
    required int chunkIndex,

    /// Общее количество чанков
    required int totalChunks,

    /// Данные чанка
    @Uint8ListBase64Converter() required Uint8List data,

    /// Размер чанка
    required int size,

    /// Позиция в файле
    required int offset,

    /// Является ли последним чанком
    required bool isLast,

    /// MD5 хеш чанка для проверки целостности
    String? md5Hash,
  }) = _FileChunk;

  factory FileChunk.fromJson(Map<String, dynamic> json) =>
      _$FileChunkFromJson(json);
}

/// Сообщение управления передачей файла
@freezed
abstract class FileTransferMessage with _$FileTransferMessage {
  const factory FileTransferMessage({
    /// Тип сообщения
    required FileTransferMessageType type,

    /// ID передачи
    required String transferId,

    /// Данные сообщения
    Map<String, dynamic>? data,

    /// Временная метка
    required DateTime timestamp,
  }) = _FileTransferMessage;

  factory FileTransferMessage.fromJson(Map<String, dynamic> json) =>
      _$FileTransferMessageFromJson(json);

  /// Создать сообщение запроса передачи
  factory FileTransferMessage.request({
    required String transferId,
    required FileMetadata metadata,
  }) {
    return FileTransferMessage(
      type: FileTransferMessageType.request,
      transferId: transferId,
      timestamp: DateTime.now(),
      data: {'metadata': metadata.toJson()},
    );
  }

  /// Создать сообщение принятия передачи
  factory FileTransferMessage.accept({required String transferId}) {
    return FileTransferMessage(
      type: FileTransferMessageType.accept,
      transferId: transferId,
      timestamp: DateTime.now(),
    );
  }

  /// Создать сообщение отклонения передачи
  factory FileTransferMessage.reject({
    required String transferId,
    String? reason,
  }) {
    return FileTransferMessage(
      type: FileTransferMessageType.reject,
      transferId: transferId,
      timestamp: DateTime.now(),
      data: reason != null ? {'reason': reason} : null,
    );
  }

  /// Создать сообщение с чанком
  factory FileTransferMessage.chunk({
    required String transferId,
    required FileChunk chunk,
  }) {
    return FileTransferMessage(
      type: FileTransferMessageType.chunk,
      transferId: transferId,
      timestamp: DateTime.now(),
      data: chunk.toJson(),
    );
  }

  /// Создать сообщение подтверждения чанка
  factory FileTransferMessage.ack({
    required String transferId,
    required int chunkIndex,
  }) {
    return FileTransferMessage(
      type: FileTransferMessageType.ack,
      transferId: transferId,
      timestamp: DateTime.now(),
      data: {'chunkIndex': chunkIndex},
    );
  }

  /// Создать сообщение отмены передачи
  factory FileTransferMessage.cancel({
    required String transferId,
    String? reason,
  }) {
    return FileTransferMessage(
      type: FileTransferMessageType.cancel,
      transferId: transferId,
      timestamp: DateTime.now(),
      data: reason != null ? {'reason': reason} : null,
    );
  }

  /// Создать сообщение об ошибке
  factory FileTransferMessage.error({
    required String transferId,
    required String error,
  }) {
    return FileTransferMessage(
      type: FileTransferMessageType.error,
      transferId: transferId,
      timestamp: DateTime.now(),
      data: {'error': error},
    );
  }

  /// Создать сообщение о завершении
  factory FileTransferMessage.complete({required String transferId}) {
    return FileTransferMessage(
      type: FileTransferMessageType.complete,
      transferId: transferId,
      timestamp: DateTime.now(),
    );
  }
}

/// Типы сообщений управления передачей файлов
enum FileTransferMessageType {
  /// Запрос на передачу файла
  request,

  /// Принятие запроса
  accept,

  /// Отклонение запроса
  reject,

  /// Чанк данных
  chunk,

  /// Подтверждение получения чанка
  ack,

  /// Отмена передачи
  cancel,

  /// Ошибка передачи
  error,

  /// Завершение передачи
  complete,

  /// Приостановка передачи
  pause,

  /// Возобновление передачи
  resume,
}
