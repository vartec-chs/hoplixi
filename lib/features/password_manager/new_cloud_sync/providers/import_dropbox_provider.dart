import 'package:riverpod/riverpod.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/services/import_service.dart';

final importDropboxProvider = FutureProvider<ImportDropboxService>((ref) async {
  final accountService = await ref.watch(oauth2AccountProvider.future);
  return ImportDropboxService(accountService);
});
