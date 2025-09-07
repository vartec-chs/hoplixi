/// Провайдеры для работы с базой данных Hoplixi Store
///
/// Этот файл содержит все Riverpod провайдеры для работы с базой данных,
/// включая DAO провайдеры, stream провайдеры и статистические провайдеры.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/errors/db_errors.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_manager.dart';
import 'package:hoplixi/hoplixi_store/state.dart';
import 'package:hoplixi/hoplixi_store/dao/index.dart';
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/services/history_service.dart';

final hoplixiStoreManagerProvider = Provider<HoplixiStoreManager>((ref) {
  final manager = HoplixiStoreManager();

  // Cleanup on dispose
  ref.onDispose(() {
    logInfo(
      'Освобождение ресурсов databaseManagerProvider',
      tag: 'DatabaseProviders',
    );
    manager.dispose();
  });

  return manager;
});

final databaseStateProvider =
    StateNotifierProvider<DatabaseStateNotifier, DatabaseState>((ref) {
      final manager = ref.read(hoplixiStoreManagerProvider);
      return DatabaseStateNotifier(manager);
    });

/// Нотификатор состояния базы данных (новая версия)
class DatabaseStateNotifier extends StateNotifier<DatabaseState> {
  final HoplixiStoreManager _manager;

  DatabaseStateNotifier(this._manager) : super(const DatabaseState());

  /// Создает новую базу данных
  Future<void> createDatabase(CreateDatabaseDto dto) async {
    try {
      state = state.copyWith(status: DatabaseStatus.loading);
      final newState = await _manager.createDatabase(dto);
      state = newState;
      logInfo(
        'База данных создана успешно',
        tag: 'DatabaseStateNotifier',
        data: {'name': dto.name},
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка создания базы данных',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'name': dto.name},
        stackTrace: stackTrace,
      );
      state = DatabaseState(
        status: DatabaseStatus.error,
        error: e is DatabaseError
            ? e
            : DatabaseError.unknown(
                message: 'Unknown database error',
                stackTrace: stackTrace,
                details: e.toString(),
              ),
      );
      rethrow;
    }
  }

  /// Открывает существующую базу данных
  Future<void> openDatabase(OpenDatabaseDto dto) async {
    try {
      state = state.copyWith(status: DatabaseStatus.loading);
      final newState = await _manager.openDatabase(dto);
      state = newState;
      logInfo(
        'База данных открыта успешно',
        tag: 'DatabaseStateNotifier',
        data: {'path': dto.path},
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка открытия базы данных',
        error: e,
        tag: 'DatabaseStateNotifier',
        data: {'path': dto.path},
        stackTrace: stackTrace,
      );
      state = DatabaseState(
        status: DatabaseStatus.error,
        error: e is DatabaseError
            ? e
            : DatabaseError.unknown(
                message: 'Unknown database error',
                stackTrace: stackTrace,
                details: e.toString(),
              ),
      );
      rethrow;
    }
  }

  /// Закрывает текущую базу данных
  Future<void> closeDatabase() async {
    try {
      final newState = await _manager.closeDatabase();
      state = newState;
      logInfo('База данных закрыта успешно', tag: 'DatabaseStateNotifier');
    } catch (e) {
      logError(
        'Ошибка закрытия базы данных',
        error: e,
        tag: 'DatabaseStateNotifier',
      );
      // В случае ошибки закрытия, все равно считаем БД закрытой
      state = const DatabaseState(status: DatabaseStatus.closed);
    }
  }

  // текущее состояние базы данных
  DatabaseState get currentState => state;

