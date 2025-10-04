
import 'package:sodium/sodium.dart';
import 'package:sodium_libs/sodium_libs_sumo.dart';
import 'package:riverpod/riverpod.dart';

final sodiumProvider = FutureProvider<Sodium>((ref) {
  return SodiumSumoInit.init();
});
