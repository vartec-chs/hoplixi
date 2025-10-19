import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/services/dropbox/import_service.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';

/// Провайдер для сервиса импорта из Dropbox
/// Зависит от сервиса авторизации OAuth2
final dropboxImportServiceProvider = FutureProvider<ImportDropboxService>((
  ref,
) async {
  final oauth2Service = await ref.watch(oauth2AccountProvider.future);
  return ImportDropboxService(oauth2Service);
});
