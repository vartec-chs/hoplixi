import 'package:hoplixi/core/lib/sodium_file_encryptor/aead_file_encryptor.dart';
import 'package:sodium/sodium.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';
import 'package:riverpod/riverpod.dart';

final sodiumProvider = FutureProvider<Sodium>((ref) {
  return SodiumSumoInit.init();
});

final keyGeneratorProvider = Provider<SecureKey>((ref) {
  final sodium = ref
      .watch(sodiumProvider)
      .maybeWhen(
        data: (sodium) => sodium,
        orElse: () => throw Exception('Sodium is not initialized yet'),
      );
  return AeadFileEncryptor.generateKey(sodium);
});
