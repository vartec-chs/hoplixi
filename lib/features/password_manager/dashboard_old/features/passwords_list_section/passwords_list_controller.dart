// DEPRECATED: Этот файл заменен на passwords_stream_provider.dart
// который использует современный реактивный подход с StreamProvider

// Экспортируем все из нового файла для обратной совместимости
export 'passwords_stream_provider.dart';

// Ниже сохранены устаревшие определения для совместимости с существующим кодом
// Рекомендуется переходить на новые провайдеры из passwords_stream_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'passwords_stream_provider.dart';

/// DEPRECATED: Используйте filteredPasswordsStreamProvider вместо этого
/// Provider для контроллера списка паролей (обратная совместимость)
final passwordsListControllerProvider =
    Provider.autoDispose<_DeprecatedPasswordsListController>((ref) {
      return _DeprecatedPasswordsListController(ref);
    });

/// DEPRECATED: Используйте passwordsListProvider из passwords_stream_provider.dart
/// Provider для получения только списка паролей (обратная совместимость)
final passwordsListProvider = Provider.autoDispose<List<CardPasswordDto>>((
  ref,
) {
  // Переадресуем на новый провайдер
  return ref.watch(
    filteredPasswordsStreamProvider.select(
      (asyncValue) => asyncValue.when(
        data: (passwords) => passwords,
        loading: () => <CardPasswordDto>[],
        error: (_, __) => <CardPasswordDto>[],
      ),
    ),
  );
});

/// DEPRECATED: Используйте isPasswordsLoadingProvider из passwords_stream_provider.dart
/// Provider для проверки состояния загрузки (обратная совместимость)
final isPasswordsLoadingProvider = Provider.autoDispose<bool>((ref) {
  // Переадресуем на новый провайдер
  final asyncPasswords = ref.watch(filteredPasswordsStreamProvider);
  return asyncPasswords.isLoading;
});

/// DEPRECATED: Используйте passwordsErrorProvider из passwords_stream_provider.dart
/// Provider для получения ошибки (обратная совместимость)
final passwordsErrorProvider = Provider.autoDispose<String?>((ref) {
  // Переадресуем на новый провайдер
  final asyncPasswords = ref.watch(filteredPasswordsStreamProvider);
  return asyncPasswords.error?.toString();
});

/// DEPRECATED: Не используется в новом подходе со StreamProvider
/// Provider для проверки наличия дополнительных данных (обратная совместимость)
final hasMorePasswordsProvider = Provider.autoDispose<bool>((ref) {
  // В новом подходе со StreamProvider все данные загружаются сразу
  return false;
});

/// DEPRECATED: Используйте passwordsTotalCountProvider из passwords_stream_provider.dart
/// Provider для общего количества паролей (обратная совместимость)
final passwordsTotalCountProvider = Provider.autoDispose<int>((ref) {
  // Переадресуем на новый провайдер
  final passwords = ref.watch(passwordsListProvider);
  return passwords.length;
});

/// DEPRECATED: Используйте passwordsActionsProvider из passwords_stream_provider.dart
/// Provider для уведомления об изменениях паролей (обратная совместимости)
final passwordChangeNotifierProvider = Provider.autoDispose<void Function()>((
  ref,
) {
  // Возвращаем пустую функцию для обратной совместимости
  return () {
    // В новом подходе уведомления не требуются
  };
});

/// DEPRECATED: Устаревший контроллер для обратной совместимости
/// Используйте PasswordsActions из passwords_stream_provider.dart
class _DeprecatedPasswordsListController {
  final Ref _ref;
  late final PasswordsActions _actions;

  _DeprecatedPasswordsListController(this._ref) {
    _actions = _ref.read(passwordsActionsProvider);
  }

  /// DEPRECATED: Используйте passwordsActionsProvider.refreshPasswords()
  Future<void> refreshPasswords() async {
    await _actions.refreshPasswords();
  }

  /// DEPRECATED: Используйте passwordsActionsProvider.toggleFavorite()
  Future<void> toggleFavorite(String passwordId) async {
    await _actions.toggleFavorite(passwordId);
  }

  /// DEPRECATED: Используйте passwordsActionsProvider.deletePassword()
  Future<void> deletePassword(String passwordId) async {
    await _actions.deletePassword(passwordId);
  }

  /// DEPRECATED: Используйте passwordsActionsProvider.searchPasswords()
  Future<void> searchPasswords(String query) async {
    _actions.searchPasswords(query);
  }

  /// DEPRECATED: Используйте passwordsActionsProvider.getPasswordById()
  Future<String> getPasswordById(String id) async {
    return await _actions.getPasswordById(id);
  }

  /// DEPRECATED: Используйте passwordsActionsProvider.getUrlById()
  Future<String> getUrlById(String id) async {
    return await _actions.getUrlById(id);
  }

  /// DEPRECATED: Используйте passwordsActionsProvider.getLoginById()
  Future<String> getLoginById(String id) async {
    return await _actions.getLoginById(id);
  }

  /// DEPRECATED: Автоматически обновляется через StreamProvider
  void notifyPasswordChanged() {
    // Не требуется в новом подходе
  }

  /// DEPRECATED: Не требуется в новом подходе
  void clearError() {
    // Ошибки автоматически обрабатываются через AsyncValue
  }

  /// DEPRECATED: Не требуется в новом подходе
  void setHoplixiStore(store) {
    // Конфигурация происходит через провайдеры
  }
}
