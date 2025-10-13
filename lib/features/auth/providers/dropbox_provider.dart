import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';

import '../services/dropbox_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dropboxServiceProvider = FutureProvider.family
    .autoDispose<DropboxService, String>((ref, clientKey) async {
      final oauth = await ref.watch(oauth2AccountProvider.future);
      return DropboxService(oauth.clients[clientKey]);
    });
