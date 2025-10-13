import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/providers/export_dropbox_provider.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

/// Состояние экспорта
class ExportState {
  final bool isExporting;
  final double progress;
  final String message;
  final String? error;

  const ExportState({
    this.isExporting = false,
    this.progress = 0.0,
    this.message = '',
    this.error,
  });

  ExportState copyWith({
    bool? isExporting,
    double? progress,
    String? message,
    String? error,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error ?? this.error,
    );
  }
}

/// Контроллер для управления экспортом хранилища
class ExportController extends Notifier<ExportState> {
  @override
  ExportState build() {
    return const ExportState();
  }

  /// Экспортирует хранилище в Dropbox
  Future<void> exportToDropbox({
    required String clientKey,
    String? encryptionKeyArchive,
    void Function(double progress, String message)? onProgress,
    void Function(String error)? onError,
  }) async {
    const String tag = 'ExportController';

    try {
      // Обновляем состояние
      state = state.copyWith(
        isExporting: true,
        progress: 0.0,
        message: 'Подготовка к экспорту...',
        error: null,
      );

      onProgress?.call(0.0, 'Подготовка к экспорту...');

      logInfo(
        'Начало экспорта хранилища',
        tag: tag,
        data: {'clientKey': _maskKey(clientKey)},
      );

      // Получаем менеджер базы данных
      final manager = await ref.read(hoplixiStoreManagerProvider.future);

      // Проверяем, что БД открыта
      if (!manager.hasOpenDatabase) {
        throw Exception('База данных не открыта');
      }

      // Получаем метаданные и путь к БД
      state = state.copyWith(progress: 0.1, message: 'Получение метаданных...');
      onProgress?.call(0.1, 'Получение метаданных...');

      final metadata = await manager.getDatabaseMetaForSync();

      // Путь к директории БД (не к файлу)
      final dbPath = ref.read(hoplixiStoreProvider.notifier).databaseDir;

      if (dbPath == null) {
        throw Exception('Путь к директории базы данных не определён');
      }

      logInfo(
        'Метаданные получены',
        tag: tag,
        data: {'dbId': metadata.id, 'dbName': metadata.name, 'dbPath': dbPath},
      );

      // Получаем сервис экспорта
      state = state.copyWith(
        progress: 0.2,
        message: 'Инициализация сервиса экспорта...',
      );
      onProgress?.call(0.2, 'Инициализация сервиса экспорта...');

      final exportService = await ref.read(exportDropboxProvider.future);

      // Создаём архив
      state = state.copyWith(
        progress: 0.3,
        message: 'Создание архива хранилища...',
      );
      onProgress?.call(0.3, 'Создание архива хранилища...');

      logInfo('Начало создания архива', tag: tag);

      // Запускаем экспорт с передачей callback'ов
      final result = await exportService.exportToDropbox(
        metadata,
        clientKey,
        dbPath,
        encryptionKeyArchive,
        onProgress: (progress, message) {
          // Обновляем состояние при получении прогресса от сервиса
          state = state.copyWith(progress: progress, message: message);
          // Передаём прогресс во внешний callback
          onProgress?.call(progress, message);
        },
        onError: (error) {
          // Обрабатываем ошибки из сервиса
          logError(
            'Ошибка из сервиса экспорта',
            tag: tag,
            data: {'error': error},
          );
          state = state.copyWith(error: error, message: error);
          // Передаём ошибку во внешний callback
          onError?.call(error);
        },
      );

      if (!result.success) {
        throw Exception(result.message ?? 'Ошибка экспорта');
      }

      // Экспорт завершён
      state = state.copyWith(
        progress: 1.0,
        message: 'Экспорт успешно завершён',
        isExporting: false,
      );
      onProgress?.call(1.0, 'Экспорт успешно завершён');

      logInfo(
        'Экспорт успешно завершён',
        tag: tag,
        data: {'fileName': result.data},
      );
    } catch (e, st) {
      logError(
        'Ошибка при экспорте хранилища',
        error: e,
        stackTrace: st,
        tag: tag,
      );

      state = state.copyWith(
        isExporting: false,
        error: e.toString(),
        message: 'Ошибка: ${e.toString()}',
      );

      rethrow;
    }
  }

  /// Сбрасывает состояние
  void reset() {
    state = const ExportState();
  }

  /// Маскирует ключ для логирования
  String _maskKey(String key) {
    if (key.length <= 8) {
      return '${key.substring(0, 2)}***';
    }
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }
}

/// Провайдер контроллера экспорта
final exportControllerProvider =
    NotifierProvider<ExportController, ExportState>(ExportController.new);
