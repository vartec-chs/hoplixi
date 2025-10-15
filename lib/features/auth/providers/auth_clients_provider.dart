import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/services/auth_clients_service.dart';
import 'package:hoplixi/core/providers/box_db_provider.dart';

/// Провайдер сервиса credential
final authClientsServiceProvider = FutureProvider<AuthClientsService>((
  ref,
) async {
  final boxManager = await ref.watch(boxDbProvider.future);

  final service = AuthClientsService(boxManager);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Состояние списка credentials
class AuthClientsListState {
  final List<AuthClientConfig> credentials;
  final bool isLoading;
  final String? error;

  AuthClientsListState({
    this.credentials = const [],
    this.isLoading = false,
    this.error,
  });

  AuthClientsListState copyWith({
    List<AuthClientConfig>? credentials,
    bool? isLoading,
    String? error,
  }) {
    return AuthClientsListState(
      credentials: credentials ?? this.credentials,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier для управления списком credentials
class AuthClientsListNotifier extends AsyncNotifier<List<AuthClientConfig>> {
  late AuthClientsService _service;

  @override
  Future<List<AuthClientConfig>> build() async {
    _service = await ref.read(authClientsServiceProvider.future);
    return await _loadCredentials();
  }

  Future<List<AuthClientConfig>> _loadCredentials() async {
    final result = await _service.getAllCredentials();
    if (result.success) {
      return result.data ?? [];
    } else {
      throw Exception(result.message ?? 'Failed to load credentials');
    }
  }

  /// Обновить список
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _loadCredentials());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Создать новый credential
  Future<bool> createAuthClient({
    required AuthClientType type,
    required String clientId,
    required String clientSecret,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.createCredential(
        type: type,
        clientId: clientId,
        name: name,
        clientSecret: clientSecret,
      );

      if (result.success) {
        state = AsyncValue.data(await _loadCredentials());
        return true;
      } else {
        state = AsyncValue.error(
          result.message ?? 'Failed to create credential',
          StackTrace.current,
        );
        return false;
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Обновить credential
  Future<bool> updateAuthClient(AuthClientConfig credential) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.updateCredential(credential);

      if (result.success) {
        state = AsyncValue.data(await _loadCredentials());
        return true;
      } else {
        state = AsyncValue.error(
          result.message ?? 'Failed to update credential',
          StackTrace.current,
        );
        return false;
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Удалить credential
  Future<bool> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.deleteCredential(id);

      if (result.success) {
        state = AsyncValue.data(await _loadCredentials());
        return true;
      } else {
        state = AsyncValue.error(
          result.message ?? 'Failed to delete credential',
          StackTrace.current,
        );
        return false;
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Очистить все
  Future<bool> clearAll() async {
    state = const AsyncValue.loading();
    try {
      final result = await _service.clearAll();

      if (result.success) {
        state = AsyncValue.data(await _loadCredentials());
        return true;
      } else {
        state = AsyncValue.error(
          result.message ?? 'Failed to clear credentials',
          StackTrace.current,
        );
        return false;
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
}

/// Провайдер списка credentials
final authClientsListProvider =
    AsyncNotifierProvider<AuthClientsListNotifier, List<AuthClientConfig>>(
      AuthClientsListNotifier.new,
    );

/// Провайдер для фильтрации по активным типам
final activeAuthClientsProvider = Provider<AsyncValue<List<AuthClientConfig>>>((
  ref,
) {
  final asyncValue = ref.watch(authClientsListProvider);
  return asyncValue.when(
    data: (credentials) => AsyncValue.data(
      credentials.where((credential) => credential.type.isActive).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Провайдер для группировки по типам
final authClientsByTypeProvider =
    Provider<AsyncValue<Map<AuthClientType, List<AuthClientConfig>>>>((ref) {
      final asyncValue = ref.watch(authClientsListProvider);
      return asyncValue.when(
        data: (credentials) {
          final grouped = <AuthClientType, List<AuthClientConfig>>{};
          for (final credential in credentials) {
            grouped.putIfAbsent(credential.type, () => []).add(credential);
          }
          return AsyncValue.data(grouped);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });
