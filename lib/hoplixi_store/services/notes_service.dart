import 'dart:async';
import '../../core/logger/app_logger.dart';
import '../hoplixi_store.dart';
import '../dao/notes_dao.dart';
import '../dao/categories_dao.dart';
import '../dto/db_dto.dart';
import '../enums/entity_types.dart';
import 'service_results.dart';

/// Полный сервис для работы с заметками, включающий:
/// - CRUD операции с заметками
/// - Управление категориями
/// - Поиск и фильтрацию
/// - Stream-подписки для UI
/// - Работу с избранным и закреплением
class NotesService {
  final HoplixiStore _database;
  late final NotesDao _notesDao;
  late final CategoriesDao _categoriesDao;

  NotesService(this._database) {
    _notesDao = NotesDao(_database);
    _categoriesDao = CategoriesDao(_database);
  }

  // ==================== ОСНОВНЫЕ CRUD ОПЕРАЦИИ ====================

  /// Создание новой заметки
  Future<ServiceResult<String>> createNote(CreateNoteDto dto) async {
    try {
      logInfo('Создание новой заметки: ${dto.title}', tag: 'NotesService');

      // Проверяем существование категории если указана
      if (dto.categoryId != null) {
        final categoryExists = await _categoriesDao.getCategoryById(
          dto.categoryId!,
        );
        if (categoryExists == null) {
          return ServiceResult.error('Категория не найдена');
        }
      }

      // TODO: В будущем здесь будет обработка вложений (attachments)
      // Сейчас игнорируем dto.attachments - заглушка

      // Создаем заметку
      final noteId = await _notesDao.createNote(dto);

      logInfo(
        'Заметка создана успешно: $noteId',
        tag: 'NotesService',
        data: {'noteId': noteId, 'title': dto.title},
      );

      return ServiceResult.success(
        data: noteId,
        message: 'Заметка "${dto.title}" создана успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания заметки',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка создания заметки: ${e.toString()}');
    }
  }

  /// Обновление заметки
  Future<ServiceResult<bool>> updateNote(UpdateNoteDto dto) async {
    try {
      logInfo('Обновление заметки: ${dto.id}', tag: 'NotesService');

      // Проверяем существование заметки
      final existingNote = await _notesDao.getNoteById(dto.id);
      if (existingNote == null) {
        return ServiceResult.error('Заметка не найдена');
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

      // Обновляем заметку
      final updated = await _notesDao.updateNote(dto);

      if (!updated) {
        return ServiceResult.error('Не удалось обновить заметку');
      }

      logInfo(
        'Заметка обновлена успешно: ${dto.id}',
        tag: 'NotesService',
        data: {'noteId': dto.id, 'title': dto.title},
      );

      return ServiceResult.success(
        data: true,
        message: 'Заметка обновлена успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка обновления заметки',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка обновления заметки: ${e.toString()}');
    }
  }

  /// Удаление заметки
  Future<ServiceResult<bool>> deleteNote(String noteId) async {
    try {
      logInfo('Удаление заметки: $noteId', tag: 'NotesService');

      // Проверяем существование заметки
      final existingNote = await _notesDao.getNoteById(noteId);
      if (existingNote == null) {
        return ServiceResult.error('Заметка не найдена');
      }

      // Удаляем заметку
      final deleted = await _notesDao.deleteNote(noteId);
      if (!deleted) {
        return ServiceResult.error('Не удалось удалить заметку');
      }

      logInfo(
        'Заметка удалена успешно: $noteId',
        tag: 'NotesService',
        data: {'noteId': noteId, 'title': existingNote.title},
      );

      return ServiceResult.success(
        data: true,
        message: 'Заметка "${existingNote.title}" удалена успешно',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка удаления заметки',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка удаления заметки: ${e.toString()}');
    }
  }

  /// Получение заметки по ID с подробной информацией
  Future<ServiceResult<NoteWithDetails>> getNoteDetails(String noteId) async {
    try {
      logDebug('Получение деталей заметки: $noteId', tag: 'NotesService');

      final note = await _notesDao.getNoteById(noteId);
      if (note == null) {
        return ServiceResult.error('Заметка не найдена');
      }

      // Получаем дополнительную информацию
      final category = note.categoryId != null
          ? await _categoriesDao.getCategoryById(note.categoryId!)
          : null;

      // Обновляем время последнего доступа
      await _notesDao.updateLastAccessed(noteId);

      final details = NoteWithDetails(note: note, category: category);

      return ServiceResult.success(
        data: details,
        message: 'Детали заметки получены',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения деталей заметки',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка получения заметки: ${e.toString()}');
    }
  }

  /// Получение самой заметки по ID
  Future<ServiceResult<Note>> getNoteById(String noteId) async {
    try {
      final note = await _notesDao.getNoteById(noteId);
      if (note == null) {
        return ServiceResult.error('Заметка не найдена');
      }

      return ServiceResult.success(data: note, message: 'Заметка получена');
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения заметки',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка получения заметки: ${e.toString()}');
    }
  }

  // ==================== ПОИСК И ФИЛЬТРАЦИЯ ====================

  /// Получение всех заметок
  Future<ServiceResult<List<Note>>> getAllNotes() async {
    try {
      final notes = await _notesDao.getAllNotes();

      return ServiceResult.success(
        data: notes,
        message: 'Получено заметок: ${notes.length}',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения всех заметок',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка получения заметок: ${e.toString()}');
    }
  }

  /// Получение заметок по категории
  Future<ServiceResult<List<Note>>> getNotesByCategory(
    String categoryId,
  ) async {
    try {
      // Проверяем существование категории
      final categoryExists = await _categoriesDao.getCategoryById(categoryId);
      if (categoryExists == null) {
        return ServiceResult.error('Категория не найдена');
      }

      final notes = await _notesDao.getNotesByCategory(categoryId);

      return ServiceResult.success(
        data: notes,
        message: 'Найдено заметок в категории: ${notes.length}',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения заметок по категории',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка получения заметок: ${e.toString()}');
    }
  }

  /// Получение избранных заметок
  Future<ServiceResult<List<Note>>> getFavoriteNotes() async {
    try {
      final notes = await _notesDao.getFavoriteNotes();

      return ServiceResult.success(
        data: notes,
        message: 'Найдено избранных заметок: ${notes.length}',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения избранных заметок',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка получения заметок: ${e.toString()}');
    }
  }

  /// Получение закрепленных заметок
  Future<ServiceResult<List<Note>>> getPinnedNotes() async {
    try {
      final notes = await _notesDao.getPinnedNotes();

      return ServiceResult.success(
        data: notes,
        message: 'Найдено закрепленных заметок: ${notes.length}',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения закрепленных заметок',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка получения заметок: ${e.toString()}');
    }
  }

  /// Поиск заметок по заголовку или содержимому
  Future<ServiceResult<List<Note>>> searchNotes(String searchTerm) async {
    try {
      if (searchTerm.isEmpty) {
        return await getAllNotes();
      }

      logDebug('Поиск заметок по запросу: $searchTerm', tag: 'NotesService');

      final notes = await _notesDao.searchNotes(searchTerm);

      return ServiceResult.success(
        data: notes,
        message: 'Найдено заметок по запросу "$searchTerm": ${notes.length}',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка поиска заметок',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка поиска заметок: ${e.toString()}');
    }
  }

  /// Получение недавно просмотренных заметок
  Future<ServiceResult<List<Note>>> getRecentlyAccessedNotes({
    int limit = 10,
  }) async {
    try {
      final notes = await _notesDao.getRecentlyAccessedNotes(limit: limit);

      return ServiceResult.success(
        data: notes,
        message: 'Недавно просмотренные заметки получены',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения недавно просмотренных заметок',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка получения данных: ${e.toString()}');
    }
  }

  // ==================== УПРАВЛЕНИЕ СТАТУСАМИ ====================

  /// Закрепление/открепление заметки
  Future<ServiceResult<bool>> togglePinNote(String noteId) async {
    try {
      final note = await _notesDao.getNoteById(noteId);
      if (note == null) {
        return ServiceResult.error('Заметка не найдена');
      }

      await _notesDao.togglePinNote(noteId);

      final newStatus = !note.isPinned;
      logInfo(
        'Статус закрепления изменен: $noteId -> $newStatus',
        tag: 'NotesService',
        data: {'noteId': noteId, 'isPinned': newStatus},
      );

      return ServiceResult.success(
        data: newStatus,
        message: newStatus ? 'Заметка закреплена' : 'Заметка откреплена',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка изменения статуса закрепления',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка изменения статуса: ${e.toString()}');
    }
  }

  /// Добавление/удаление из избранного
  Future<ServiceResult<bool>> toggleFavoriteNote(String noteId) async {
    try {
      final note = await _notesDao.getNoteById(noteId);
      if (note == null) {
        return ServiceResult.error('Заметка не найдена');
      }

      await _notesDao.toggleFavoriteNote(noteId);

      final newStatus = !note.isFavorite;
      logInfo(
        'Статус избранного изменен: $noteId -> $newStatus',
        tag: 'NotesService',
        data: {'noteId': noteId, 'isFavorite': newStatus},
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
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка изменения статуса: ${e.toString()}');
    }
  }

  // ==================== РАБОТА С КАТЕГОРИЯМИ ====================

  /// Создание новой категории для заметок
  Future<ServiceResult<String>> createCategory(CreateCategoryDto dto) async {
    try {
      logInfo('Создание категории: ${dto.name}', tag: 'NotesService');

      // Проверяем, что тип категории подходит для заметок
      if (dto.type != CategoryType.notes && dto.type != CategoryType.mixed) {
        return ServiceResult.error('Неверный тип категории для заметок');
      }

      final categoryId = await _categoriesDao.createCategory(dto);

      logInfo(
        'Категория создана: $categoryId',
        tag: 'NotesService',
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
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка создания категории: ${e.toString()}');
    }
  }

  /// Получение категорий для заметок
  Future<ServiceResult<List<Category>>> getNoteCategories() async {
    try {
      final categories = await _categoriesDao.getCategoriesByType(
        CategoryType.notes,
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
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка получения категорий: ${e.toString()}');
    }
  }

  // ==================== СТАТИСТИКА ====================

  /// Получение количества заметок
  Future<ServiceResult<int>> getNotesCount() async {
    try {
      final count = await _notesDao.getNotesCount();
      return ServiceResult.success(
        data: count,
        message: 'Количество заметок: $count',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения количества заметок',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error(
        'Ошибка получения статистики: ${e.toString()}',
      );
    }
  }

  /// Получение количества заметок по категориям
  Future<ServiceResult<Map<String?, int>>> getNotesCountByCategory() async {
    try {
      final countByCategory = await _notesDao.getNotesCountByCategory();

      return ServiceResult.success(
        data: countByCategory,
        message: 'Статистика по категориям получена',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения статистики по категориям',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error(
        'Ошибка получения статистики: ${e.toString()}',
      );
    }
  }

  /// Получение статистики заметок
  Future<ServiceResult<NoteStatistics>> getNoteStatistics() async {
    try {
      final totalCount = await _notesDao.getNotesCount();
      final favoriteNotes = await _notesDao.getFavoriteNotes();
      final pinnedNotes = await _notesDao.getPinnedNotes();
      final countByCategory = await _notesDao.getNotesCountByCategory();

      // Получаем категории для отображения имен
      final categories = await _categoriesDao.getAllCategories();
      final categoryMap = {for (final cat in categories) cat.id: cat.name};

      final statistics = NoteStatistics(
        totalCount: totalCount,
        favoriteCount: favoriteNotes.length,
        pinnedCount: pinnedNotes.length,
        countByCategory: countByCategory.map(
          (categoryId, count) =>
              MapEntry(categoryMap[categoryId] ?? 'Без категории', count),
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
        tag: 'NotesService',
      );
      return ServiceResult.error(
        'Ошибка получения статистики: ${e.toString()}',
      );
    }
  }

  // ==================== BATCH ОПЕРАЦИИ ====================

  /// Массовое создание заметок
  Future<ServiceResult<bool>> createNotesBatch(List<CreateNoteDto> dtos) async {
    try {
      logInfo('Массовое создание заметок: ${dtos.length}', tag: 'NotesService');

      await _notesDao.createNotesBatch(dtos);

      logInfo(
        'Массовое создание завершено',
        tag: 'NotesService',
        data: {'count': dtos.length},
      );

      return ServiceResult.success(
        data: true,
        message: 'Создано заметок: ${dtos.length}',
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка массового создания заметок',
        error: e,
        stackTrace: stackTrace,
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка массового создания: ${e.toString()}');
    }
  }

  // ==================== STREAM МЕТОДЫ ДЛЯ UI ====================

  /// Stream всех заметок для наблюдения в UI
  Stream<List<Note>> watchAllNotes() {
    return _notesDao.watchAllNotes();
  }

  /// Stream избранных заметок
  Stream<List<Note>> watchFavoriteNotes() {
    return _notesDao.watchFavoriteNotes();
  }

  /// Stream закрепленных заметок
  Stream<List<Note>> watchPinnedNotes() {
    return _notesDao.watchPinnedNotes();
  }

  /// Stream заметок по категории
  Stream<List<Note>> watchNotesByCategory(String categoryId) {
    return _notesDao.watchNotesByCategory(categoryId);
  }

  // ==================== УТИЛИТАРНЫЕ МЕТОДЫ ====================

  /// Проверка целостности данных
  Future<ServiceResult<Map<String, dynamic>>> validateDataIntegrity() async {
    try {
      logInfo('Проверка целостности данных заметок', tag: 'NotesService');

      final issues = <String, dynamic>{};

      // Проверяем заметки с несуществующими категориями
      final allNotes = await _notesDao.getAllNotes();
      final orphanedNotes = <String>[];

      for (final note in allNotes) {
        if (note.categoryId != null) {
          final category = await _categoriesDao.getCategoryById(
            note.categoryId!,
          );
          if (category == null) {
            orphanedNotes.add(note.id);
          }
        }
      }

      issues['notesWithMissingCategories'] = orphanedNotes;

      logInfo(
        'Проверка целостности завершена',
        tag: 'NotesService',
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
        tag: 'NotesService',
      );
      return ServiceResult.error('Ошибка проверки: ${e.toString()}');
    }
  }
}

// ==================== МОДЕЛИ ДЛЯ СЕРВИСА ====================

/// Модель заметки с дополнительной информацией
class NoteWithDetails {
  final Note note;
  final Category? category;

  NoteWithDetails({required this.note, this.category});
}

/// Модель статистики заметок
class NoteStatistics {
  final int totalCount;
  final int favoriteCount;
  final int pinnedCount;
  final Map<String, int> countByCategory;

  NoteStatistics({
    required this.totalCount,
    required this.favoriteCount,
    required this.pinnedCount,
    required this.countByCategory,
  });
}
