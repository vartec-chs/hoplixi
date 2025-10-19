import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/cloud_sync/services/dropbox/export_service.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';

/// Провайдер для сервиса экспорта в Dropbox
/// Зависит от сервиса авторизации OAuth2 (FutureProvider)
final dropboxExportServiceProvider = FutureProvider<DropboxExportService>((
  ref,
) async {
  final oauth2Service = await ref.watch(oauth2AccountProvider.future);
  return DropboxExportService(oauth2Service);
});
