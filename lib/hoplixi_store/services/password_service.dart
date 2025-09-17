import 'dart:async';
import '../../core/logger/app_logger.dart';
import '../hoplixi_store.dart';
import '../dao/passwords_dao.dart';
import '../dao/password_histories_dao.dart';
import '../dao/categories_dao.dart';
import '../dao/tags_dao.dart';
import '../dao/password_tags_dao.dart';
import '../dto/db_dto.dart';
import '../models/password_filter.dart';

import '../enums/entity_types.dart';
import 'service_results.dart';

/// Полный сервис для работы с паролями, включающий:
/// - CRUD операции с паролями
/// - Автоматическую работу с историей
/// - Управление категориями и тегами
/// - Поиск и фильтрацию
/// - Stream-подписки для UI
class PasswordService {
  final HoplixiStore _database;
  late final PasswordsDao _passwordsDao;
  late final PasswordHistoriesDao _passwordHistoriesDao;
  late final CategoriesDao _categoriesDao;
  late final TagsDao _tagsDao;
  late final PasswordTagsDao _passwordTagsDao;

  PasswordService(this._database) {
    _passwordsDao = PasswordsDao(_database);
    _passwordHistoriesDao = PasswordHistoriesDao(_database);
    _categoriesDao = CategoriesDao(_database);
    _tagsDao = TagsDao(_database);
    _passwordTagsDao = PasswordTagsDao(_database);
  }

  // ==================== ОСНОВНЫЕ CRUD ОПЕРАЦИИ ====================

  /// Создание нового пароля с автоматическим сохранением в историю
  Future<ServiceResult<String>> createPassword(
    CreatePasswordDto dto, {
    List<String>? tagIds,
  }) async {
    try {
      logInfo('Создание нового пароля: ${dto.name}', tag: 'PasswordService');

      // Проверяем существование категории если указана
      if (dto.categoryId != null) {
        final categoryExists = await _categoriesDao.getCategoryById(
          dto.categoryId!,
        );
        if (categoryExists == null) {
          return ServiceResult.error('Категория не найдена');
        }
      }

      // Проверяем существование тегов если указаны
      if (tagIds != null && tagIds.isNotEmpty) {
        for (final tagId in tagIds) {
          final tagExists = await _tagsDao.getTagById(tagId);
          if (tagExists == null) {
            return ServiceResult.error('Тег $tagId не найден');
          }
        }
      }

      // Создаем пароль
      final passwordId = await _passwordsDao.createPassword(dto);

      // Добавляем теги если указаны
      if (tagIds != null && tagIds.isNotEmpty) {
        await _passwordTagsDao.addTagsToPasswordsBatch([passwordId], tagIds);
      }

      // История создается автоматически через триггеры БД

      logInfo(
        'Пароль создан успешно: $passwordId',
        tag: 'PasswordService',
        data: {'passwordId': passwordId, 'tagsCount': tagIds?.length ?? 0},
      );

      return ServiceResult.success(
        data: passwordId,
        message: 'Пароль "${dto.name}" создан успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка создания пароля: ${e.toString()}');
    }
  }

