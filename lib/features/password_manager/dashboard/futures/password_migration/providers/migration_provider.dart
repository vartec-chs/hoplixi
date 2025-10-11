import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';
import 'dart:io';
import '../services/json_generator_for_migration.dart';
import '../services/json_parser_for_migration.dart';

// =============================================================================
// ПРОВАЙДЕРЫ СЕРВИСОВ
// =============================================================================

/// Провайдер для генератора JSON
final jsonGeneratorProvider = Provider<JsonGeneratorForMigration>((ref) {
  return JsonGeneratorForMigration();
});

/// Провайдер для парсера JSON
final jsonParserProvider = Provider<JsonParserForMigration>((ref) {
  return JsonParserForMigration();
});

// =============================================================================
// СОСТОЯНИЯ
// =============================================================================

/// Состояние экспорта
enum ExportState { idle, generating, success, error }

/// Состояние импорта
enum ImportState { idle, parsing, preview, importing, success, error }

/// Модель состояния экспорта
class ExportStateModel {
  final ExportState state;
  final String? filePath;
  final String? errorMessage;
  final int passwordCount;
  final int categoryCount;

  const ExportStateModel({
    required this.state,
    this.filePath,
    this.errorMessage,
    this.passwordCount = 0,
    this.categoryCount = 0,
  });

  ExportStateModel copyWith({
    ExportState? state,
    String? filePath,
    String? errorMessage,
    int? passwordCount,
    int? categoryCount,
  }) {
    return ExportStateModel(
      state: state ?? this.state,
      filePath: filePath ?? this.filePath,
      errorMessage: errorMessage ?? this.errorMessage,
      passwordCount: passwordCount ?? this.passwordCount,
      categoryCount: categoryCount ?? this.categoryCount,
    );
  }
}

/// Модель состояния импорта
class ImportStateModel {
  final String? filePath;
  final ImportState state;
  final String? errorMessage;
  final List<CreatePasswordDto>? passwords;
  final List<CreateCategoryForMigrationDto>? categories;

  const ImportStateModel({
    this.filePath,
    required this.state,
    this.errorMessage,
    this.passwords,
    this.categories,
  });

  ImportStateModel copyWith({
    String? filePath,
    ImportState? state,
    String? errorMessage,
    List<CreatePasswordDto>? passwords,
    List<CreateCategoryForMigrationDto>? categories,
  }) {
    return ImportStateModel(
      filePath: filePath,
      state: state ?? this.state,
      errorMessage: errorMessage ?? this.errorMessage,
      passwords: passwords ?? this.passwords,
      categories: categories ?? this.categories,
    );
  }
}

// =============================================================================
// NOTIFIER ДЛЯ ЭКСПОРТА
// =============================================================================

final exportNotifierProvider =
    NotifierProvider<ExportNotifier, ExportStateModel>(ExportNotifier.new);

class ExportNotifier extends Notifier<ExportStateModel> {
  @override
  ExportStateModel build() {
    return const ExportStateModel(state: ExportState.idle);
  }

  /// Генерация и сохранение файла
  Future<void> generateAndSave({
    required int passwordCount,
    required int categoryCount,
    required String filePath,
  }) async {
    state = state.copyWith(
      state: ExportState.generating,
      passwordCount: passwordCount,
      categoryCount: categoryCount,
    );

    try {
      final generator = ref.read(jsonGeneratorProvider);
      generator.generateAndSave(
        passwordCount: passwordCount,
        categoryCount: categoryCount,
        filePath: filePath,
      );

      state = state.copyWith(state: ExportState.success, filePath: filePath);
    } catch (e) {
      state = state.copyWith(
        state: ExportState.error,
        errorMessage: 'Ошибка при генерации файла: $e',
      );
    }
  }

  /// Сброс состояния
  void reset() {
    state = const ExportStateModel(state: ExportState.idle);
  }
}

// =============================================================================
// NOTIFIER ДЛЯ ИМПОРТА
// =============================================================================

final importNotifierProvider =
    NotifierProvider<ImportNotifier, ImportStateModel>(ImportNotifier.new);

class ImportNotifier extends Notifier<ImportStateModel> {
  @override
  ImportStateModel build() {
    return const ImportStateModel(state: ImportState.idle);
  }

  /// Парсинг файла и показ превью
  Future<void> parseFile(String filePath) async {
    state = state.copyWith(state: ImportState.parsing);

    try {
      final parser = ref.read(jsonParserProvider);
      final result = parser.parseFromFile(filePath);

      if (!result.success) {
        state = state.copyWith(
          state: ImportState.error,
          errorMessage: result.message ?? 'Ошибка парсинга файла',
        );
        return;
      }

      final passwords = result.data!['passwords'] as List<CreatePasswordDto>;
      final categories =
          result.data!['categories'] as List<CreateCategoryForMigrationDto>;

      state = state.copyWith(
        state: ImportState.preview,
        passwords: passwords,
        categories: categories,
        filePath: filePath,
      );
    } catch (e) {
      state = state.copyWith(
        state: ImportState.error,
        errorMessage: 'Ошибка при парсинге файла: $e',
      );
    }
  }

  /// Импорт данных в БД
  Future<void> importToDatabase() async {
    if (state.passwords == null || state.categories == null) {
      state = state.copyWith(
        state: ImportState.error,
        errorMessage: 'Нет данных для импорта',
      );
      return;
    }

    state = state.copyWith(state: ImportState.importing);

    try {
      final categoriesService = ref.read(categoriesServiceProvider);
      final passwordsService = ref.read(passwordsServiceProvider);

      // Сначала импортируем категории
      for (final category in state.categories!) {
        final result = await categoriesService.createCategoryForMigration(
          migrationId: category.migrationId,
          name: category.name,
          description: category.description,
          iconId: category.iconId,
          color: category.color,
          type: category.type,
        );

        if (!result.success) {
          state = state.copyWith(
            state: ImportState.error,
            errorMessage: 'Ошибка при создании категории: ${result.message}',
          );
          return;
        }
      }

      // Затем импортируем пароли
      for (final password in state.passwords!) {
        final result = await passwordsService.createPassword(password);

        if (!result.success) {
          state = state.copyWith(
            state: ImportState.error,
            errorMessage: 'Ошибка при создании пароля: ${result.message}',
          );
          return;
        }
      }

   

      // удалять файл после успешного импорта
      try {
        await File(state.filePath!).delete();
      } catch (e) {
        state = state.copyWith(
          state: ImportState.success,
          errorMessage:
              'При автоматическом удалении файла произошла ошибка, удалите файл вручную: $e',
        );
        return;
      }

     

      state = state.copyWith(state: ImportState.success);
    } catch (e) {
      state = state.copyWith(
        state: ImportState.error,
        errorMessage: 'Ошибка при импорте в БД: $e',
      );
    }
  }

  /// Сброс состояния
  void reset() {
    state = const ImportStateModel(state: ImportState.idle);
  }
}
