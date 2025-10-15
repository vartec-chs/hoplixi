import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/models/import_session_state.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/import_dropbox_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:hoplixi/hoplixi_store/providers/providers.dart';

/// Провайдер для управления сессией импорта базы данных
class ImportSessionNotifier extends Notifier<ImportSessionState?> {
  static const String _tag = 'ImportSessionNotifier';

  @override
  ImportSessionState? build() {
    return null;
  }

  /// Начинает новую сессию импорта
  void startSession({
    required DatabaseMetaForSync metadata,
    required String clientKey,
    String? encryptionKeyArchive,
  }) {
    state = ImportSessionState(
      metadata: metadata,
      clientKey: clientKey,
      encryptionKeyArchive: encryptionKeyArchive,
      currentStep: ImportStep.checking,
      message: 'Проверка наличия обновлений...',
    );

    logInfo(
      'Начата новая сессия импорта',
      tag: _tag,
      data: {'dbId': metadata.id, 'dbName': metadata.name},
    );
  }

  /// Выполняет полный процесс импорта
  Future<void> executeImport() async {
    if (state == null) {
      logError('Попытка выполнить импорт без активной сессии', tag: _tag);
      return;
    }

    try {
      final currentState = state!;
      final oldDbPath = ref.read(stateProvider)?.path;
      final importService = await ref.read(importDropboxProvider.future);

      // Шаг 1: Проверка новой версии
      state = currentState.copyWith(
        currentStep: ImportStep.checking,
        progress: 0.1,
        message: 'Проверка наличия новой версии...',
      );

      final versionResult = await importService.checkForNewVersion(
        metadata: currentState.metadata,
        clientKey: currentState.clientKey,
      );

      if (!versionResult.success) {
        _setError('Ошибка проверки версии: ${versionResult.message}');
        return;
      }

      if (versionResult.data == null) {
        _setError('Новая версия не найдена в облаке');
        return;
      }

      state = currentState.copyWith(
        versionInfo: versionResult.data,
        progress: 0.2,
        message: 'Найдена новая версия',
      );

      logInfo(
        'Найдена новая версия для импорта',
        tag: _tag,
        data: {
          'timestamp': versionResult.data!.timestamp.toString(),
          'fileName': versionResult.data!.fileName,
        },
      );

      // Шаг 2: Скачивание архива
      state = state!.copyWith(
        currentStep: ImportStep.downloading,
        progress: 0.2,
        message: 'Начало скачивания...',
      );

      final downloadResult = await importService.downloadArchive(
        versionInfo: versionResult.data!,
        metadata: currentState.metadata,
        onProgress: (progress, message) {
          state = state?.copyWith(
            progress: 0.2 + (progress * 0.4), // 0.2 - 0.6
            message: message,
          );
        },
      );

      if (!downloadResult.success) {
        _setError('Ошибка скачивания: ${downloadResult.message}');
        return;
      }

      state = state!.copyWith(
        downloadPath: downloadResult.data,
        progress: 0.6,
        message: 'Скачивание завершено',
      );

      logInfo(
        'Архив успешно скачан',
        tag: _tag,
        data: {'path': downloadResult.data},
      );

      // Шаг 3: Закрытие текущей БД
      state = state!.copyWith(
        currentStep: ImportStep.replacing,
        progress: 0.65,
        message: 'Закрытие текущей базы данных...',
      );

      final dbNotifier = ref.read(hoplixiStoreProvider.notifier);
      await dbNotifier.closeDatabase(imported: true);
      await ref.read(clearAllProvider.notifier).clearAll();

      logInfo('Текущая БД закрыта', tag: _tag);

      // Шаг 4: Замена базы данных
      state = state!.copyWith(
        progress: 0.7,
        message: 'Распаковка новой базы данных...',
      );

      final replaceResult = await importService.replaceDatabase(
        downloadPath: downloadResult.data!,
        metadata: currentState.metadata,
        onProgress: (progress, message) {
          state = state?.copyWith(
            progress: 0.7 + (progress * 0.2), // 0.7 - 0.9
            message: message,
          );
        },
      );

      if (!replaceResult.success) {
        _setError('Ошибка замены БД: ${replaceResult.message}');
        return;
      }

      final importedDbPath = replaceResult.data!;

      // Сохраняем путь к импортированной БД в состоянии
      state = state!.copyWith(
        importedDbPath: importedDbPath,
        progress: 0.9,
        message: 'База данных заменена',
      );

      logInfo(
        'База данных заменена',
        tag: _tag,
        data: {'newPath': importedDbPath},
      );

      // Шаг 5: Открытие новой БД
      state = state!.copyWith(
        currentStep: ImportStep.opening,
        progress: 0.9,
        message: 'Открытие импортированной базы данных...',
      );

      logInfo('Открытие импортированной базы данных...', tag: _tag);
      // log old path
      logInfo('Старая база данных: $oldDbPath', tag: _tag);

      await _openImportedDatabase(
        importedDbPath,
        currentState.metadata,
        oldDbPath!,
      );

      // Завершено
      state = state!.copyWith(
        currentStep: ImportStep.completed,
        progress: 1.0,
        message: 'Импорт успешно завершён',
      );

      logInfo('Импорт успешно завершён', tag: _tag);
    } catch (e, st) {
      logError(
        'Критическая ошибка при импорте',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
      _setError('Критическая ошибка: ${e.toString()}');
    }
  }

  /// Открывает импортированную базу данных
  Future<void> _openImportedDatabase(
    String dbFolderPath,
    DatabaseMetaForSync metadata,
    String oldPath,
  ) async {
    try {
      // Получаем сервис истории БД
      final manager = await ref.read(hoplixiStoreManagerProvider.future);
      final historyService = await manager.getHistoryService();

      // Проверяем, есть ли сохранённый пароль
      final historyResult = await historyService.getEntryByPath(oldPath);
      logInfo(
        'Результат истории: ${historyResult.success.toString()}',
        tag: _tag,
      );

      String? masterPassword;
      if (historyResult.success && historyResult.entry != null) {
        masterPassword = historyResult.entry!.masterPassword;
        logInfo(
          'Проверка пароля в истории',
          tag: _tag,
          data: {'hasSavedPassword': masterPassword != null},
        );
      }

      // Если пароль не найден в истории, нужно будет запросить у пользователя
      // Это будет обработано на уровне UI
      if (masterPassword == null) {
        logInfo('Пароль не найден в истории, требуется ввод', tag: _tag);
        state = state?.copyWith(message: 'Требуется ввод мастер-пароля');
        return;
      }

      // Открываем БД с сохранённым паролем
      final dbNotifier = ref.read(hoplixiStoreProvider.notifier);
      await dbNotifier.openDatabase(
        OpenDatabaseDto(path: dbFolderPath, masterPassword: masterPassword),
      );

      // Ждём небольшую задержку, чтобы состояние провайдера гарантированно обновилось
      await Future.delayed(const Duration(milliseconds: 300));

      logInfo('Импортированная БД успешно открыта', tag: _tag);
    } catch (e, st) {
      logError(
        'Ошибка при открытии импортированной БД',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
      rethrow;
    }
  }

  /// Открывает БД с указанным паролем (вызывается из UI если пароль не сохранён)
  Future<void> openWithPassword(String password, String dbPath) async {
    if (state == null || state!.currentStep != ImportStep.opening) {
      logError('Неверное состояние для открытия БД', tag: _tag);
      return;
    }

    try {
      final dbNotifier = ref.read(hoplixiStoreProvider.notifier);

      logInfo('Открытие БД с паролем от пользователя', tag: _tag);

      await dbNotifier.openDatabase(
        OpenDatabaseDto(path: dbPath, masterPassword: password),
      );

      // Ждём небольшую задержку, чтобы состояние провайдера гарантированно обновилось
      await Future.delayed(const Duration(milliseconds: 300));

      state = state?.copyWith(
        currentStep: ImportStep.completed,
        progress: 1.0,
        message: 'База данных успешно открыта',
      );

      logInfo('БД успешно открыта с введённым паролем', tag: _tag);
    } catch (e, st) {
      logError(
        'Ошибка при открытии БД с паролем',
        error: e,
        stackTrace: st,
        tag: _tag,
      );
      _setError('Ошибка открытия БД: ${e.toString()}');
    }
  }

  /// Устанавливает ошибку в состояние
  void _setError(String error) {
    logError(error, tag: _tag);
    state = state?.copyWith(
      currentStep: ImportStep.error,
      error: error,
      message: error,
    );
  }

  /// Сбрасывает сессию
  void reset() {
    state = null;
    logDebug('Сессия импорта сброшена', tag: _tag);
  }
}

/// Провайдер сессии импорта
final importSessionProvider =
    NotifierProvider<ImportSessionNotifier, ImportSessionState?>(
      ImportSessionNotifier.new,
    );
