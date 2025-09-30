import 'dart:async';
import '../../core/logger/app_logger.dart';
import '../hoplixi_store.dart';
import '../dao/otps_dao.dart';
import '../dao/categories_dao.dart';
import '../dto/db_dto.dart';
import '../enums/entity_types.dart';
import 'service_results.dart';

/// Сервис для работы с TOTP (Time-based One-Time Password) токенами
/// Предоставляет CRUD операции с автоматическим шифрованием секретов
class TOTPService {
  late final OtpsDao _otpsDao;
  late final CategoriesDao _categoriesDao;

  TOTPService(this._otpsDao, this._categoriesDao);

  // ==================== ОСНОВНЫЕ CRUD ОПЕРАЦИИ ====================

  /// Создание нового TOTP токена с шифрованием секрета
  Future<ServiceResult<String>> createTotp(CreateTotpDto dto) async {
    try {
      logInfo(
        'Создание нового TOTP токена: ${dto.issuer} - ${dto.accountName}',
        tag: 'TOTPService',
      );

      // Проверяем существование категории если указана
      if (dto.categoryId != null) {
        final categoryExists = await _categoriesDao.getCategoryById(
          dto.categoryId!,
        );
        if (categoryExists == null) {
          return ServiceResult.error('Категория не найдена');
        }
      }

      // Создаем TOTP
      final totpId = await _otpsDao.createTotp(dto);

      logInfo(
        'TOTP токен создан успешно: $totpId',
        tag: 'TOTPService',
        data: {
          'totpId': totpId,
          'issuer': dto.issuer,
          'accountName': dto.accountName,
        },
      );

      return ServiceResult.success(
        data: totpId,
        message: 'TOTP токен "${dto.issuer}" создан успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания TOTP токена',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error(
        'Ошибка создания TOTP токена: ${e.toString()}',
      );
    }
  }

  /// Получение TOTP токена по ID с расшифровкой секрета
  Future<ServiceResult<Otp>> getTotpById(String id) async {
    try {
      logDebug('Получение TOTP токена: $id', tag: 'TOTPService');

      final otpData = await _otpsDao.getTotpById(id);
      if (otpData == null) {
        return ServiceResult.error('TOTP токен не найден');
      }

      // Обновляем время последнего доступа
      await _otpsDao.updateLastAccessed(id);

      return ServiceResult.success(
        data: otpData,
        message: 'TOTP токен получен',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения TOTP токена',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error(
        'Ошибка получения TOTP токена: ${e.toString()}',
      );
    }
  }

  /// Обновление TOTP токена
  /// ВАЖНО: обновлять otp коды не принято и мы не предоставляем такую возможность
  Future<ServiceResult<bool>> updateTotp(UpdateTotpDto dto) async {
    try {
      logInfo('Обновление TOTP токена: ${dto.id}', tag: 'TOTPService');

      // Проверяем существование токена
      final existingOtp = await _otpsDao.getTotpById(dto.id);
      if (existingOtp == null) {
        return ServiceResult.error('TOTP токен не найден');
      }

      // Проверяем существование категории если указана
      if (dto.categoryId != null) {
        final categoryExists = await _categoriesDao.getCategoryById(
          dto.categoryId!,
        );
        if (categoryExists == null) {
          return ServiceResult.error('Категория не найдена');
        }
      }

      // Обновляем токен
      final updated = await _otpsDao.updateTotp(dto);

      if (!updated) {
        return ServiceResult.error('Не удалось обновить TOTP токен');
      }

      logInfo(
        'TOTP токен обновлен успешно: ${dto.id}',
        tag: 'TOTPService',
        data: {'totpId': dto.id},
      );

      return ServiceResult.success(
        data: true,
        message: 'TOTP токен обновлен успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка обновления TOTP токена',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error(
        'Ошибка обновления TOTP токена: ${e.toString()}',
      );
    }
  }

  /// Удаление TOTP токена
  Future<ServiceResult<bool>> deleteTotp(String id) async {
    try {
      logInfo('Удаление TOTP токена: $id', tag: 'TOTPService');

      // Проверяем существование токена
      final existingOtp = await _otpsDao.getTotpById(id);
      if (existingOtp == null) {
        return ServiceResult.error('TOTP токен не найден');
      }

      // Удаляем токен
      final deleted = await _otpsDao.deleteTotp(id);
      if (!deleted) {
        return ServiceResult.error('Не удалось удалить TOTP токен');
      }

      logInfo(
        'TOTP токен удален успешно: $id',
        tag: 'TOTPService',
        data: {
          'totpId': id,
          'issuer': existingOtp.issuer,
          'accountName': existingOtp.accountName,
        },
      );

      return ServiceResult.success(
        data: true,
        message: 'TOTP токен "${existingOtp.issuer}" удален успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка удаления TOTP токена',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error(
        'Ошибка удаления TOTP токена: ${e.toString()}',
      );
    }
  }

  // ==================== ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Получение всех TOTP токенов
  Future<ServiceResult<List<Otp>>> getAllTotps() async {
    try {
      final otpData = await _otpsDao.getAllTotps();

      return ServiceResult.success(
        data: otpData,
        message: 'Получено ${otpData.length} TOTP токенов',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения всех TOTP токенов',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error(
        'Ошибка получения TOTP токенов: ${e.toString()}',
      );
    }
  }

  /// Получение TOTP токенов по категории
  Future<ServiceResult<List<Otp>>> getTotpsByCategory(String categoryId) async {
    try {
      final otpData = await _otpsDao.getTotpsByCategory(categoryId);

      return ServiceResult.success(
        data: otpData,
        message: 'Найдено ${otpData.length} TOTP токенов в категории',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения TOTP токенов по категории',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error(
        'Ошибка получения TOTP токенов: ${e.toString()}',
      );
    }
  }

  /// Получение избранных TOTP токенов
  Future<ServiceResult<List<Otp>>> getFavoriteTotps() async {
    try {
      final otpData = await _otpsDao.getFavoriteOtps();

      return ServiceResult.success(
        data: otpData,
        message: 'Найдено ${otpData.length} избранных TOTP токенов',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения избранных TOTP токенов',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error(
        'Ошибка получения избранных TOTP токенов: ${e.toString()}',
      );
    }
  }

  /// Поиск TOTP токенов
  Future<ServiceResult<List<Otp>>> searchTotps(String searchTerm) async {
    try {
      if (searchTerm.isEmpty) {
        return await getAllTotps();
      }

      final otpData = await _otpsDao.searchOtps(searchTerm);

      return ServiceResult.success(
        data: otpData,
        message:
            'Найдено ${otpData.length} TOTP токенов по запросу "$searchTerm"',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка поиска TOTP токенов',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error('Ошибка поиска TOTP токенов: ${e.toString()}');
    }
  }

  /// Обновление счетчика для HOTP
  Future<ServiceResult<bool>> updateHotpCounter(
    String id,
    int newCounter,
  ) async {
    try {
      logInfo('Обновление счетчика HOTP: $id', tag: 'TOTPService');

      final existingOtp = await _otpsDao.getTotpById(id);
      if (existingOtp == null) {
        return ServiceResult.error('TOTP токен не найден');
      }

      if (existingOtp.type != OtpType.hotp) {
        return ServiceResult.error('Операция доступна только для HOTP токенов');
      }

      await _otpsDao.updateHotpCounter(id, newCounter);

      logInfo(
        'Счетчик HOTP обновлен: $id -> $newCounter',
        tag: 'TOTPService',
        data: {'totpId': id, 'counter': newCounter},
      );

      return ServiceResult.success(
        data: true,
        message: 'Счетчик HOTP обновлен',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка обновления счетчика HOTP',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error('Ошибка обновления счетчика: ${e.toString()}');
    }
  }

  /// Переключение статуса избранного
  Future<ServiceResult<bool>> toggleFavorite(String id) async {
    try {
      final existingOtp = await _otpsDao.getTotpById(id);
      if (existingOtp == null) {
        return ServiceResult.error('TOTP токен не найден');
      }

      await _otpsDao.toggleFavoriteTotp(id);

      final newStatus = !existingOtp.isFavorite;
      logInfo(
        'Статус избранного изменен: $id -> $newStatus',
        tag: 'TOTPService',
        data: {'totpId': id, 'isFavorite': newStatus},
      );

      return ServiceResult.success(
        data: newStatus,
        message: newStatus ? 'Добавлено в избранное' : 'Удалено из избранного',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка изменения статуса избранного',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error('Ошибка изменения статуса: ${e.toString()}');
    }
  }

  /// Получение расшифрованного секрета TOTP токена
  Future<ServiceResult<String>> getDecryptedSecret(String id) async {
    try {
      final otp = await _otpsDao.getTotpById(id);
      if (otp == null) {
        return ServiceResult.error('TOTP токен не найден');
      }

      // Секрет уже расшифрован в DAO при получении
      return ServiceResult.success(
        data: otp.secret,
        message: 'Секрет получен успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения секрета TOTP токена',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error('Ошибка получения секрета: ${e.toString()}');
    }
  }

  // ==================== СТАТИСТИКА ====================

  /// Получение количества TOTP токенов
  Future<ServiceResult<int>> getTotpsCount() async {
    try {
      final count = await _otpsDao.getOtpsCount();
      return ServiceResult.success(
        data: count,
        message: 'Количество TOTP токенов: $count',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения количества TOTP токенов',
        error: e,
        stackTrace: stackTrace,
        tag: 'TOTPService',
      );
      return ServiceResult.error(
        'Ошибка получения статистики: ${e.toString()}',
      );
    }
  }

  // ==================== STREAM МЕТОДЫ ====================

  /// Stream всех TOTP токенов
  Stream<List<Otp>> watchAllTotps() {
    return _otpsDao.watchAllOtps();
  }

  /// Stream избранных TOTP токенов
  Stream<List<Otp>> watchFavoriteTotps() {
    return _otpsDao.watchFavoriteOtps();
  }

  /// Stream TOTP токенов по категории
  Stream<List<Otp>> watchTotpsByCategory(String categoryId) {
    return _otpsDao.watchOtpsByCategory(categoryId);
  }
}
