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
import 'package:path/path.dart' as p;

/// Экран подтверждения и выполнения экспорта хранилища
class ExportConfirmScreen extends ConsumerStatefulWidget {
  final String storagePath;
  final String storageName;

  const ExportConfirmScreen({
    super.key,
    required this.storagePath,
    required this.storageName,
  });

  @override
  ConsumerState<ExportConfirmScreen> createState() =>
      _ExportConfirmScreenState();
}

class _ExportConfirmScreenState extends ConsumerState<ExportConfirmScreen> {
  bool _isExporting = false;
  double _progress = 0.0;
  String? _exportedArchivePath;
  bool _usePassword = false;
  final _passwordController = TextEditingController();
  List<CredentialApp> _cloudCredentials = [];

  @override
  void initState() {
    super.initState();
    _loadCloudCredentials();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadCloudCredentials() async {
    try {
      final credentialService = await ref.read(
        credentialServiceProvider.future,
      );
      final result = await credentialService.getAllCredentials();

      if (result.success && result.data != null) {
        setState(() {
          _cloudCredentials = result.data!;
        });
        logInfo(
          'Cloud credentials загружены',
          tag: 'ExportConfirmScreen',
          data: {'count': result.data!.length},
        );
      }
    } catch (e, st) {
      logError(
        'Ошибка загрузки cloud credentials',
        error: e,
        stackTrace: st,
        tag: 'ExportConfirmScreen',
      );
    }
  }

  Future<void> _showCloudExportDialog() async {
    if (_exportedArchivePath == null) {
      ToastHelper.error(title: 'Сначала создайте архив');
      return;
    }

    if (_cloudCredentials.isEmpty) {
      ToastHelper.error(title: 'Нет настроенных облачных аккаунтов');
      return;
    }

    final credential = await showDialog<CredentialApp>(
      context: context,
      builder: (context) =>
          _CloudCredentialDialog(credentials: _cloudCredentials),
    );

    if (credential != null && mounted) {
      await _performCloudExport(credential);
    }
  }

  Future<void> _performCloudExport(CredentialApp credential) async {
    if (_exportedArchivePath == null) return;

    try {
      ToastHelper.info(title: 'Начинается загрузка в облако...');

      // Инициализация сервиса
      final notifier = ref.read(dropboxServiceStateProvider.notifier);
      await notifier.init(credential.id);

      // Проверка и авторизация
      final isConnected = await notifier.check();
      if (!isConnected) {
        ToastHelper.error(title: 'Ошибка подключения к Dropbox');
        return;
      }

      // Загрузка файла (используем имя архива из пути)
      final archiveName = p.basename(_exportedArchivePath!);
      final result = await notifier.uploadStorage(
        localPath: _exportedArchivePath!,
        storageName: archiveName,
      );

      if (result.success) {
        ToastHelper.success(title: 'Архив успешно загружен в Dropbox');
        logInfo(
          'Архив экспортирован в облако',
          tag: 'ExportConfirmScreen',
          data: {'archiveName': archiveName, 'credentialId': credential.id},
        );
      } else {
        ToastHelper.error(title: result.message ?? 'Ошибка загрузки в облако');
      }
    } catch (e, st) {
      logError(
        'Ошибка облачного экспорта',
        error: e,
        stackTrace: st,
        tag: 'ExportConfirmScreen',
      );
      ToastHelper.error(title: 'Ошибка загрузки в облако');
    }
  }

  Future<void> _performExport() async {
    setState(() {
      _isExporting = true;
      _progress = 0.0;
      _exportedArchivePath = null;
    });

    try {
      logInfo(
        'Начало экспорта хранилища',
        tag: 'ExportConfirmScreen',
        data: {'path': widget.storagePath, 'name': widget.storageName},
      );

      // Имитация прогресса
      _updateProgress(0.3);

      final service = ref.read(storageExportServiceProvider);
      final result = await service.exportStorage(
        storagePath: widget.storagePath,
        password: _usePassword && _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      _updateProgress(1.0);

      if (result.success && result.data != null) {
        setState(() {
          _exportedArchivePath = result.data;
        });

        ToastHelper.success(
          title: result.message ?? 'Экспорт завершён успешно',
        );

        logInfo(
          'Экспорт завершён успешно',
          tag: 'ExportConfirmScreen',
          data: {'archivePath': result.data},
        );
      } else {
        ToastHelper.error(title: result.message ?? 'Ошибка при экспорте');
        logError(
          'Ошибка при экспорте',
          tag: 'ExportConfirmScreen',
          data: {'message': result.message},
        );
      }
    } catch (e, st) {
      logError(
        'Исключение при экспорте',
        error: e,
        stackTrace: st,
        tag: 'ExportConfirmScreen',
      );
      ToastHelper.error(title: 'Произошла ошибка при экспорте');
    } finally {
      setState(() {
        _isExporting = false;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Экспорт хранилища')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Иконка
            Icon(
              _exportedArchivePath != null ? Icons.check_circle : Icons.archive,
              size: 80,
              color: _exportedArchivePath != null
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // Заголовок
            Text(
              _exportedArchivePath != null
                  ? 'Экспорт завершён'
                  : 'Экспорт хранилища',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Информация о хранилище
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      icon: Icons.storage,
                      label: 'Хранилище',
                      value: widget.storageName,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.folder,
                      label: 'Путь',
                      value: widget.storagePath,
                      isPath: true,
                    ),
                    if (_exportedArchivePath != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.archive,
                        label: 'Архив',
                        value: p.basename(_exportedArchivePath!),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.save,
                        label: 'Сохранён в',
                        value: p.dirname(_exportedArchivePath!),
                        isPath: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Защита паролем
            if (_exportedArchivePath == null)
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
                              'Защита паролем',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Switch(
                            value: _usePassword,
                            onChanged: _isExporting
                                ? null
                                : (value) {
                                    setState(() {
                                      _usePassword = value;
                                      if (!value) {
                                        _passwordController.clear();
                                      }
                                    });
                                  },
                          ),
                        ],
                      ),
                      if (_usePassword) ...[
                        const SizedBox(height: 16),
                        CustomPasswordField(
                          controller: _passwordController,
                          label: 'Пароль для архива',
                          hintText: 'Введите пароль',
                          enabled: !_isExporting,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Архив будет защищён паролем. Сохраните пароль, он понадобится для распаковки.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Прогресс
            if (_isExporting) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 16),
              Text(
                'Создание архива... ${(_progress * 100).toInt()}%',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],

            const Spacer(),

            // Кнопки
            if (_exportedArchivePath == null && !_isExporting)
              SmoothButton(
                label: 'Создать архив',
                onPressed: _performExport,
                icon: const Icon(Icons.archive),
              ),

            if (_exportedArchivePath != null)
              Column(
                spacing: 12,
                children: [
                  SmoothButton(
                    isFullWidth: true,
                    label: 'Загрузить в облако',
                    onPressed: _showCloudExportDialog,
                    icon: const Icon(Icons.cloud_upload),
                  ),
                  SmoothButton(
                    isFullWidth: true,
                    label: 'Готово',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),

            if (_isExporting)
              const SizedBox(
                height: 56, // Высота кнопки
                child: Center(child: Text('Пожалуйста, подождите...')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPath = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
                maxLines: isPath ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Диалог выбора облачного аккаунта для экспорта
class _CloudCredentialDialog extends StatelessWidget {
  final List<CredentialApp> credentials;

  const _CloudCredentialDialog({required this.credentials});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Выберите облачный аккаунт'),
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
