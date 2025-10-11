import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:mime/mime.dart';
import '../../core/logger/app_logger.dart';
import '../hoplixi_store.dart';
import '../dao/attachments_dao.dart';
import '../dao/passwords_dao.dart';
import '../dao/otps_dao.dart';
import '../dao/notes_dao.dart';
import '../dto/attachment_dto.dart';
import 'service_results.dart';


String _generateAttachmentFolder(String dbId) {
  return 'attachments/$dbId';
}

/// Сервис для работы с вложениями (attachments)
/// Автоматически определяет стратегию хранения (путь или данные в БД)
/// на основе размера файла
class AttachmentService {
  final HoplixiStore _database;
  late final AttachmentsDao _attachmentsDao;
  late final PasswordsDao _passwordsDao;
  late final OtpsDao _otpsDao;
  late final NotesDao _notesDao;

  /// Максимальный размер файла для хранения в БД (по умолчанию 5 МБ)
  /// Файлы больше этого размера будут храниться по пути на диске
  static const int defaultMaxSizeForDbStorage = 5 * 1024 * 1024; // 5 MB

  final int maxSizeForDbStorage;

  AttachmentService(
    this._database,
    this._attachmentsDao,
    this._passwordsDao,
    this._otpsDao,
    this._notesDao, {
    this.maxSizeForDbStorage = defaultMaxSizeForDbStorage,
  });

  // ==================== УДОБНЫЕ МЕТОДЫ С АВТООПРЕДЕЛЕНИЕМ ====================