  // /// Попытка автологина
  // Future<bool> tryAutoLogin(String path) async {
  //   try {
  //     state = state.copyWith(status: DatabaseStatus.loading);
  //     final result = await _manager.openWithAutoLogin(path);
  //     if (result != null) {
  //       state = result;
  //       logInfo(
  //         'Автологин успешен',
  //         tag: 'DatabaseStateNotifier',
  //         data: {'path': path},
  //       );
  //       return true;
  //     } else {
  //       state = const DatabaseState(status: DatabaseStatus.closed);
  //       logDebug(
  //         'Автологин не удался',
  //         tag: 'DatabaseStateNotifier',
  //         data: {'path': path},
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     logError(
  //       'Ошибка автологина',
  //       error: e,
  //       tag: 'DatabaseStateNotifier',
  //       data: {'path': path},
  //     );
  //     state = DatabaseState(
  //       status: DatabaseStatus.error,
  //       error: e is DatabaseError ? e.toString() : e.toString(),
  //     );
  //     return false;
  //   }
  // }

  // /// Умное открытие базы данных
  // Future<bool> smartOpen(String path, [String? providedPassword]) async {
  //   try {
  //     state = state.copyWith(status: DatabaseStatus.loading);
  //     final result = await _manager.smartOpen(path, providedPassword);
  //     if (result != null) {
  //       state = result;
  //       logInfo(
  //         'Умное открытие успешно',
  //         tag: 'DatabaseStateNotifier',
  //         data: {'path': path},
  //       );
  //       return true;
  //     } else {
  //       state = const DatabaseState(status: DatabaseStatus.closed);
  //       logDebug(
  //         'Умное открытие не удалось',
  //         tag: 'DatabaseStateNotifier',
  //         data: {'path': path},
  //       );
  //       return false;
  //     }
  //   } catch (e) {
  //     logError(
  //       'Ошибка умного открытия',
  //       error: e,
  //       tag: 'DatabaseStateNotifier',
  //       data: {'path': path},
  //     );
  //     state = DatabaseState(
  //       status: DatabaseStatus.error,
  //       error: e is DatabaseError ? e.toString() : e.toString(),
  //     );
  //     return false;
  //   }
  // }

  // /// Проверка возможности автологина
  // Future<bool> canAutoLogin(String path) async {
  //   try {
  //     return await _manager.canAutoLogin(path);
  //   } catch (e) {
  //     logError(
  //       'Ошибка проверки возможности автологина',
  //       error: e,
  //       tag: 'DatabaseStateNotifier',
  //       data: {'path': path},
  //     );
  //     return false;
  //   }
  // }

  /// Выбор файла базы данных
  // Future<String?> pickDatabaseFile() async {
  //   try {
  //     return await _manager.pickDatabaseFile();
  //   } catch (e) {
  //     logError(
  //       'Ошибка выбора файла базы данных',
  //       error: e,
  //       tag: 'DatabaseStateNotifier',
  //     );
  //     return null;
  //   }
  // }

  /// Сброс состояния в начальное
  void reset() {
    state = const DatabaseState();
  }

  /// Установка состояния ошибки
  void setError(DatabaseError error) {
    state = DatabaseState(status: DatabaseStatus.error, error: error);
  }
}

// =============================================================================
// DAO ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер для PasswordsDao
final passwordsDaoProvider = Provider<PasswordsDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getPasswordsDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing PasswordsDao',
      stackTrace: StackTrace.current,
    );
  }

  return PasswordsDao(manager.database!);
});

/// Провайдер для NotesDao
final notesDaoProvider = Provider<NotesDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getNotesDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing NotesDao',
      stackTrace: StackTrace.current,
    );
  }

  return NotesDao(manager.database!);
});

/// Провайдер для CategoriesDao
final categoriesDaoProvider = Provider<CategoriesDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getCategoriesDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing CategoriesDao',
      stackTrace: StackTrace.current,
    );
  }

  return CategoriesDao(manager.database!);
});

/// Провайдер для TagsDao
final tagsDaoProvider = Provider<TagsDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getTagsDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing TagsDao',
      stackTrace: StackTrace.current,
    );
  }

  return TagsDao(manager.database!);
});

/// Провайдер для TotpsDao
final totpsDaoProvider = Provider<TotpsDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getTotpsDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing TotpsDao',
      stackTrace: StackTrace.current,
    );
  }

  return TotpsDao(manager.database!);
});

/// Провайдер для IconsDao
final iconsDaoProvider = Provider<IconsDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getIconsDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing IconsDao',
      stackTrace: StackTrace.current,
    );
  }

  return IconsDao(manager.database!);
});

/// Провайдер для AttachmentsDao
final attachmentsDaoProvider = Provider<AttachmentsDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getAttachmentsDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing AttachmentsDao',
      stackTrace: StackTrace.current,
    );
  }

  return AttachmentsDao(manager.database!);
});

/// Провайдер для PasswordTagsDao
final passwordTagsDaoProvider = Provider<PasswordTagsDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getPasswordTagsDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing PasswordTagsDao',
      stackTrace: StackTrace.current,
    );
  }

  return PasswordTagsDao(manager.database!);
});

/// Провайдер для NoteTagsDao
final noteTagsDaoProvider = Provider<NoteTagsDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getNoteTagsDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing NoteTagsDao',
      stackTrace: StackTrace.current,
    );
  }

  return NoteTagsDao(manager.database!);
});

