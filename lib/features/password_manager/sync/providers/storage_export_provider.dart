import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/sync/services/storage_export_service.dart';

/// Провайдер сервиса экспорта/импорта хранилищ
final storageExportServiceProvider = Provider<StorageExportService>((ref) {
  return StorageExportService();
});