  /// Создание attachment из файла с автоматическим определением стратегии хранения
  /// Если файл меньше [maxSizeForDbStorage], данные сохраняются в БД
  /// Иначе сохраняется только путь к файлу
  Future<ServiceResult<String>> createAttachmentFromFile({
    required String filePath,
    required String name,
    String? description,
    String? passwordId,
    String? otpId,
    String? noteId,
  }) async {
    try {
      logInfo(
        'Создание attachment из файла: $filePath',
        tag: 'AttachmentService',
      );

      // Проверяем существование файла
      final file = File(filePath);
      if (!await file.exists()) {
        return ServiceResult.error('Файл не найден: $filePath');
      }

      // Валидация родительской сущности
      final parentValidation = await _validateParentEntity(
        passwordId: passwordId,
        otpId: otpId,
        noteId: noteId,
      );
      if (!parentValidation.success) {
        return ServiceResult.error(
          parentValidation.message ?? 'Ошибка валидации родительской сущности',
        );
      }

      // Получаем информацию о файле
      final fileSize = await file.length();
      final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

      // Вычисляем checksum
      final fileData = await file.readAsBytes();
      final checksum = sha256.convert(fileData).toString();

      String attachmentId;

      // Определяем стратегию хранения
      if (fileSize <= maxSizeForDbStorage) {
        // Маленький файл - храним данные в БД
        logDebug(
          'Файл $name ($fileSize байт) будет сохранен в БД',
          tag: 'AttachmentService',
        );

        final dto = CreateAttachmentFromData(
          name: name,
          description: description,
          fileData: fileData,
          mimeType: mimeType,
          fileSize: fileSize,
          checksum: checksum,
          passwordId: passwordId,
          otpId: otpId,
          noteId: noteId,
        );

        attachmentId = await _attachmentsDao.createAttachmentFromData(dto);
      } else {
        // Большой файл - храним только путь
        logDebug(
          'Файл $name ($fileSize байт) будет сохранен как путь',
          tag: 'AttachmentService',
        );

        final dto = CreateAttachmentFromPath(
          name: name,
          description: description,
          filePath: filePath,
          mimeType: mimeType,
          fileSize: fileSize,
          checksum: checksum,
          passwordId: passwordId,
          otpId: otpId,
          noteId: noteId,
        );

        attachmentId = await _attachmentsDao.createAttachmentFromPath(dto);
      }

      logInfo(
        'Attachment создан успешно: $attachmentId',
        tag: 'AttachmentService',
        data: {
          'attachmentId': attachmentId,
          'fileSize': fileSize,
          'storageType': fileSize <= maxSizeForDbStorage ? 'database' : 'path',
        },
      );

      return ServiceResult.success(
        data: attachmentId,
        message: 'Вложение "$name" добавлено успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания attachment из файла',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка добавления вложения: ${e.toString()}');
    }
  }

  /// Создание attachment из данных в памяти
  Future<ServiceResult<String>> createAttachmentFromBytes({
    required String name,
    required Uint8List data,
    required String mimeType,
    String? description,
    String? passwordId,
    String? otpId,
    String? noteId,
  }) async {
    try {
      logInfo('Создание attachment из данных: $name', tag: 'AttachmentService');

      // Валидация родительской сущности
      final parentValidation = await _validateParentEntity(
        passwordId: passwordId,
        otpId: otpId,
        noteId: noteId,
      );
      if (!parentValidation.success) {
        return ServiceResult.error(
          parentValidation.message ?? 'Ошибка валидации родительской сущности',
        );
      }

      final fileSize = data.length;
      final checksum = sha256.convert(data).toString();

      final dto = CreateAttachmentFromData(
        name: name,
        description: description,
        fileData: data,
        mimeType: mimeType,
        fileSize: fileSize,
        checksum: checksum,
        passwordId: passwordId,
        otpId: otpId,
        noteId: noteId,
      );

      final attachmentId = await _attachmentsDao.createAttachmentFromData(dto);

      logInfo(
        'Attachment из данных создан: $attachmentId',
        tag: 'AttachmentService',
        data: {'attachmentId': attachmentId, 'fileSize': fileSize},
      );

      return ServiceResult.success(
        data: attachmentId,
        message: 'Вложение "$name" добавлено успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания attachment из данных',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка добавления вложения: ${e.toString()}');
    }
  }

  // ==================== CRUD ОПЕРАЦИИ ====================

  /// Получение attachment по ID
  Future<ServiceResult<AttachmentCardDto>> getAttachmentById(String id) async {
    try {
      logDebug('Получение attachment: $id', tag: 'AttachmentService');

      final attachment = await _attachmentsDao.getAttachmentCardById(id);
      if (attachment == null) {
        return ServiceResult.error('Вложение не найдено');
      }

      // Обновляем время последнего доступа
      await _attachmentsDao.updateLastAccessed(id);

      return ServiceResult.success(
        data: attachment,
        message: 'Вложение получено',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения attachment',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка получения вложения: ${e.toString()}');
    }
  }

  /// Получение полных данных attachment (с содержимым)
  Future<ServiceResult<dynamic>> getAttachmentWithData(String id) async {
    try {
      logDebug('Получение attachment с данными: $id', tag: 'AttachmentService');

      // Сначала получаем базовую информацию
      final baseAttachment = await _attachmentsDao.getAttachmentById(id);
      if (baseAttachment == null) {
        return ServiceResult.error('Вложение не найдено');
      }

      // Обновляем время последнего доступа
      await _attachmentsDao.updateLastAccessed(id);

      // Определяем тип и возвращаем соответствующий DTO
      if (baseAttachment.filePath != null) {
        final dto = await _attachmentsDao.getAttachmentFromPathById(id);
        return ServiceResult.success(
          data: dto,
          message: 'Вложение (путь) получено',
        );
      } else if (baseAttachment.fileData != null) {
        final dto = await _attachmentsDao.getAttachmentFromDataById(id);
        return ServiceResult.success(
          data: dto,
          message: 'Вложение (данные) получено',
        );
      } else {
        return ServiceResult.error('Вложение повреждено (нет данных и пути)');
      }
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения attachment с данными',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка получения вложения: ${e.toString()}');
    }
  }

  /// Получение файла attachment (для скачивания/открытия)
  Future<ServiceResult<File>> getAttachmentFile(String id) async {
    try {
      logDebug('Получение файла attachment: $id', tag: 'AttachmentService');

      final attachment = await _attachmentsDao.getAttachmentById(id);
      if (attachment == null) {
        return ServiceResult.error('Вложение не найдено');
      }

      // Обновляем время последнего доступа
      await _attachmentsDao.updateLastAccessed(id);

      if (attachment.filePath != null) {
        // Вложение хранится на диске
        final file = File(attachment.filePath!);
        if (!await file.exists()) {
          return ServiceResult.error(
            'Файл вложения не найден на диске: ${attachment.filePath}',
          );
        }
        return ServiceResult.success(data: file, message: 'Файл получен');
      } else if (attachment.fileData != null) {
        // Вложение хранится в БД - создаем временный файл
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/${attachment.name}');
        await tempFile.writeAsBytes(attachment.fileData!);

        return ServiceResult.success(
          data: tempFile,
          message: 'Временный файл создан',
        );
      } else {
        return ServiceResult.error('Вложение повреждено (нет данных и пути)');
      }
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения файла attachment',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка получения файла: ${e.toString()}');
    }
  }

