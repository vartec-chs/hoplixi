import 'package:riverpod/riverpod.dart';
import '../services/local_meta_crud_service.dart';

final localMetaCrudProvider = FutureProvider<LocalMetaCrudService>((ref) async {
  final serviceResult = await LocalMetaCrudService.getInstance();
  return serviceResult.getOrThrow();
});
