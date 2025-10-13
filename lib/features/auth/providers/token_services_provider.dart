import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/auth/services/token_services.dart';
import 'package:hoplixi/core/providers/box_db_provider.dart';

final tokenServicesProvider = FutureProvider<TokenServices>((ref) async {
  final boxManager = await ref.watch(boxDbProvider.future);

  return TokenServices(boxManager);
});
