import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/auth/providers/oauth2_navigation_provider.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';
import 'package:hoplixi/features/auth/services/service_result.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Notifier для управления авторизацией OAuth2
class OAuth2AccountNotifier extends AsyncNotifier<ServiceResult<String>?> {
  static const String _tag = 'OAuth2AccountNotifier';

  late OAuth2AccountService _service;

  @override
  Future<ServiceResult<String>?> build() async {
    logInfo('Инициализация OAuth2AccountNotifier', tag: _tag);
    _service = await ref.watch(oauth2AccountProvider.future);
    return null; // Начальное состояние - нет результата авторизации
  }

  /// Метод авторизации с интеграцией навигации
  Future<void> authorize(AuthClientConfig credential) async {
    try {
      // Сохраняем текущий путь перед авторизацией
      await ref.read(oauth2NavigationProvider.notifier).saveCurrentPath();

      state = const AsyncLoading();

      final result = await _service.authorize(credential);

      if (result.success) {
        // Успешная авторизация - восстанавливаем путь
        await ref
            .read(oauth2NavigationProvider.notifier)
            .restorePathOnSuccess();
      } else {
        // Ошибка авторизации - восстанавливаем путь
        await ref.read(oauth2NavigationProvider.notifier).restorePathOnError();
      }

      state = AsyncData(result as ServiceResult<String>?);
    } catch (e, stack) {
      logError(
        'Ошибка при авторизации',
        error: e,
        stackTrace: stack,
        tag: _tag,
      );
      // В случае ошибки восстанавливаем путь
      await ref.read(oauth2NavigationProvider.notifier).restorePathOnError();
      state = AsyncError(e, stack);
    }
  }

  /// Сброс состояния
  void reset() {
    state = const AsyncData(null);
  }
}

/// Провайдер для управления авторизацией OAuth2
final oauth2AccountNotifierProvider =
    AsyncNotifierProvider<OAuth2AccountNotifier, ServiceResult<String>?>(
      OAuth2AccountNotifier.new,
    );
