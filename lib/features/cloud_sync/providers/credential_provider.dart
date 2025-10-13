import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';
import 'package:hoplixi/features/cloud_sync/services/credential_service.dart';
import 'package:hoplixi/core/providers/box_db_provider.dart';

/// Провайдер сервиса credential
final credentialServiceProvider = FutureProvider<CredentialService>((
  ref,
) async {
  final boxManager = await ref.watch(boxDbProvider.future);

  final service = CredentialService(boxManager);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Состояние списка credentials
class CredentialListState {
  final List<CredentialApp> credentials;
  final bool isLoading;
  final String? error;

  CredentialListState({
    this.credentials = const [],
    this.isLoading = false,
    this.error,
  });

  CredentialListState copyWith({
    List<CredentialApp>? credentials,
    bool? isLoading,
    String? error,
  }) {
    return CredentialListState(
      credentials: credentials ?? this.credentials,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier для управления списком credentials
class CredentialListNotifier extends AsyncNotifier<List<CredentialApp>> {
  late CredentialService _service;

  @override
  Future<List<CredentialApp>> build() async {
    _service = await ref.read(credentialServiceProvider.future);
    return await _loadCredentials();
  }

  Future<List<CredentialApp>> _loadCredentials() async {
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
  Future<bool> createCredential({
    required CredentialOAuthType type,
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
  Future<bool> updateCredential(CredentialApp credential) async {
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
  Future<bool> deleteCredential(String id) async {
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
final credentialListProvider =
    AsyncNotifierProvider<CredentialListNotifier, List<CredentialApp>>(
      CredentialListNotifier.new,
    );

/// Провайдер для фильтрации по активным типам
final activeCredentialsProvider = Provider<AsyncValue<List<CredentialApp>>>((
  ref,
) {
  final asyncValue = ref.watch(credentialListProvider);
  return asyncValue.when(
    data: (credentials) => AsyncValue.data(
      credentials.where((credential) => credential.type.isActive).toList(),
    ),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Провайдер для группировки по типам
final credentialsByTypeProvider =
    Provider<AsyncValue<Map<CredentialOAuthType, List<CredentialApp>>>>((ref) {
      final asyncValue = ref.watch(credentialListProvider);
      return asyncValue.when(
        data: (credentials) {
          final grouped = <CredentialOAuthType, List<CredentialApp>>{};
          for (final credential in credentials) {
            grouped.putIfAbsent(credential.type, () => []).add(credential);
          }
          return AsyncValue.data(grouped);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });
