import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/cloud_sync/models/token_oauth.dart';
import 'package:hoplixi/features/cloud_sync/providers/token_services_provider.dart';
import 'package:hoplixi/features/cloud_sync/services/token_services.dart';

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
    return await _loadTokens();
  }

  Future<List<TokenInfo>> _loadTokens() async {
    try {
      // Получаем базу данных напрямую для доступа к TokenOAuth
      final db = _service.db;
      if (db == null) {
        logWarning('Token database not initialized', tag: _tag);
        return [];
      }

      final allTokens = await db.getAll();

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