/// Провайдер для TotpTagsDao
final totpTagsDaoProvider = Provider<TotpTagsDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getTotpTagsDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing TotpTagsDao',
      stackTrace: StackTrace.current,
    );
  }

  return TotpTagsDao(manager.database!);
});

// =============================================================================
// ИСТОРИЯ DAO ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер для PasswordHistoriesDao
final passwordHistoriesDaoProvider = Provider<PasswordHistoriesDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getPasswordHistoriesDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing PasswordHistoriesDao',
      stackTrace: StackTrace.current,
    );
  }

  return PasswordHistoriesDao(manager.database!);
});

/// Провайдер для NoteHistoriesDao
final noteHistoriesDaoProvider = Provider<NoteHistoriesDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getNoteHistoriesDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing NoteHistoriesDao',
      stackTrace: StackTrace.current,
    );
  }

  return NoteHistoriesDao(manager.database!);
});

/// Провайдер для TotpHistoriesDao
final totpHistoriesDaoProvider = Provider<TotpHistoriesDao>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getTotpHistoriesDao',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing TotpHistoriesDao',
      stackTrace: StackTrace.current,
    );
  }

  return TotpHistoriesDao(manager.database!);
});

/// Провайдер для HistoryService
final historyServiceProvider = Provider<HistoryService>((ref) {
  final manager = ref.watch(hoplixiStoreManagerProvider);
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || manager.database == null) {
    throw DatabaseError.operationFailed(
      operation: 'getHistoryService',
      details: 'Database is not open or not initialized',
      message: 'Database must be opened before accessing HistoryService',
      stackTrace: StackTrace.current,
    );
  }

  return HistoryService(manager.database!);
});

// =============================================================================
// STREAM ПРОВАЙДЕРЫ для часто используемых данных
// =============================================================================

/// Stream провайдер для всех паролей
final allPasswordsStreamProvider = StreamProvider((ref) {
  final dao = ref.watch(passwordsDaoProvider);
  return dao.watchAllPasswords();
});

/// Stream провайдер для избранных паролей
final favoritePasswordsStreamProvider = StreamProvider((ref) {
  final dao = ref.watch(passwordsDaoProvider);
  return dao.watchFavoritePasswords();
});

/// Stream провайдер для всех заметок
final allNotesStreamProvider = StreamProvider((ref) {
  final dao = ref.watch(notesDaoProvider);
  return dao.watchAllNotes();
});

/// Stream провайдер для избранных заметок
final favoriteNotesStreamProvider = StreamProvider((ref) {
  final dao = ref.watch(notesDaoProvider);
  return dao.watchFavoriteNotes();
});

/// Stream провайдер для закрепленных заметок
final pinnedNotesStreamProvider = StreamProvider((ref) {
  final dao = ref.watch(notesDaoProvider);
  return dao.watchPinnedNotes();
});

/// Stream провайдер для всех категорий
final allCategoriesStreamProvider = StreamProvider((ref) {
  final dao = ref.watch(categoriesDaoProvider);
  return dao.watchAllCategories();
});

/// Stream провайдер для всех тегов
final allTagsStreamProvider = StreamProvider((ref) {
  final dao = ref.watch(tagsDaoProvider);
  return dao.watchAllTags();
});

/// Stream провайдер для всех TOTP
final allTotpsStreamProvider = StreamProvider((ref) {
  final dao = ref.watch(totpsDaoProvider);
  return dao.watchAllTotps();
});

/// Stream провайдер для избранных TOTP
final favoriteTotpsStreamProvider = StreamProvider((ref) {
  final dao = ref.watch(totpsDaoProvider);
  return dao.watchFavoriteTotps();
});

// =============================================================================
// СЕМЕЙНЫЕ ПРОВАЙДЕРЫ для параметризованных запросов
// =============================================================================

/// Семейный провайдер для получения паролей по категории
final passwordsByCategoryProvider =
    StreamProvider.family<List<dynamic>, String>((ref, categoryId) {
      final dao = ref.watch(passwordsDaoProvider);
      return dao.watchPasswordsByCategory(categoryId);
    });

/// Семейный провайдер для получения заметок по категории
final notesByCategoryProvider = StreamProvider.family<List<dynamic>, String>((
  ref,
  categoryId,
) {
  final dao = ref.watch(notesDaoProvider);
  return dao.watchNotesByCategory(categoryId);
});

