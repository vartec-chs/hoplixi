import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/features/global/providers/box_db_provider.dart';
import 'package:riverpod/riverpod.dart';

final oauth2AccountProvider = FutureProvider<OAuth2Account>((ref) async {
  final box_db = await ref.watch(boxDbProvider.future);
  return OAuth2Account(appPrefix: 'hoplixi', tokenStorage: null);
});
