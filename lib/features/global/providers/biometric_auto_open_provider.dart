import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/app_preferences/keys.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/global/providers/secure_storage_provider.dart';

class BiometricAutoOpenNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final secureStorage = ref.read(secureStorageProvider);
    final value = await secureStorage.read(Keys.biometricForAutoOpen.key);
    return value == 'true';
  }

  Future<void> setBiometricAutoOpen(bool value) async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.write(Keys.biometricForAutoOpen.key, value.toString());
    state = AsyncValue.data(value);
  }
}

final biometricAutoOpenProvider =
    AsyncNotifierProvider<BiometricAutoOpenNotifier, bool>(
      BiometricAutoOpenNotifier.new,
    );
