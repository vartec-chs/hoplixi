import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_manager.dart';
import 'package:hoplixi/hoplixi_store/models/database_entry.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/state.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Контроллер для главного экрана
class HomeController extends ChangeNotifier {
  final HoplixiStoreManager _storeManager;

  DatabaseEntry? _recentDatabase;
  bool _isLoading = false;
  String? _error;
  bool _isAutoOpening = false;

  HomeController({HoplixiStoreManager? storeManager})
    : _storeManager = storeManager ?? HoplixiStoreManager();

  // Геттеры
  DatabaseEntry? get recentDatabase => _recentDatabase;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAutoOpening => _isAutoOpening;
  bool get hasRecentDatabase => _recentDatabase != null;
  bool get canAutoOpen =>
      _recentDatabase?.saveMasterPassword == true &&
      _recentDatabase?.masterPassword?.isNotEmpty == true;

  /// Инициализация контроллера
  Future<void> initialize() async {
    await _loadRecentDatabase();
  }

  //TODO: Warning: Failed to read record c:\users\vartec\documents\hoplixi\storages\test.hpl: SegmentCorruptError: Failed to read record c:\users\vartec\documents\hoplixi\storages\test.hpl: SegmentCorruptError: Checksum mismatch for record c:\users\vartec\documents\hoplixi\storages\test.hpl. Expected: 00f196da6deab6710e27613c6a2ecf6d49a274ac9661b267df82041d0fe6e06a, Got: 424a4d76e586a1f8bec3fba947ef5a1348267fd5f0ca30f8a8086fafa6465a04 исправить работу с конкурентными блокировками

