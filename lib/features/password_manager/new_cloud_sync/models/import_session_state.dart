import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/models/cloud_version_info.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

part 'import_session_state.freezed.dart';

/// Этап процесса импорта
enum ImportStep {
  /// Проверка наличия новой версии
  checking,

  /// Скачивание архива
  downloading,

  /// Замена базы данных
  replacing,

  /// Открытие базы данных
  opening,

  /// Импорт завершён
  completed,

  /// Ошибка
  error,
}

/// Состояние сессии импорта
@freezed
abstract class ImportSessionState with _$ImportSessionState {
  const factory ImportSessionState({
    /// Метаданные базы данных
    required DatabaseMetaForSync metadata,

    /// Информация о версии в облаке
    CloudVersionInfo? versionInfo,

    /// Путь к скачанному файлу
    String? downloadPath,

    /// Путь к импортированной (распакованной) БД
    String? importedDbPath,

    /// Прогресс выполнения (0.0 - 1.0)
    @Default(0.0) double progress,

    /// Текущий этап
    @Default(ImportStep.checking) ImportStep currentStep,

    /// Сообщение о текущем действии
    @Default('') String message,

    /// Сообщение об ошибке
    String? error,

    /// Ключ клиента для OAuth2
    required String clientKey,

    /// Ключ шифрования архива (опционально)
    String? encryptionKeyArchive,
  }) = _ImportSessionState;
}
