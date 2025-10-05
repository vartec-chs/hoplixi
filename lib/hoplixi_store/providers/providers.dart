/// Библиотека провайдеров для Hoplixi Store
///
/// Экспортирует все необходимые провайдеры для работы с базой данных и сервисами
library;

export 'hoplixi_store_providers.dart';
export 'service_providers.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:hoplixi/features/global/providers/file_encryptor_provider.dart';
import 'service_providers.dart';
import 'dao_providers.dart';

final clearAllProvider = AsyncNotifierProvider<ClearAllNotifier, void>(
  ClearAllNotifier.new,
);

class ClearAllNotifier extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    try {
      final providers = <ProviderBase>{
        passwordFilterDaoProvider,
        categoriesDaoProvider,
        iconsDaoProvider,
        tagsDaoProvider,
        passwordsDaoProvider,
        passwordTagsDaoProvider,
        categoriesServiceProvider,
        iconsServiceProvider,
        tagsServiceProvider,
        passwordsServiceProvider,
        // fileEncryptorProvider,
      };

      // Если нужно асинхронно что-то делать — await внутри цикла.
      for (final p in providers) {
        ref.invalidate(p);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