  /// Загружает информацию о недавно открытой базе данных
  Future<void> _loadRecentDatabase() async {
    try {
      _setLoading(true);
      _clearError();

      logDebug('Загрузка недавней базы данных', tag: 'HomeController');

      // Получаем самую недавно открытую базу данных из истории
      final history = await _storeManager.getDatabaseHistory();

      if (history.isNotEmpty) {
        _recentDatabase = history.first;
        logDebug(
          'Найдена недавняя БД: ${_recentDatabase!.name}',
          tag: 'HomeController',
          data: {
            'path': _recentDatabase!.path,
            'hasSavedPassword': _recentDatabase!.saveMasterPassword,
          },
        );
      } else {
        _recentDatabase = null;
        logDebug('Недавние базы данных не найдены', tag: 'HomeController');
      }
    } catch (e, stackTrace) {
      _setError('Ошибка загрузки недавней базы данных: ${e.toString()}');
      logError(
        'Ошибка загрузки недавней базы данных',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Автоматическое открытие базы данных (если пароль сохранен)
  Future<DatabaseState?> autoOpenRecentDatabase() async {
    if (!canAutoOpen) {
      logWarning(
        'Автоматическое открытие недоступно',
        tag: 'HomeController',
        data: {
          'hasRecentDb': hasRecentDatabase,
          'hasSavedPassword': _recentDatabase?.saveMasterPassword ?? false,
        },
      );
      return null;
    }

    try {
      _setAutoOpening(true);
      _clearError();

      logInfo(
        'Автоматическое открытие БД: ${_recentDatabase!.name}',
        tag: 'HomeController',
        data: {'path': _recentDatabase!.path},
      );

      final openDto = OpenDatabaseDto(
        path: _recentDatabase!.path,
        masterPassword: _recentDatabase!.masterPassword!,
        saveMasterPassword: true,
      );

      final result = await _storeManager.openDatabase(openDto);

      logInfo(
        'БД автоматически открыта успешно',
        tag: 'HomeController',
        data: {'status': result.status.toString()},
      );

      // Обновляем информацию о недавней базе данных
      await _safeReloadHistory();

      return result;
    } catch (e, stackTrace) {
      final errorMessage = 'Ошибка автоматического открытия: ${e.toString()}';
      _setError(errorMessage);

      logError(
        'Ошибка автоматического открытия БД',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
        data: {'path': _recentDatabase?.path},
      );

      return null;
    } finally {
      _setAutoOpening(false);
    }
  }

  /// Открытие базы данных с введенным паролем
  Future<DatabaseState?> openRecentDatabaseWithPassword(String password) async {
    if (!hasRecentDatabase) {
      _setError('Недавняя база данных не найдена');
      return null;
    }

    try {
      _setLoading(true);
      _clearError();

      logInfo(
        'Открытие БД с паролем: ${_recentDatabase!.name}',
        tag: 'HomeController',
        data: {'path': _recentDatabase!.path},
      );

      final openDto = OpenDatabaseDto(
        path: _recentDatabase!.path,
        masterPassword: password,
        saveMasterPassword: false, // Не сохраняем пароль по умолчанию
      );

      final result = await _storeManager.openDatabase(openDto);

      logInfo(
        'БД открыта успешно с введенным паролем',
        tag: 'HomeController',
        data: {'status': result.status.toString()},
      );

      // Обновляем информацию о недавней базе данных
      await _safeReloadHistory();

      return result;
    } catch (e, stackTrace) {
      final errorMessage = 'Ошибка открытия: ${e.toString()}';
      _setError(errorMessage);

      logError(
        'Ошибка открытия БД с паролем',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
        data: {'path': _recentDatabase?.path},
      );

      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Открытие базы данных с сохранением пароля
  Future<DatabaseState?> openRecentDatabaseWithPasswordAndSave(
    String password,
  ) async {
    if (!hasRecentDatabase) {
      _setError('Недавняя база данных не найдена');
      return null;
    }

    try {
      _setLoading(true);
      _clearError();

      logInfo(
        'Открытие БД с сохранением пароля: ${_recentDatabase!.name}',
        tag: 'HomeController',
        data: {'path': _recentDatabase!.path},
      );

      final openDto = OpenDatabaseDto(
        path: _recentDatabase!.path,
        masterPassword: password,
        saveMasterPassword: true, // Сохраняем пароль
      );

      final result = await _storeManager.openDatabase(openDto);

      logInfo(
        'БД открыта успешно с сохранением пароля',
        tag: 'HomeController',
        data: {'status': result.status.toString()},
      );

      // Обновляем информацию о недавней базе данных
      await _safeReloadHistory();

      return result;
    } catch (e, stackTrace) {
      final errorMessage = 'Ошибка открытия: ${e.toString()}';
      _setError(errorMessage);

      logError(
        'Ошибка открытия БД с сохранением пароля',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
        data: {'path': _recentDatabase?.path},
      );

      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Удаляет недавнюю базу данных из истории
  Future<void> removeRecentDatabase() async {
    if (!hasRecentDatabase) return;

    try {
      _setLoading(true);
      _clearError();

      await _storeManager.removeDatabaseHistoryEntry(_recentDatabase!.path);

      logInfo(
        'БД удалена из истории: ${_recentDatabase!.name}',
        tag: 'HomeController',
        data: {'path': _recentDatabase!.path},
      );

      // Перезагружаем список
      await _safeReloadHistory();
    } catch (e, stackTrace) {
      _setError('Ошибка удаления из истории: ${e.toString()}');
      logError(
        'Ошибка удаления БД из истории',
        error: e,
        stackTrace: stackTrace,
        tag: 'HomeController',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Получает статистику истории
  Future<Map<String, dynamic>> getHistoryStats() async {
    try {
      return await _storeManager.getDatabaseHistoryStats();
    } catch (e) {
      logError(
        'Ошибка получения статистики истории',
        error: e,
        tag: 'HomeController',
      );
      return {
        'totalEntries': 0,
        'entriesWithSavedPasswords': 0,
        'oldestEntry': null,
        'newestEntry': null,
      };
    }
  }

  /// Безопасная перезагрузка истории БД с повторными попытками
  Future<void> _safeReloadHistory({int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await _loadRecentDatabase();
        return; // Успешно загружено
      } catch (e) {
        if (attempt == maxRetries - 1) {
          // Последняя попытка не удалась
          logError(
            'Не удалось загрузить историю БД после $maxRetries попыток',
            error: e,
            tag: 'HomeController',
          );
          _recentDatabase = null;
          notifyListeners();
          return;
        }

        // Ждем перед следующей попыткой
        await Future.delayed(Duration(milliseconds: 200 * (attempt + 1)));
      }
    }
  }

  /// Обновляет состояние загрузки
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Обновляет состояние автоматического открытия
  void _setAutoOpening(bool autoOpening) {
    if (_isAutoOpening != autoOpening) {
      _isAutoOpening = autoOpening;
      notifyListeners();
    }
  }

  /// Устанавливает ошибку
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Очищает ошибку
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Освобождение ресурсов
  @override
  void dispose() {
    // Здесь можно добавить очистку ресурсов если потребуется
    super.dispose();
  }
}
