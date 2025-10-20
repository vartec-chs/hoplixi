import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/utils/result_pattern/result.dart';
import 'package:hoplixi/features/auth/models/sync_providers.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/auth/providers/token_provider.dart';
import 'package:hoplixi/features/auth/providers/token_services_provider.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';
import 'package:hoplixi/features/auth/services/token_services.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_export_state.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_sync_exceptions.dart';
import 'package:hoplixi/features/cloud_sync/services/dropbox/export_service.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

final cloudExportProvider =
    AsyncNotifierProvider<CloudExportProvider, ExportState>(
      CloudExportProvider.new,
    );

class CloudExportProvider extends AsyncNotifier<ExportState> {
  late final OAuth2AccountService _oauth2AccountService;
  late final DropboxExportService _dropboxExportService;
  late final TokenServices _tokenServices;

  @override
  Future<ExportState> build() async {
    _tokenServices = await ref.read(tokenServicesProvider.future);
    _oauth2AccountService = await ref.read(oauth2AccountProvider.future);

    _dropboxExportService = DropboxExportService(_oauth2AccountService);
    return const ExportState.idle();
  }

  Future<void> export(
    DatabaseMetaForSync databaseMeta,
    String pathToDbFolderDB,
  ) async {
    state = const AsyncValue.loading();
    final startedAt = DateTime.now();
    state = AsyncData(
      ExportState.exporting(
        progress: 0.0,
        message: 'Starting Dropbox export...',
        startedAt: startedAt,
      ),
    );

    try {
      final providerType = ProviderType.dropbox;

      // Step 1: Get client key
      state = AsyncData(
        ExportState.exporting(
          progress: 0.1,
          message: 'Authorizing with Dropbox...',
          startedAt: startedAt,
        ),
      );
      final clientKeyResult = await _getClientKey(providerType);
      if (clientKeyResult.isFailure) {
        state = AsyncData(ExportState.failure(clientKeyResult.errorOrNull!));
        return;
      }
      final clientKey = clientKeyResult.dataOrNull!;

      // Step 2: Initialize Dropbox connection
      state = AsyncData(
        ExportState.exporting(
          progress: 0.15,
          message: 'Initializing Dropbox connection...',
          startedAt: startedAt,
        ),
      );
      final initResult = await _dropboxExportService
          .initializeDropboxConnection(
            clientKey,
            (error) => state = AsyncData(
              ExportState.failure(ExportException.unknown(error)),
            ),
          );
      if (initResult.isFailure) {
        state = AsyncData(
          ExportState.failure(ExportException.unknown(initResult.errorOrNull!)),
        );
        return;
      }

      // Step 3: Ensure root folder exists
      state = AsyncData(
        ExportState.exporting(
          progress: 0.2,
          message: 'Preparing cloud storage...',
          startedAt: startedAt,
        ),
      );
      final rootFolderResult = await _dropboxExportService.ensureRootFolder();
      if (rootFolderResult.isFailure) {
        state = AsyncData(
          ExportState.failure(
            ExportException.unknown(rootFolderResult.errorOrNull!),
          ),
        );
        return;
      }

      // Step 4: Ensure storage folder exists
      final storeFolderName =
          '${databaseMeta.name.replaceAll(' ', '_')}_${databaseMeta.id}';
      final exportCloudPath =
          '${_dropboxExportService.storagesRootCloudPath}/$storeFolderName';

      state = AsyncData(
        ExportState.exporting(
          progress: 0.25,
          message: 'Creating storage folder...',
          startedAt: startedAt,
        ),
      );
      final storageFolderResult = await _dropboxExportService
          .ensureStorageFolder(
            exportCloudPath,
            (error) => state = AsyncData(
              ExportState.failure(ExportException.unknown(error)),
            ),
          );
      if (storageFolderResult.isFailure) {
        state = AsyncData(
          ExportState.failure(
            ExportException.unknown(storageFolderResult.errorOrNull!),
          ),
        );
        return;
      }

      // Step 5: Create archive
      state = AsyncData(
        ExportState.exporting(
          progress: 0.3,
          message: 'Creating archive for export...',
          startedAt: startedAt,
        ),
      );
      final archiveResult = await _dropboxExportService.createArchive(
        storagePath: pathToDbFolderDB,
      );
      if (archiveResult.isFailure) {
        state = AsyncData(
          ExportState.failure(
            ExportException.unknown(archiveResult.errorOrNull!),
          ),
        );
        return;
      }
      final archiveData = archiveResult.dataOrNull!;
      final exportTime = DateTime.now().microsecondsSinceEpoch;

      // Step 6: Upload archive to Dropbox
      state = AsyncData(
        ExportState.exporting(
          progress: 0.4,
          message: 'Uploading archive to Dropbox...',
          startedAt: startedAt,
        ),
      );
      final uploadResult = await _dropboxExportService.uploadArchiveToDropbox(
        exportCloudPath: exportCloudPath,
        exportArchivePath: archiveData.archivePath,
        exportTime: exportTime,
        onFileProgress: (progress, message) {
          state = AsyncData(
            ExportState.fileProgress(progress: progress, message: message),
          );
        },
        onError: (error) {
          state = AsyncData(
            ExportState.failure(ExportException.unknown(error)),
          );
        },
      );
      if (uploadResult.isFailure) {
        state = AsyncData(
          ExportState.failure(
            ExportException.unknown(uploadResult.errorOrNull!),
          ),
        );
        return;
      }

      // Step 7: Success
      state = AsyncData(
        ExportState.success(
          fileName: uploadResult.dataOrNull?.name ?? '',
          exportTime: exportTime,
        ),
      );
    } catch (e) {
      state = AsyncData(
        ExportState.failure(
          ExportException.unknown(
            'An unexpected error occurred during export',
            cause: e,
          ),
        ),
      );
    }
  }

  Future<Result<String?, ExportException>> _getClientKey(
    ProviderType providerType,
  ) async {
    try {
      final token = await _tokenServices.findOneBySuffix(providerType.name);
      if (token == null) {
        return Result.failure(
          ExportException.auth(
            'No token found for provider: ${providerType.name}',
          ),
        );
      }
      final tokenInfo = TokenInfo(key: token.id, token: token);
      // final tokenInfo = await _tokenServices.getTokenInfo();
      final result = await _oauth2AccountService.authorizeWithToken(tokenInfo);
      if (result.success) {
        return Result.success(result.data);
      } else {
        return Result.failure(
          ExportException.auth(
            'Failed to authorize with token for provider: ${providerType.name}',
          ),
        );
      }
    } catch (e) {
      return Result.failure(
        ExportException.unknown(
          'An unknown error occurred while getting client key for provider: ${providerType.name}',
          cause: e,
        ),
      );
    }
  }
}
