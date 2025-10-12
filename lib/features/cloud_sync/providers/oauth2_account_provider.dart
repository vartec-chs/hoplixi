import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/features/cloud_sync/providers/token_services_provider.dart';
import 'package:riverpod/riverpod.dart';

final oauth2AccountProvider = FutureProvider<OAuth2Account>((ref) async {
  final tokenStorage = await ref.watch(tokenServicesProvider.future);
  return OAuth2Account(
    appPrefix: MainConstants.appName,
    tokenStorage: tokenStorage,
  );
});