  /// Обновление пароля с автоматическим сохранением в историю
  Future<ServiceResult<bool>> updatePassword(
    UpdatePasswordDto dto, {
    List<String>? tagIds,
    bool replaceAllTags = false,
  }) async {
    try {
      logInfo('Обновление пароля: ${dto.id}', tag: 'PasswordService');

      // Проверяем существование пароля
      final existingPassword = await _passwordsDao.getPasswordById(dto.id);
      if (existingPassword == null) {
        return ServiceResult.error('Пароль не найден');
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

      // Проверяем существование тегов если указаны
      if (tagIds != null && tagIds.isNotEmpty) {
        for (final tagId in tagIds) {
          final tagExists = await _tagsDao.getTagById(tagId);
          if (tagExists == null) {
            return ServiceResult.error('Тег $tagId не найден');
          }
        }
      }

      // Обновляем пароль
      final updated = await _passwordsDao.updatePassword(dto);

      if (!updated) {
        return ServiceResult.error('Не удалось обновить пароль');
      }

      // Обновляем теги если указаны
      if (tagIds != null) {
        if (replaceAllTags) {
          await _passwordTagsDao.replacePasswordTags(dto.id, tagIds);
        } else {
          // Добавляем новые теги, не удаляя существующие
          await _passwordTagsDao.addTagsToPasswordsBatch([dto.id], tagIds);
        }
      }

      // История обновляется автоматически через триггеры БД

      logInfo(
        'Пароль обновлен успешно: ${dto.id}',
        tag: 'PasswordService',
        data: {
          'passwordId': dto.id,
          'tagsCount': tagIds?.length ?? 0,
          'replaceAllTags': replaceAllTags,
        },
      );

      return ServiceResult.success(
        data: true,
        message: 'Пароль обновлен успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка обновления пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка обновления пароля: ${e.toString()}');
    }
  }

  /// Удаление пароля с автоматическим сохранением в историю
  Future<ServiceResult<bool>> deletePassword(String passwordId) async {
    try {
      logInfo('Удаление пароля: $passwordId', tag: 'PasswordService');

      // Проверяем существование пароля
      final existingPassword = await _passwordsDao.getPasswordById(passwordId);
      if (existingPassword == null) {
        return ServiceResult.error('Пароль не найден');
      }

      // Удаляем связи с тегами
      await _database.transaction(() async {
        // Удаляем связи password_tags
        await _database.customStatement(
          'DELETE FROM password_tags WHERE password_id = ?',
          [passwordId],
        );

        // Удаляем сам пароль
        final deleted = await _passwordsDao.deletePassword(passwordId);
        if (!deleted) {
          throw Exception('Не удалось удалить пароль');
        }
      });

      // История удаления создается автоматически через триггеры БД

      logInfo(
        'Пароль удален успешно: $passwordId',
        tag: 'PasswordService',
        data: {'passwordId': passwordId, 'name': existingPassword.name},
      );

      return ServiceResult.success(
        data: true,
        message: 'Пароль "${existingPassword.name}" удален успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка удаления пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка удаления пароля: ${e.toString()}');
    }
  }

  /// Получение пароля по ID с подробной информацией
  Future<ServiceResult<PasswordWithDetails>> getPasswordDetails(
    String passwordId,
  ) async {
    try {
      logDebug('Получение деталей пароля: $passwordId', tag: 'PasswordService');

      final password = await _passwordsDao.getPasswordById(passwordId);
      if (password == null) {
        return ServiceResult.error('Пароль не найден');
      }

      // Получаем дополнительную информацию
      final tags = await _passwordTagsDao.getTagsForPassword(passwordId);
      final category = password.categoryId != null
          ? await _categoriesDao.getCategoryById(password.categoryId!)
          : null;
      final historyCount = await _passwordHistoriesDao.getPasswordHistoryCount(
        passwordId,
      );

      // Обновляем время последнего доступа
      await _passwordsDao.updateLastAccessed(passwordId);

      final details = PasswordWithDetails(
        password: password,
        tags: tags,
        category: category,
        historyCount: historyCount,
      );

      return ServiceResult.success(
        data: details,
        message: 'Детали пароля получены',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения деталей пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка получения пароля: ${e.toString()}');
    }
  }

  // ==================== РАБОТА С ТЕГАМИ ====================

  /// Добавление тега к паролю
  Future<ServiceResult<bool>> addTagToPassword(
    String passwordId,
    String tagId,
  ) async {
    try {
      // Проверяем существование пароля и тега
      final password = await _passwordsDao.getPasswordById(passwordId);
      if (password == null) {
        return ServiceResult.error('Пароль не найден');
      }

      final tag = await _tagsDao.getTagById(tagId);
      if (tag == null) {
        return ServiceResult.error('Тег не найден');
      }

      // Проверяем, не назначен ли уже тег
      final hasTag = await _passwordTagsDao.passwordHasTag(passwordId, tagId);
      if (hasTag) {
        return ServiceResult.success(
          data: true,
          message: 'Тег уже назначен паролю',
        );
      }

      await _passwordTagsDao.addTagToPassword(passwordId, tagId);

      logInfo(
        'Тег добавлен к паролю',
        tag: 'PasswordService',
        data: {'passwordId': passwordId, 'tagId': tagId, 'tagName': tag.name},
      );

      return ServiceResult.success(
        data: true,
        message: 'Тег "${tag.name}" добавлен к паролю',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка добавления тега к паролю',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка добавления тега: ${e.toString()}');
    }
  }

  /// Удаление тега у пароля
  Future<ServiceResult<bool>> removeTagFromPassword(
    String passwordId,
    String tagId,
  ) async {
    try {
      final removed = await _passwordTagsDao.removeTagFromPassword(
        passwordId,
        tagId,
      );

      if (!removed) {
        return ServiceResult.error('Связь между паролем и тегом не найдена');
      }

      logInfo(
        'Тег удален у пароля',
        tag: 'PasswordService',
        data: {'passwordId': passwordId, 'tagId': tagId},
      );

      return ServiceResult.success(data: true, message: 'Тег удален у пароля');
    } catch (e, stackTrace) {
      logError(
        'Ошибка удаления тега у пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка удаления тега: ${e.toString()}');
    }
  }

  /// Получение тегов пароля
  Future<ServiceResult<List<Tag>>> getPasswordTags(String passwordId) async {
    try {
      final tags = await _passwordTagsDao.getTagsForPassword(passwordId);
      return ServiceResult.success(data: tags, message: 'Теги пароля получены');
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения тегов пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка получения тегов: ${e.toString()}');
    }
  }

  //get field password by id
  Future<ServiceResult<String>> getPasswordById(String passwordId) async {
    try {
      final password = await _passwordsDao.getPassword(passwordId);
      return ServiceResult.success(data: password, message: 'Пароль получен');
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка получения пароля: ${e.toString()}');
    }
  }

  //get field url by id
  Future<ServiceResult<String>> getPasswordUrlById(String passwordId) async {
    try {
      final password = await _passwordsDao.getUrl(passwordId);
      return ServiceResult.success(data: password, message: 'Url получен');
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения url',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка получения url: ${e.toString()}');
    }
  }

  //get field login or email by id
  Future<ServiceResult<String>> getPasswordLoginOrEmailById(String passwordId) async {
    try {
      final password = await _passwordsDao.getLoginOrEmail(passwordId);
      return ServiceResult.success(
        data: password,
        message: 'Логин или почта получен(ы)',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения логина или почты',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error(
        'Ошибка получения логина или почты: ${e.toString()}',
      );
    }
  }

  // ==================== ПОИСК И ФИЛЬТРАЦИЯ ====================

  /// Поиск паролей по различным критериям
  Future<ServiceResult<List<PasswordWithDetails>>> searchPasswords({
    String? searchTerm,
    String? categoryId,
    List<String>? tagIds,
    bool? isFavorite,
    bool includeTagsInAnd = true, // true = AND, false = OR для тегов
    int limit = 100,
  }) async {
    try {
      logDebug(
        'Поиск паролей',
        tag: 'PasswordService',
        data: {
          'searchTerm': searchTerm,
          'categoryId': categoryId,
          'tagIds': tagIds,
          'isFavorite': isFavorite,
          'includeTagsInAnd': includeTagsInAnd,
          'limit': limit,
        },
      );

      List<Password> passwords;

      if (tagIds != null && tagIds.isNotEmpty) {
        // Поиск по тегам
        if (includeTagsInAnd) {
          passwords = await _passwordTagsDao.getPasswordsByTags(tagIds);
        } else {
          passwords = await _passwordTagsDao.getPasswordsByAnyTag(tagIds);
        }
      } else if (categoryId != null) {
        // Поиск по категории
        passwords = await _passwordsDao.getPasswordsByCategory(categoryId);
      } else if (searchTerm != null && searchTerm.isNotEmpty) {
        // Поиск по тексту
        passwords = await _passwordsDao.searchPasswords(searchTerm);
      } else if (isFavorite == true) {
        // Избранные пароли
        passwords = await _passwordsDao.getFavoritePasswords();
      } else {
        // Все пароли
        passwords = await _passwordsDao.getAllPasswords();
      }

      // Применяем дополнительные фильтры
      if (isFavorite != null &&
          tagIds == null &&
          categoryId == null &&
          searchTerm == null) {
        passwords = passwords.where((p) => p.isFavorite == isFavorite).toList();
      }

      // Ограничиваем количество результатов
      if (passwords.length > limit) {
        passwords = passwords.take(limit).toList();
      }

      // Получаем детальную информацию для каждого пароля
      final List<PasswordWithDetails> detailedPasswords = [];
      for (final password in passwords) {
        final tags = await _passwordTagsDao.getTagsForPassword(password.id);
        final category = password.categoryId != null
            ? await _categoriesDao.getCategoryById(password.categoryId!)
            : null;
        final historyCount = await _passwordHistoriesDao
            .getPasswordHistoryCount(password.id);

        detailedPasswords.add(
          PasswordWithDetails(
            password: password,
            tags: tags,
            category: category,
            historyCount: historyCount,
          ),
        );
      }

      logDebug(
        'Поиск паролей завершен',
        tag: 'PasswordService',
        data: {'foundCount': detailedPasswords.length},
      );

      return ServiceResult.success(
        data: detailedPasswords,
        message: 'Найдено паролей: ${detailedPasswords.length}',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка поиска паролей',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка поиска: ${e.toString()}');
    }
  }

  /// Получение недавно использованных паролей
  Future<ServiceResult<List<PasswordWithDetails>>> getRecentlyUsed({
    int limit = 10,
  }) async {
    try {
      final passwords = await _passwordsDao.getRecentlyAccessedPasswords(
        limit: limit,
      );

      final List<PasswordWithDetails> detailedPasswords = [];
      for (final password in passwords) {
        final tags = await _passwordTagsDao.getTagsForPassword(password.id);
        final category = password.categoryId != null
            ? await _categoriesDao.getCategoryById(password.categoryId!)
            : null;
        final historyCount = await _passwordHistoriesDao
            .getPasswordHistoryCount(password.id);

        detailedPasswords.add(
          PasswordWithDetails(
            password: password,
            tags: tags,
            category: category,
            historyCount: historyCount,
          ),
        );
      }

      return ServiceResult.success(
        data: detailedPasswords,
        message: 'Недавно использованные пароли получены',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения недавно использованных паролей',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка получения данных: ${e.toString()}');
    }
  }

  // ==================== РАБОТА С КАТЕГОРИЯМИ ====================

  /// Создание новой категории для паролей
  Future<ServiceResult<String>> createCategory(CreateCategoryDto dto) async {
    try {
      logInfo('Создание категории: ${dto.name}', tag: 'PasswordService');

      // Проверяем, что тип категории подходит для паролей
      if (dto.type != CategoryType.password && dto.type != CategoryType.mixed) {
        return ServiceResult.error('Неверный тип категории для паролей');
      }

      final categoryId = await _categoriesDao.createCategory(dto);

      logInfo(
        'Категория создана: $categoryId',
        tag: 'PasswordService',
        data: {
          'categoryId': categoryId,
          'name': dto.name,
          'type': dto.type.name,
        },
      );

      return ServiceResult.success(
        data: categoryId,
        message: 'Категория "${dto.name}" создана',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания категории',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка создания категории: ${e.toString()}');
    }
  }

  /// Получение категорий для паролей
  Future<ServiceResult<List<Category>>> getPasswordCategories() async {
    try {
      final categories = await _categoriesDao.getCategoriesByType(
        CategoryType.password,
      );
      final mixedCategories = await _categoriesDao.getCategoriesByType(
        CategoryType.mixed,
      );

      final allCategories = [...categories, ...mixedCategories];

      return ServiceResult.success(
        data: allCategories,
        message: 'Категории получены',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения категорий',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка получения категорий: ${e.toString()}');
    }
  }

  // ==================== РАБОТА С ИСТОРИЕЙ ====================

  /// Получение истории пароля
  Future<ServiceResult<List<PasswordHistory>>> getPasswordHistory(
    String passwordId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final history = await _passwordHistoriesDao
          .getPasswordHistoryWithPagination(
            passwordId,
            limit: limit,
            offset: offset,
          );

      return ServiceResult.success(
        data: history,
        message: 'История пароля получена',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения истории пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка получения истории: ${e.toString()}');
    }
  }

  /// Очистка истории пароля
  Future<ServiceResult<int>> clearPasswordHistory(String passwordId) async {
    try {
      final clearedCount = await _passwordHistoriesDao.clearPasswordHistory(
        passwordId,
      );

      logInfo(
        'История пароля очищена',
        tag: 'PasswordService',
        data: {'passwordId': passwordId, 'clearedCount': clearedCount},
      );

      return ServiceResult.success(
        data: clearedCount,
        message: 'Очищено записей истории: $clearedCount',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка очистки истории пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка очистки истории: ${e.toString()}');
    }
  }

  // ==================== СТАТИСТИКА ====================

  /// Получение статистики паролей
  Future<ServiceResult<PasswordStatistics>> getPasswordStatistics() async {
    try {
      final totalCount = await _passwordsDao.getPasswordsCount();
      final favoritePasswords = await _passwordsDao.getFavoritePasswords();
      final countByCategory = await _passwordsDao.getPasswordsCountByCategory();
      final tagCounts = await _passwordTagsDao.getPasswordCountPerTag();

      // Получаем категории для отображения имен
      final categories = await _categoriesDao.getAllCategories();
      final categoryMap = {for (final cat in categories) cat.id: cat.name};

      // Получаем теги для отображения имен
      final tags = await _tagsDao.getAllTags();
      final tagMap = {for (final tag in tags) tag.id: tag.name};

      final statistics = PasswordStatistics(
        totalCount: totalCount,
        favoriteCount: favoritePasswords.length,
        countByCategory: countByCategory.map(
          (categoryId, count) =>
              MapEntry(categoryMap[categoryId] ?? 'Без категории', count),
        ),
        countByTag: tagCounts.map(
          (tagId, count) => MapEntry(tagMap[tagId] ?? 'Неизвестный тег', count),
        ),
      );

      return ServiceResult.success(
        data: statistics,
        message: 'Статистика получена',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения статистики',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error(
        'Ошибка получения статистики: ${e.toString()}',
      );
    }
  }

  // ==================== BATCH ОПЕРАЦИИ ====================

  /// Массовое создание паролей
  Future<ServiceResult<bool>> createPasswordsBatch(
    List<CreatePasswordDto> dtos,
  ) async {
    try {
      logInfo(
        'Массовое создание паролей: ${dtos.length}',
        tag: 'PasswordService',
      );

      await _passwordsDao.createPasswordsBatch(dtos);

      logInfo(
        'Массовое создание завершено',
        tag: 'PasswordService',
        data: {'count': dtos.length},
      );

      return ServiceResult.success(
        data: true,
        message: 'Создано паролей: ${dtos.length}',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка массового создания паролей',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка массового создания: ${e.toString()}');
    }
  }

  /// Массовое добавление тегов к паролям
  Future<ServiceResult<bool>> addTagsToPasswordsBatch(
    List<String> passwordIds,
    List<String> tagIds,
  ) async {
    try {
      await _passwordTagsDao.addTagsToPasswordsBatch(passwordIds, tagIds);

      logInfo(
        'Массовое добавление тегов завершено',
        tag: 'PasswordService',
        data: {
          'passwordsCount': passwordIds.length,
          'tagsCount': tagIds.length,
        },
      );

      return ServiceResult.success(
        data: true,
        message: 'Теги добавлены к ${passwordIds.length} паролям',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка массового добавления тегов',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка добавления тегов: ${e.toString()}');
    }
  }

  // ==================== STREAM МЕТОДЫ ДЛЯ UI ====================

  /// Stream всех паролей для наблюдения в UI
  Stream<List<Password>> watchAllPasswords() {
    return _passwordsDao.watchAllPasswords();
  }

  /// Stream избранных паролей
  Stream<List<Password>> watchFavoritePasswords() {
    return _passwordsDao.watchFavoritePasswords();
  }

  /// Stream паролей по категории
  Stream<List<Password>> watchPasswordsByCategory(String categoryId) {
    return _passwordsDao.watchPasswordsByCategory(categoryId);
  }

  /// Stream тегов для конкретного пароля
  Stream<List<Tag>> watchPasswordTags(String passwordId) {
    return _passwordTagsDao.watchTagsForPassword(passwordId);
  }

  /// Stream паролей для конкретного тега
  Stream<List<Password>> watchPasswordsByTag(String tagId) {
    return _passwordTagsDao.watchPasswordsForTag(tagId);
  }

  // ==================== ФИЛЬТРАЦИЯ ПАРОЛЕЙ ====================

  /// Получение отфильтрованных паролей как карточек
  Future<ServiceResult<List<CardPasswordDto>>> getFilteredPasswords(
    PasswordFilter filter,
  ) async {
    try {
      logDebug('Получение отфильтрованных паролей', tag: 'PasswordService');

      final passwordCards = await _passwordsDao.getFilteredPasswords(filter);

      return ServiceResult.success(
        data: passwordCards,
        message: 'Пароли отфильтрованы успешно',
      );
    } catch (e) {
      logError(
        'Ошибка получения отфильтрованных паролей: $e',
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка фильтрации паролей: ${e.toString()}');
    }
  }

  /// Подсчет количества паролей по фильтру
  Future<ServiceResult<int>> countFilteredPasswords(
    PasswordFilter filter,
  ) async {
    try {
      final count = await _passwordsDao.countFilteredPasswords(filter);
      return ServiceResult.success(
        data: count,
        message: 'Количество паролей подсчитано',
      );
    } catch (e) {
      return ServiceResult.error('Ошибка подсчета паролей: ${e.toString()}');
    }
  }

  /// Stream отфильтрованных паролей как карточек
  Stream<List<CardPasswordDto>> watchFilteredPasswords(PasswordFilter filter) {
    return _passwordsDao.watchFilteredPasswords(filter);
  }

  /// Быстрый поиск паролей
  Future<ServiceResult<List<CardPasswordDto>>> quickSearchPasswords(
    String query, {
    int limit = 50,
  }) async {
    final filter = PasswordFilter.create(
      query: query,
      limit: limit,
      sortField: PasswordSortField.modifiedAt,
      sortDirection: SortDirection.desc,
    );

    return await getFilteredPasswords(filter);
  }

  // ==================== УТИЛИТАРНЫЕ МЕТОДЫ ====================

  /// Очистка потерянных связей (orphaned relations)
  Future<ServiceResult<int>> cleanupOrphanedRelations() async {
    try {
      final cleaned = await _passwordTagsDao.cleanupOrphanedRelations();

      logInfo(
        'Очистка потерянных связей завершена',
        tag: 'PasswordService',
        data: {'cleanedCount': cleaned},
      );

      return ServiceResult.success(
        data: cleaned,
        message: 'Очищено связей: $cleaned',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка очистки связей',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка очистки: ${e.toString()}');
    }
  }

  /// Проверка целостности данных
  Future<ServiceResult<Map<String, dynamic>>> validateDataIntegrity() async {
    try {
      logInfo('Проверка целостности данных паролей', tag: 'PasswordService');

      final issues = <String, dynamic>{};

      // Проверяем пароли с несуществующими категориями
      final allPasswords = await _passwordsDao.getAllPasswords();
      final orphanedPasswords = <String>[];

      for (final password in allPasswords) {
        if (password.categoryId != null) {
          final category = await _categoriesDao.getCategoryById(
            password.categoryId!,
          );
          if (category == null) {
            orphanedPasswords.add(password.id);
          }
        }
      }

      issues['passwordsWithMissingCategories'] = orphanedPasswords;

      // Проверяем потерянные связи password_tags
      final orphanedRelations = await _passwordTagsDao
          .cleanupOrphanedRelations();
      issues['orphanedTagRelations'] = orphanedRelations;

      logInfo(
        'Проверка целостности завершена',
        tag: 'PasswordService',
        data: issues,
      );

      return ServiceResult.success(
        data: issues,
        message: 'Проверка целостности завершена',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка проверки целостности',
        error: e,
        stackTrace: stackTrace,
        tag: 'PasswordService',
      );
      return ServiceResult.error('Ошибка проверки: ${e.toString()}');
    }
  }
}

// ==================== МОДЕЛИ ДЛЯ СЕРВИСА ====================

/// Модель пароля с дополнительной информацией
class PasswordWithDetails {
  final Password password;
  final List<Tag> tags;
  final Category? category;
  final int historyCount;

  PasswordWithDetails({
    required this.password,
    required this.tags,
    this.category,
    required this.historyCount,
  });
}

/// Модель статистики паролей
class PasswordStatistics {
  final int totalCount;
  final int favoriteCount;
  final Map<String, int> countByCategory;
  final Map<String, int> countByTag;

  PasswordStatistics({
    required this.totalCount,
    required this.favoriteCount,
    required this.countByCategory,
    required this.countByTag,
  });
}

/// Результат поиска паролей с метаданными
class PasswordSearchResult {
  final List<PasswordWithDetails> passwords;
  final int? totalCount;
  final PasswordFilter filter;
  final bool hasMore;

  PasswordSearchResult({
    required this.passwords,
    this.totalCount,
    required this.filter,
    required this.hasMore,
  });
}
