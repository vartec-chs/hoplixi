import 'package:dropbox_api/dropbox_api.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';
import 'package:hoplixi/features/cloud_sync/providers/credential_provider.dart';
import 'package:hoplixi/features/cloud_sync/providers/dropbox_provider.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/features/global/widgets/password_field.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/password_manager/sync/providers/storage_export_provider.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:intl/intl.dart';

/// Экран импорта хранилища
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  bool _isImporting = false;
  double _progress = 0.0;
  String? _importedStoragePath;
  String? _selectedArchivePath;
  bool _requiresPassword = false;
  final _passwordController = TextEditingController();
  List<CredentialApp> _cloudCredentials = [];

  @override
  void initState() {
    super.initState();
    _passwordController.text = '';
    _loadCloudCredentials();
  }

  Future<void> _loadCloudCredentials() async {
    try {
      final service = await ref.read(credentialServiceProvider.future);
      final result = await service.getAllCredentials();
      if (result.success && result.data != null) {
        setState(() {
          _cloudCredentials = result.data!
              .where((c) => c.type == CredentialOAuthType.dropbox)
              .toList();
        });
      }
    } catch (e) {
      logError('Failed to load cloud credentials', error: e);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickArchive() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Выберите архив хранилища',
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _selectedArchivePath = file.path;
          });

          logInfo(
            'Выбран архив для импорта',
            tag: 'ImportScreen',
            data: {'path': file.path},
          );
        }
      }
    } catch (e, st) {
      logError(
        'Ошибка при выборе архива',
        error: e,
        stackTrace: st,
        tag: 'ImportScreen',
      );
      ToastHelper.error(title: 'Ошибка при выборе архива');
    }
  }

  Future<void> _performImport() async {
    if (_selectedArchivePath == null) {
      ToastHelper.warning(title: 'Выберите архив для импорта');
      return;
    }

    setState(() {
      _isImporting = true;
      _progress = 0.0;
      _importedStoragePath = null;
    });

    try {
      logInfo(
        'Начало импорта хранилища',
        tag: 'ImportScreen',
        data: {'archivePath': _selectedArchivePath},
      );

      // Имитация прогресса
      _updateProgress(0.3);

      final manager = await ref.read(hoplixiStoreManagerProvider.future);
      final destinationDir = await manager.getDefaultDatabasePath();

      _updateProgress(0.5);

      final service = ref.read(storageExportServiceProvider);
      final result = await service.importStorage(
        archivePath: _selectedArchivePath!,
        destinationDir: destinationDir,
        password: _requiresPassword && _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      _updateProgress(1.0);

      if (result.success && result.data != null) {
        setState(() {
          _importedStoragePath = result.data;
        });

        ToastHelper.success(title: result.message ?? 'Импорт завершён успешно');

        logInfo(
          'Импорт завершён успешно',
          tag: 'ImportScreen',
          data: {'storagePath': result.data},
        );
      } else {
        ToastHelper.error(title: result.message ?? 'Ошибка при импорте');
        logError(
          'Ошибка при импорте',
          tag: 'ImportScreen',
          data: {'message': result.message},
        );
      }
    } catch (e, st) {
      logError(
        'Исключение при импорте',
        error: e,
        stackTrace: st,
        tag: 'ImportScreen',
      );
      ToastHelper.error(title: 'Произошла ошибка при импорте');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  void _updateProgress(double value) {
    if (mounted) {
      setState(() {
        _progress = value;
      });
    }
  }

  void _openImportedStorage() {
    if (_importedStoragePath == null) return;

    logInfo(
      'Переход к открытию импортированного хранилища',
      tag: 'ImportScreen',
      data: {'path': _importedStoragePath},
    );

    // Переходим на экран открытия хранилища
    context.go(AppRoutes.openStore);
  }

  Future<void> _showCloudImportDialog() async {
    if (_cloudCredentials.isEmpty) {
      ToastHelper.warning(title: 'Нет настроенных облачных хранилищ');
      return;
    }

    final credential = await showDialog<CredentialApp>(
      context: context,
      builder: (context) =>
          _CloudCredentialDialog(credentials: _cloudCredentials),
    );

    if (credential != null) {
      await _performCloudImport(credential);
    }
  }

  Future<void> _performCloudImport(CredentialApp credential) async {
    setState(() {
      _isImporting = true;
      _progress = 0.0;
      _importedStoragePath = null;
    });

    try {
      logInfo(
        'Начало импорта из облака',
        tag: 'ImportScreen',
        data: {'credentialId': credential.id},
      );

      _updateProgress(0.2);

      // Инициализируем Dropbox notifier
      final notifier = ref.read(dropboxServiceStateProvider.notifier);
      final initialized = await notifier.init(credential.id);

      if (!initialized) {
        ToastHelper.error(
          title: 'Не удалось подключиться к облачному хранилищу',
        );
        return;
      }

      _updateProgress(0.4);

      // Получаем список хранилищ
      final storagesResult = await notifier.listStorages();
      if (!storagesResult.success || storagesResult.data!.isEmpty) {
        ToastHelper.warning(title: 'В облаке не найдено хранилищ');
        return;
      }

      _updateProgress(0.5);

      // Показываем диалог выбора хранилища
      final selectedStorage = await showDialog<DropboxFile>(
        context: mounted ? context : throw Exception('Context not mounted'),
        builder: (context) =>
            _CloudStorageListDialog(storages: storagesResult.data!),
      );

      if (selectedStorage == null) {
        return;
      }

      _updateProgress(0.6);

      // Скачиваем хранилище
      final manager = await ref.read(hoplixiStoreManagerProvider.future);
      final destinationDir = await manager.getDefaultDatabasePath();

      final downloadResult = await notifier.downloadStorage(
        storageName: selectedStorage.name,
        localDir: destinationDir,
      );

      _updateProgress(1.0);

      if (downloadResult.success && downloadResult.data != null) {
        setState(() {
          _importedStoragePath = downloadResult.data;
        });

        ToastHelper.success(
          title: downloadResult.message ?? 'Импорт завершён успешно',
        );

        logInfo(
          'Импорт из облака завершён успешно',
          tag: 'ImportScreen',
          data: {'storagePath': downloadResult.data},
        );
      } else {
        ToastHelper.error(
          title: downloadResult.message ?? 'Ошибка при импорте',
        );
        logError(
          'Ошибка при импорте из облака',
          tag: 'ImportScreen',
          data: {'message': downloadResult.message},
        );
      }
    } catch (e, st) {
      logError(
        'Исключение при импорте из облака',
        error: e,
        stackTrace: st,
        tag: 'ImportScreen',
      );
      ToastHelper.error(title: 'Произошла ошибка при импорте');
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Импорт хранилища')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Иконка
            Icon(
              _importedStoragePath != null
                  ? Icons.check_circle
                  : Icons.download,
              size: 80,
              color: _importedStoragePath != null
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Заголовок
            Text(
              _importedStoragePath != null
                  ? 'Импорт завершён'
                  : 'Импорт хранилища',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Описание
            if (_importedStoragePath == null)
              Text(
                'Выберите способ импорта хранилища',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 32),

            // Информация о выбранном архиве
            if (_selectedArchivePath != null && _importedStoragePath == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.archive,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Выбранный архив',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedArchivePath!.split('\\').last,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedArchivePath = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // Поле для пароля (если архив защищён)
            if (_selectedArchivePath != null && _importedStoragePath == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Архив защищён паролем?',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Switch(
                            value: _requiresPassword,
                            onChanged: _isImporting
                                ? null
                                : (value) {
                                    setState(() {
                                      _requiresPassword = value;
                                      if (!value) {
                                        _passwordController.clear();
                                      }
                                    });
                                  },
                          ),
                        ],
                      ),
                      if (_requiresPassword) ...[
                        const SizedBox(height: 16),
                        CustomPasswordField(
                          controller: _passwordController,
                          label: 'Пароль для распаковки',
                          hintText: 'Введите пароль',
                          enabled: !_isImporting,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Введите пароль, который был установлен при создании архива.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Информация об импортированном хранилище
            if (_importedStoragePath != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.storage,
                            color: theme.colorScheme.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Хранилище импортировано',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _importedStoragePath!.split('\\').last,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Прогресс
            if (_isImporting) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Text(
                'Импорт хранилища... ${(_progress * 100).toInt()}%',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],

            const Spacer(),

            // Кнопки
            if (_importedStoragePath == null && !_isImporting) ...[
              SmoothButton(
                isFullWidth: true,
                label: 'Импорт из архива',
                onPressed: _selectedArchivePath == null
                    ? _pickArchive
                    : _performImport,
                icon: Icon(
                  _selectedArchivePath == null
                      ? Icons.folder_zip
                      : Icons.upload,
                ),
              ),
              const SizedBox(height: 12),
              SmoothButton(
                isFullWidth: true,
                label: 'Импорт из облака',
                onPressed: _cloudCredentials.isEmpty
                    ? null
                    : _showCloudImportDialog,
                icon: const Icon(Icons.cloud_download),
                type: SmoothButtonType.outlined,
              ),
            ],

            if (_importedStoragePath != null)
              Column(
                children: [
                  SmoothButton(
                    isFullWidth: true,
                    label: 'Открыть хранилище',
                    onPressed: _openImportedStorage,
                    icon: const Icon(Icons.folder_open),
                  ),
                  const SizedBox(height: 12),
                  SmoothButton(
                    isFullWidth: true,
                    label: 'Закрыть',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.close),
                    type: SmoothButtonType.outlined,
                  ),
                ],
              ),

            if (_isImporting)
              const SizedBox(
                height: 56,
                child: Center(child: Text('Пожалуйста, подождите...')),
              ),
          ],
        ),
      ),
    );
  }
}

/// Диалог выбора облачного credential
class _CloudCredentialDialog extends StatelessWidget {
  final List<CredentialApp> credentials;

  const _CloudCredentialDialog({required this.credentials});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Выберите облачное хранилище'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: credentials.length,
          itemBuilder: (context, index) {
            final credential = credentials[index];
            return ListTile(
              leading: Icon(Icons.cloud, color: theme.colorScheme.primary),
              title: Text(_getTypeName(credential.type)),
              subtitle: Text('ID: ${credential.clientId.substring(0, 10)}...'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pop(credential),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ],
    );
  }

  String _getTypeName(CredentialOAuthType type) {
    switch (type) {
      case CredentialOAuthType.dropbox:
        return 'Dropbox';
      case CredentialOAuthType.google:
        return 'Google Drive';
      case CredentialOAuthType.onedrive:
        return 'OneDrive';
      case CredentialOAuthType.icloud:
        return 'iCloud';
      case CredentialOAuthType.other:
        return 'Другое';
    }
  }
}

/// Диалог выбора хранилища из облака
class _CloudStorageListDialog extends StatelessWidget {
  final List<DropboxFile> storages;

  const _CloudStorageListDialog({required this.storages});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return AlertDialog(
      title: const Text('Выберите хранилище'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: storages.length,
          itemBuilder: (context, index) {
            final storage = storages.length - 1 - index; // Обратный порядок
            final file = storages[storage];
            return ListTile(
              leading: Icon(Icons.storage, color: theme.colorScheme.primary),
              title: Text(file.name),
              subtitle: Text(
                file.serverModified != null
                    ? dateFormat.format(file.serverModified!)
                    : 'Нет данных',
              ),
              trailing: const Icon(Icons.download),
              onTap: () => Navigator.of(context).pop(file),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}
