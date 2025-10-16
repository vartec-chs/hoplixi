import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/auth/models/token_oauth.dart';
import 'package:hoplixi/features/auth/providers/token_services_provider.dart';
import 'package:hoplixi/features/auth/services/token_services.dart';

/// Информация о токене для отображения
class TokenInfo {
  final String key;
  final TokenOAuth token;

  const TokenInfo({required this.key, required this.token});
}

/// Провайдер списка всех токенов
class TokenListNotifier extends AsyncNotifier<List<TokenInfo>> {
  static const String _tag = 'TokenListNotifier';
  late TokenServices _service;

  @override
  Future<List<TokenInfo>> build() async {
    _service = await ref.read(tokenServicesProvider.future);
    state = const AsyncValue.loading();
    try {
      final tokens = await _loadTokens();
      state = AsyncValue.data(tokens);
      logInfo('Loaded ${tokens.length} tokens', tag: _tag);
      return tokens;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      logError('Failed to load tokens', error: e, stackTrace: stack, tag: _tag);
    }

    return [];
  }

  Future<List<TokenInfo>> _loadTokens() async {
    try {
      final allTokens = await _service.getAllTokens();

      return allTokens
          .map((token) => TokenInfo(key: token.id, token: token))
          .toList();
    } catch (e, stack) {
      logError('Failed to load tokens', error: e, stackTrace: stack, tag: _tag);
      throw Exception('Не удалось загрузить токены: $e');
    }
  }

  /// Обновить список токенов
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _loadTokens());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Удалить токен
  Future<bool> deleteToken(String key) async {
    state = const AsyncValue.loading();
    try {
      await _service.delete(key);
      state = AsyncValue.data(await _loadTokens());
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Очистить все токены
  Future<bool> clearAll() async {
    state = const AsyncValue.loading();
    try {
      await _service.clear();
      state = const AsyncValue.data([]);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  /// Получить количество токенов
  Future<int> getCount() async {
    return await _service.count();
  }
}

/// Провайдер списка токенов
final tokenListProvider =
    AsyncNotifierProvider.autoDispose<TokenListNotifier, List<TokenInfo>>(
      TokenListNotifier.new,
    );

/// Провайдер количества токенов
final tokenCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = await ref.watch(tokenServicesProvider.future);
  return await service.count();
});