/// Семейный провайдер для получения TOTP по категории
final totpsByCategoryProvider = StreamProvider.family<List<dynamic>, String>((
  ref,
  categoryId,
) {
  final dao = ref.watch(totpsDaoProvider);
  return dao.watchTotpsByCategory(categoryId);
});

/// Семейный провайдер для получения категорий по типу
final categoriesByTypeProvider =
    StreamProvider.family<List<dynamic>, CategoryType>((ref, type) {
      final dao = ref.watch(categoriesDaoProvider);
      return dao.watchCategoriesByType(type);
    });

/// Семейный провайдер для получения тегов по типу
final tagsByTypeProvider = StreamProvider.family<List<dynamic>, TagType>((
  ref,
  type,
) {
  final dao = ref.watch(tagsDaoProvider);
  return dao.watchTagsByType(type);
});

/// Семейный провайдер для получения тегов пароля
final passwordTagsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  passwordId,
) async {
  final dao = ref.watch(passwordTagsDaoProvider);
  return dao.getTagsForPassword(passwordId);
});

/// Семейный провайдер для получения тегов заметки
final noteTagsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  noteId,
) async {
  final dao = ref.watch(noteTagsDaoProvider);
  return dao.getTagsForNote(noteId);
});

/// Семейный провайдер для получения тегов TOTP
final totpTagsProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  totpId,
) async {
  final dao = ref.watch(totpTagsDaoProvider);
  return dao.getTagsForTotp(totpId);
});

// =============================================================================
// СТАТИСТИЧЕСКИЕ ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер для статистики паролей
final passwordsStatsProvider = FutureProvider<PasswordsStats>((ref) async {
  final dao = ref.watch(passwordsDaoProvider);

  final totalCount = await dao.getPasswordsCount();
  final countByCategory = await dao.getPasswordsCountByCategory();

  return PasswordsStats(
    totalCount: totalCount,
    countByCategory: countByCategory,
  );
});

/// Провайдер для статистики заметок
final notesStatsProvider = FutureProvider<NotesStats>((ref) async {
  final dao = ref.watch(notesDaoProvider);

  final totalCount = await dao.getNotesCount();
  final countByCategory = await dao.getNotesCountByCategory();

  return NotesStats(totalCount: totalCount, countByCategory: countByCategory);
});

/// Провайдер для статистики категорий
final categoriesStatsProvider = FutureProvider<CategoriesStats>((ref) async {
  final dao = ref.watch(categoriesDaoProvider);

  final totalCount = await dao.getCategoriesCount();
  final countByType = await dao.getCategoriesCountByType();

  return CategoriesStats(totalCount: totalCount, countByType: countByType);
});

// =============================================================================
// ПРОВАЙДЕРЫ ИСТОРИИ
// =============================================================================

/// Провайдер для получения общей статистики истории
final historyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final historyService = ref.watch(historyServiceProvider);
  return await historyService.getOverallStatistics();
});

/// Семейный провайдер для получения истории пароля
final passwordHistoryProvider = StreamProvider.family<List<dynamic>, String>((
  ref,
  passwordId,
) {
  // Поскольку нет watchPasswordHistory, используем FutureProvider и периодически обновляем
  throw UnimplementedError('Требуется реализация Stream методов в DAO');
});

/// Семейный провайдер для получения истории заметки
final noteHistoryProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  noteId,
) async {
  final historyService = ref.watch(historyServiceProvider);
  return await historyService.getNoteHistory(noteId);
});

/// Семейный провайдер для получения истории TOTP
final totpHistoryProvider = FutureProvider.family<List<dynamic>, String>((
  ref,
  totpId,
) async {
  final historyService = ref.watch(historyServiceProvider);
  return await historyService.getTotpHistory(totpId);
});

/// Провайдер для недавней активности
final recentActivityProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final historyService = ref.watch(historyServiceProvider);
  return await historyService.getRecentActivity();
});

/// Семейный провайдер для поиска в истории
final historySearchProvider =
    FutureProvider.family<Map<String, List<dynamic>>, String>((
      ref,
      query,
    ) async {
      final historyService = ref.watch(historyServiceProvider);
      return await historyService.searchHistory(query);
    });

/// Семейный провайдер для статистики истории конкретного пароля
final passwordHistoryStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, passwordId) async {
      final historyService = ref.watch(historyServiceProvider);
      return await historyService.getPasswordHistoryStats(passwordId);
    });

/// Семейный провайдер для статистики истории конкретной заметки
final noteHistoryStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, noteId) async {
      final historyService = ref.watch(historyServiceProvider);
      return await historyService.getNoteHistoryStats(noteId);
    });

