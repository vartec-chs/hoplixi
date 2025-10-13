
import 'package:hoplixi/features/auth/providers/token_services_provider.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';
import 'package:riverpod/riverpod.dart';

final oauth2AccountProvider = FutureProvider<OAuth2AccountService>((ref) async {
  final tokenStorage = await ref.watch(tokenServicesProvider.future);
  return OAuth2AccountService(tokenStorage);
});