  /// Удаление attachment
  Future<ServiceResult<bool>> deleteAttachment(String id) async {
    try {
      logInfo('Удаление attachment: $id', tag: 'AttachmentService');

      final deleted = await _attachmentsDao.deleteAttachment(id);
      if (!deleted) {
        return ServiceResult.error('Не удалось удалить вложение');
      }

      logInfo('Attachment удален: $id', tag: 'AttachmentService');

      return ServiceResult.success(
        data: true,
        message: 'Вложение удалено успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка удаления attachment',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка удаления вложения: ${e.toString()}');
    }
  }

  // ==================== ПОЛУЧЕНИЕ СПИСКОВ ====================

  /// Получение всех attachments для пароля
  Future<ServiceResult<List<AttachmentCardDto>>> getPasswordAttachments(
    String passwordId,
  ) async {
    try {
      logDebug(
        'Получение attachments для пароля: $passwordId',
        tag: 'AttachmentService',
      );

      final attachments = await _attachmentsDao.getAttachmentsByPasswordId(
        passwordId,
      );

      return ServiceResult.success(
        data: attachments,
        message: 'Вложения получены (${attachments.length})',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения attachments пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка получения вложений: ${e.toString()}');
    }
  }

  /// Получение всех attachments для TOTP
  Future<ServiceResult<List<AttachmentCardDto>>> getOtpAttachments(
    String otpId,
  ) async {
    try {
      logDebug(
        'Получение attachments для OTP: $otpId',
        tag: 'AttachmentService',
      );

      final attachments = await _attachmentsDao.getAttachmentsByOtpId(otpId);

      return ServiceResult.success(
        data: attachments,
        message: 'Вложения получены (${attachments.length})',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения attachments OTP',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка получения вложений: ${e.toString()}');
    }
  }

  /// Получение всех attachments для заметки
  Future<ServiceResult<List<AttachmentCardDto>>> getNoteAttachments(
    String noteId,
  ) async {
    try {
      logDebug(
        'Получение attachments для заметки: $noteId',
        tag: 'AttachmentService',
      );

      final attachments = await _attachmentsDao.getAttachmentsByNoteId(noteId);

      return ServiceResult.success(
        data: attachments,
        message: 'Вложения получены (${attachments.length})',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения attachments заметки',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка получения вложений: ${e.toString()}');
    }
  }

  /// Получение всех attachments
  Future<ServiceResult<List<AttachmentCardDto>>> getAllAttachments() async {
    try {
      logDebug('Получение всех attachments', tag: 'AttachmentService');

      final attachments = await _attachmentsDao.getAllAttachments();

      return ServiceResult.success(
        data: attachments,
        message: 'Все вложения получены (${attachments.length})',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения всех attachments',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка получения вложений: ${e.toString()}');
    }
  }

  /// Поиск attachments по имени
  Future<ServiceResult<List<AttachmentCardDto>>> searchAttachments(
    String searchTerm,
  ) async {
    try {
      logDebug('Поиск attachments: $searchTerm', tag: 'AttachmentService');

      if (searchTerm.isEmpty) {
        return await getAllAttachments();
      }

      final attachments = await _attachmentsDao.searchAttachments(searchTerm);

      return ServiceResult.success(
        data: attachments,
        message: 'Найдено вложений: ${attachments.length}',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка поиска attachments',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка поиска вложений: ${e.toString()}');
    }
  }

  /// Получение недавно использованных attachments
  Future<ServiceResult<List<AttachmentCardDto>>> getRecentAttachments({
    int limit = 10,
  }) async {
    try {
      logDebug(
        'Получение недавних attachments (limit: $limit)',
        tag: 'AttachmentService',
      );

      final attachments = await _attachmentsDao.getRecentlyAccessedAttachments(
        limit: limit,
      );

      return ServiceResult.success(
        data: attachments,
        message: 'Недавние вложения получены (${attachments.length})',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения недавних attachments',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error(
        'Ошибка получения недавних вложений: ${e.toString()}',
      );
    }
  }

  // ==================== СТАТИСТИКА ====================

  /// Получение количества attachments
  Future<ServiceResult<int>> getAttachmentsCount() async {
    try {
      final count = await _attachmentsDao.getAttachmentsCount();
      return ServiceResult.success(
        data: count,
        message: 'Всего вложений: $count',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения количества attachments',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error(
        'Ошибка получения статистики: ${e.toString()}',
      );
    }
  }

  /// Получение количества attachments для пароля
  Future<ServiceResult<int>> getPasswordAttachmentsCount(
    String passwordId,
  ) async {
    try {
      final count = await _attachmentsDao.getAttachmentsCountByPasswordId(
        passwordId,
      );
      return ServiceResult.success(data: count);
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения количества attachments пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка: ${e.toString()}');
    }
  }

  /// Получение количества attachments для OTP
  Future<ServiceResult<int>> getOtpAttachmentsCount(String otpId) async {
    try {
      final count = await _attachmentsDao.getAttachmentsCountByOtpId(otpId);
      return ServiceResult.success(data: count);
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения количества attachments OTP',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка: ${e.toString()}');
    }
  }

  /// Получение количества attachments для заметки
  Future<ServiceResult<int>> getNoteAttachmentsCount(String noteId) async {
    try {
      final count = await _attachmentsDao.getAttachmentsCountByNoteId(noteId);
      return ServiceResult.success(data: count);
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения количества attachments заметки',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error('Ошибка: ${e.toString()}');
    }
  }

  // ==================== STREAM ПОДПИСКИ ====================

  /// Stream для наблюдения за attachments пароля
  Stream<List<AttachmentCardDto>> watchPasswordAttachments(String passwordId) {
    return _attachmentsDao.watchAttachmentsByPasswordId(passwordId);
  }

  /// Stream для наблюдения за attachments OTP
  Stream<List<AttachmentCardDto>> watchOtpAttachments(String otpId) {
    return _attachmentsDao.watchAttachmentsByOtpId(otpId);
  }

  /// Stream для наблюдения за attachments заметки
  Stream<List<AttachmentCardDto>> watchNoteAttachments(String noteId) {
    return _attachmentsDao.watchAttachmentsByNoteId(noteId);
  }

  /// Stream для наблюдения за всеми attachments
  Stream<List<AttachmentCardDto>> watchAllAttachments() {
    return _attachmentsDao.watchAllAttachments();
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Валидация родительской сущности (должна быть указана ровно одна)
  Future<ServiceResult<bool>> _validateParentEntity({
    String? passwordId,
    String? otpId,
    String? noteId,
  }) async {
    // Проверяем, что указана ровно одна родительская сущность
    final parentCount = [
      passwordId,
      otpId,
      noteId,
    ].where((id) => id != null && id.isNotEmpty).length;

    if (parentCount == 0) {
      return ServiceResult.error(
        'Необходимо указать родительскую сущность (пароль, OTP или заметку)',
      );
    }

    if (parentCount > 1) {
      return ServiceResult.error(
        'Можно указать только одну родительскую сущность',
      );
    }

    // Проверяем существование родительской сущности
    if (passwordId != null) {
      final password = await _passwordsDao.getPasswordById(passwordId);
      if (password == null) {
        return ServiceResult.error('Пароль не найден');
      }
    }

    if (otpId != null) {
      final otp = await _otpsDao.getTotpById(otpId);
      if (otp == null) {
        return ServiceResult.error('TOTP не найден');
      }
    }

    if (noteId != null) {
      final note = await _notesDao.getNoteById(noteId);
      if (note == null) {
        return ServiceResult.error('Заметка не найдена');
      }
    }

    return ServiceResult.success(data: true);
  }

  /// Проверка целостности файла по checksum
  Future<ServiceResult<bool>> verifyAttachmentIntegrity(String id) async {
    try {
      logDebug(
        'Проверка целостности attachment: $id',
        tag: 'AttachmentService',
      );

      final attachment = await _attachmentsDao.getAttachmentById(id);
      if (attachment == null) {
        return ServiceResult.error('Вложение не найдено');
      }

      if (attachment.checksum == null) {
        return ServiceResult.success(
          data: true,
          message: 'Checksum не установлен',
        );
      }

      String calculatedChecksum;

      if (attachment.filePath != null) {
        // Файл на диске
        final file = File(attachment.filePath!);
        if (!await file.exists()) {
          return ServiceResult.error('Файл не найден на диске');
        }
        final data = await file.readAsBytes();
        calculatedChecksum = sha256.convert(data).toString();
      } else if (attachment.fileData != null) {
        // Данные в БД
        calculatedChecksum = sha256.convert(attachment.fileData!).toString();
      } else {
        return ServiceResult.error('Вложение повреждено');
      }

      final isValid = calculatedChecksum == attachment.checksum;

      if (!isValid) {
        logError(
          'Checksum не совпадает для attachment: $id',
          tag: 'AttachmentService',
          data: {
            'expected': attachment.checksum,
            'calculated': calculatedChecksum,
          },
        );
      }

      return ServiceResult.success(
        data: isValid,
        message: isValid
            ? 'Целостность файла подтверждена'
            : 'Файл поврежден или изменен',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка проверки целостности attachment',
        error: e,
        stackTrace: stackTrace,
        tag: 'AttachmentService',
      );
      return ServiceResult.error(
        'Ошибка проверки целостности: ${e.toString()}',
      );
    }
  }
}