/// Семейный провайдер для статистики истории конкретного TOTP
final totpHistoryStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, totpId) async {
      final historyService = ref.watch(historyServiceProvider);
      return await historyService.getTotpHistoryStats(totpId);
    });

// =============================================================================
// КЛАССЫ ДЛЯ СТАТИСТИКИ
// =============================================================================

class PasswordsStats {
  final int totalCount;
  final Map<String?, int> countByCategory;

  const PasswordsStats({
    required this.totalCount,
    required this.countByCategory,
  });
}

class NotesStats {
  final int totalCount;
  final Map<String?, int> countByCategory;

  const NotesStats({required this.totalCount, required this.countByCategory});
}

class CategoriesStats {
  final int totalCount;
  final Map<String, int> countByType;

  const CategoriesStats({required this.totalCount, required this.countByType});
}

// =============================================================================
// ДОПОЛНИТЕЛЬНЫЕ ПОЛЕЗНЫЕ ПРОВАЙДЕРЫ
// =============================================================================

/// Провайдер для проверки, открыта ли база данных
final isDatabaseOpenProvider = Provider<bool>((ref) {
  final state = ref.watch(databaseStateProvider);
  return state.isOpen;
});

/// Провайдер для получения пути к текущей базе данных
final currentDatabasePathProvider = Provider<String?>((ref) {
  final state = ref.watch(databaseStateProvider);
  return state.path;
});

/// Провайдер для получения имени текущей базы данных
final currentDatabaseNameProvider = Provider<String?>((ref) {
  final state = ref.watch(databaseStateProvider);
  return state.name;
});

/// Провайдер для получения текущего статуса базы данных
final databaseStatusProvider = Provider<DatabaseStatus>((ref) {
  final state = ref.watch(databaseStateProvider);
  return state.status;
});

/// Провайдер для проверки наличия ошибки в базе данных
final databaseErrorProvider = Provider<DatabaseError?>((ref) {
  final state = ref.watch(databaseStateProvider);
  return state.error;
});

/// Провайдер для подсчета общего количества всех элементов в базе данных
final totalItemsCountProvider = FutureProvider<int>((ref) async {
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen) {
    return 0;
  }

  try {
    final passwordsDao = ref.read(passwordsDaoProvider);
    final notesDao = ref.read(notesDaoProvider);
    final totpsDao = ref.read(totpsDaoProvider);

    final passwordsCount = await passwordsDao.getPasswordsCount();
    final notesCount = await notesDao.getNotesCount();
    final totpsCount = await totpsDao.getTotpsCount();

    return passwordsCount + notesCount + totpsCount;
  } catch (e) {
    logError(
      'Ошибка подсчета общего количества элементов',
      error: e,
      tag: 'DatabaseProviders',
    );
    return 0;
  }
});

/// Провайдер для проверки, есть ли данные в базе данных
final hasDatabaseDataProvider = FutureProvider<bool>((ref) async {
  final totalCount = await ref.watch(totalItemsCountProvider.future);
  return totalCount > 0;
});

/// Семейный провайдер для поиска по всем типам данных
final searchAllProvider = FutureProvider.family<SearchResults, String>((
  ref,
  query,
) async {
  final state = ref.watch(databaseStateProvider);

  if (!state.isOpen || query.trim().isEmpty) {
    return const SearchResults.empty();
  }

  try {
    final passwordsDao = ref.read(passwordsDaoProvider);
    final notesDao = ref.read(notesDaoProvider);
    final totpsDao = ref.read(totpsDaoProvider);

    final passwords = await passwordsDao.searchPasswords(query);
    final notes = await notesDao.searchNotes(query);
    final totps = await totpsDao.searchTotps(query);

    return SearchResults(passwords: passwords, notes: notes, totps: totps);
  } catch (e) {
    logError(
      'Ошибка поиска',
      error: e,
      tag: 'DatabaseProviders',
      data: {'query': query},
    );
    return const SearchResults.empty();
  }
});

/// Класс для результатов поиска
class SearchResults {
  final List<dynamic> passwords;
  final List<dynamic> notes;
  final List<dynamic> totps;

  const SearchResults({
    required this.passwords,
    required this.notes,
    required this.totps,
  });

  const SearchResults.empty()
    : passwords = const [],
      notes = const [],
      totps = const [];

  int get totalCount => passwords.length + notes.length + totps.length;
  bool get isEmpty => totalCount == 0;
  bool get isNotEmpty => totalCount > 0;
}
