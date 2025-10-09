import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/global/providers/secure_storage_provider.dart';

final boxDbProvider = FutureProvider<BoxManager>((ref) async {
  final secureStorage = ref.watch(secureStorageProvider);
  final boxManager = BoxManager(
    basePath: await getBoxDbPath(),
    secureStorage: secureStorage,
  );

  ref.onDispose(() async {
    await boxManager.closeAll();
  });

  return boxManager;
});
