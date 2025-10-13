import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/password_manager/new_cloud_sync/services/export_service.dart';
import 'package:riverpod/riverpod.dart';

final exportDropboxProvider = FutureProvider.autoDispose<ExportDropboxService>((
  ref,
) async {
  final accountService = await ref.watch(oauth2AccountProvider.future);
  return ExportDropboxService(accountService);
});
