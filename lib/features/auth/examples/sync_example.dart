import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';
import 'package:hoplixi/features/auth/services/services.dart';
import 'package:hoplixi/core/utils/toastification.dart';

/// Пример использования сервисов синхронизации архивов
class SyncExample {
  late final SyncMetadataService _metadataService;
  late final DropboxService _dropboxService;

  SyncExample(OAuth2RestClient? client) {
    _metadataService = SyncMetadataService();
    _dropboxService = DropboxService(client);
  }

  /// Пример экспорта архива в Dropbox
  Future<void> exportExample(String localArchivePath) async {
    // 1. Инициализация Dropbox
    final initResult = await _dropboxService.initialize();
    if (!initResult.success) {
      ToastHelper.error(
        title: 'Ошибка инициализации',
        description: initResult.message ?? 'Не удалось подключиться к Dropbox',
      );
      return;
    }

    // 2. Экспорт архива
    final exportResult = await _dropboxService.export(localArchivePath);

    if (exportResult.success) {
      ToastHelper.success(
        title: 'Успешно',
        description: 'Архив загружен в облако: ${exportResult.data}',
      );

      // 3. Опционально: показать список архивов
      await _showArchivesList();
    } else {
      ToastHelper.error(
        title: 'Ошибка экспорта',
        description: exportResult.message ?? 'Не удалось загрузить архив',
      );
    }
  }

  /// Пример импорта архива из Dropbox
  Future<String?> importExample(String destinationPath) async {
    // 1. Импорт самого нового архива
    final importResult = await _dropboxService.import(destinationPath);

    if (importResult.success) {
      final downloadedPath = importResult.data!;

      ToastHelper.success(
        title: 'Успешно',
        description: 'Архив загружен и проверен',
      );

      // 2. Возвращаем путь к загруженному файлу
      return downloadedPath;
    } else {
      ToastHelper.error(
        title: 'Ошибка импорта',
        description: importResult.message ?? 'Не удалось загрузить архив',
      );
      return null;
    }
  }

  /// Показать список архивов в облаке
  Future<void> _showArchivesList() async {
    final listResult = await _dropboxService.listArchives();

    if (listResult.success && listResult.data != null) {
      final archives = listResult.data!;

      print('=== Архивы в облаке (${archives.length}) ===');
      for (final archive in archives) {
        final sizeKB = (archive.size / 1024).toStringAsFixed(2);
        final date = archive.uploadedAt.toLocal();

        print('📦 ${archive.fileName}');
        print('   Размер: $sizeKB KB');
        print('   Загружен: $date');
        print('   Checksum: ${archive.checksum.substring(0, 16)}...');
        print('');
      }
    }
  }

  /// Пример проверки контрольной суммы
  Future<bool> verifyArchiveIntegrity(String archivePath) async {
    // Вычислить контрольную сумму
    final checksumResult = await _metadataService.calculateChecksum(
      archivePath,
    );

    if (!checksumResult.success || checksumResult.data == null) {
      print('Ошибка вычисления контрольной суммы');
      return false;
    }

    final checksum = checksumResult.data!;
    print('Контрольная сумма файла: $checksum');

    // Проверить с ожидаемой (из облака, например)
    final expectedChecksum = 'some_expected_checksum_here';
    final verifyResult = await _metadataService.verifyChecksum(
      archivePath,
      expectedChecksum,
    );

    return verifyResult.success && verifyResult.data == true;
  }

  /// Пример создания имени архива
  String createArchiveName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return _metadataService.generateArchiveName('storage', timestamp);
    // Результат: storage_1234567890.zip
  }

  /// Пример извлечения timestamp из имени архива
  void parseArchiveName(String fileName) {
    final timestamp = _metadataService.parseTimestampFromFileName(fileName);

    if (timestamp != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      print('Архив создан: $date');
    } else {
      print('Неверный формат имени архива');
    }
  }
}

/// Пример использования с Riverpod
/// 
/// // В providers.dart:
/// final syncMetadataServiceProvider = Provider<SyncMetadataService>((ref) {
///   return SyncMetadataService();
/// });
/// 
/// final dropboxServiceProvider = Provider<DropboxService>((ref) {
///   final client = ref.watch(oauth2ClientProvider);
///   final metadataService = ref.read(syncMetadataServiceProvider);
///   return DropboxService(client, metadataService);
/// });
/// 
/// // В виджете:
/// class ExportButton extends ConsumerWidget {
///   final String archivePath;
///   
///   const ExportButton({required this.archivePath});
///   
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final dropboxService = ref.read(dropboxServiceProvider);
///     
///     return SmoothButton(
///       label: 'Экспорт в Dropbox',
///       icon: const Icon(Icons.cloud_upload),
///       onPressed: () async {
///         final result = await dropboxService.export(archivePath);
///         
///         if (result.success) {
///           ToastHelper.success(title: 'Архив загружен в облако');
///         } else {
///           ToastHelper.error(
///             title: 'Ошибка',
///             description: result.message,
///           );
///         }
///       },
///     );
///   }
/// }
