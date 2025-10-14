import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/import_dropbox_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

/// Состояние импорта
class ImportState {
  final bool isImporting;
  final double progress;
  final String message;
  final String? error;

  const ImportState({
    this.isImporting = false,
    this.progress = 0.0,
    this.message = '',
    this.error,
  });

  ImportState copyWith({
    bool? isImporting,
    double? progress,
    String? message,
    String? error,
  }) {
    return ImportState(
      isImporting: isImporting ?? this.isImporting,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }
}

/// Контроллер для управления импортом хранилища
class ImportController extends Notifier<ImportState> {
  @override
  ImportState build() {
    return const ImportState();
  }

  /// Импортирует хранилище из Dropbox
  Future<void> importFromDropbox({
    required DatabaseMetaForSync metadata,
    required String clientKey,
    String? encryptionKeyArchive,
    void Function(double progress, String message)? onProgress,
    void Function(double progress, String message)? onFileProgress,
    void Function(String error)? onError,
  }) async {
    const String tag = 'ImportController';

    try {
      // Обновляем состояние
      state = state.copyWith(
        isImporting: true,
        progress: 0.0,
        message: 'Подготовка к импорту...',
        error: null,
      );

      onProgress?.call(0.0, 'Подготовка к импорту...');

      logInfo(
        'Начало импорта хранилища',
        tag: tag,
        data: {
          'clientKey': _maskKey(clientKey),
          'dbId': metadata.id,
          'dbName': metadata.name,
        },
      );

      // Получаем менеджер базы данных
      final manager = await ref.read(hoplixiStoreManagerProvider.future);

      // Проверяем, что БД открыта
      if (!manager.hasOpenDatabase) {
        throw Exception('База данных не открыта');
      }

      // Путь к директории БД (не к файлу)
      final dbPath = ref.read(hoplixiStoreProvider.notifier).databaseDir;

      if (dbPath == null) {
        throw Exception('Путь к директории базы данных не определён');
      }

      logInfo('Путь к БД определён', tag: tag, data: {'dbPath': dbPath});

      // Получаем сервис импорта
      state = state.copyWith(
        progress: 0.05,
        message: 'Инициализация сервиса импорта...',
      );
      onProgress?.call(0.05, 'Инициализация сервиса импорта...');

      final importService = await ref.read(importDropboxProvider.future);

      logInfo('Начало импорта из Dropbox', tag: tag);

      // Запускаем импорт с передачей callback'ов
      final result = await importService.importFromDropbox(
        metadata: metadata,
        pathToDbFolder: dbPath,
        clientKey: clientKey,
        encryptionKeyArchive: encryptionKeyArchive,
        onProgress: (progress, message) {
          // Обновляем состояние при получении прогресса от сервиса
          state = state.copyWith(progress: progress, message: message);
          // Передаём прогресс во внешний callback
          onProgress?.call(progress, message);
        },
        onFileProgress: (progress, message) {
          // Обновляем состояние при получении прогресса скачивания файла
          state = state.copyWith(progress: progress, message: message);
          // Передаём прогресс во внешний callback
          onFileProgress?.call(progress, message);
        },
        onError: (error) {
          // Обрабатываем ошибки из сервиса
          logError(
            'Ошибка из сервиса импорта',
            tag: tag,
            data: {'error': error},
          );
          state = state.copyWith(error: error, message: error);
          // Передаём ошибку во внешний callback
          onError?.call(error);
        },
      );

      if (!result.success) {
        throw Exception(result.message ?? 'Ошибка импорта');
      }

      // Импорт завершён
      state = state.copyWith(
        progress: 1.0,
        message: 'Импорт успешно завершён',
        isImporting: false,
      );
      onProgress?.call(1.0, 'Импорт успешно завершён');

      logInfo(
        'Импорт успешно завершён',
        tag: tag,
        data: {'dbId': metadata.id, 'dbName': metadata.name},
      );
    } catch (e, st) {
      logError(
        'Ошибка при импорте хранилища',
        error: e,
        stackTrace: st,
        tag: tag,
      );

      state = state.copyWith(
        isImporting: false,
        error: e.toString(),
        message: 'Ошибка: ${e.toString()}',
      );

      rethrow;
    }
  }

  /// Сбрасывает состояние
  void reset() {
    state = const ImportState();
  }

  /// Маскирует ключ для логирования
  String _maskKey(String key) {
    if (key.length <= 8) {
      return '${key.substring(0, 2)}***';
    }
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }
}

/// Провайдер контроллера импорта
final importControllerProvider =
    NotifierProvider<ImportController, ImportState>(ImportController.new);
