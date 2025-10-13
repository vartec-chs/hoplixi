import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/providers/dropbox_provider.dart';
import 'package:hoplixi/features/auth/widgets/auth_modal.dart';
import 'package:hoplixi/shared/widgets/index.dart';
import 'package:hoplixi/features/password_manager/sync/providers/storage_export_provider.dart';
import 'package:hoplixi/app/router/routes_path.dart';

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

  @override
  void initState() {
    super.initState();
    _passwordController.text = '';
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

      final destinationDir = await AppPaths.appStoragePath;

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

  /// Показывает модальное окно выбора облачного провайдера и выполняет импорт
  Future<void> _showCloudImportDialog() async {
    if (!mounted) return;

    // Показываем AuthModal для выбора провайдера и авторизации
    final clientKey = await showAuthModal(context);

    if (clientKey == null) {
      // Пользователь отменил или произошла ошибка
      logDebug('Авторизация отменена или не удалась', tag: 'ImportScreen');
      return;
    }

    if (!mounted) return;

    // Выполняем импорт из облака
    await _performCloudImport(clientKey);
  }

  /// Выполняет импорт архива из облака используя clientKey
  Future<void> _performCloudImport(String clientKey) async {
    setState(() {
      _isImporting = true;
      _progress = 0.0;
      _importedStoragePath = null;
    });

    try {
      logInfo(
        'Начало импорта из облака',
        tag: 'ImportScreen',
        data: {'clientKey': clientKey},
      );

      ToastHelper.info(
        title: 'Импорт из облака',
        description: 'Инициализация подключения...',
      );

      _updateProgress(0.2);

      // Получаем сервис Dropbox через провайдер
      final dropboxServiceAsync = ref.read(
        dropboxServiceProvider(clientKey).future,
      );
      final dropboxService = await dropboxServiceAsync;

      // Инициализируем Dropbox
      final initResult = await dropboxService.initialize();
      if (!initResult.success) {
        ToastHelper.error(
          title: 'Ошибка инициализации',
          description:
              initResult.message ?? 'Не удалось подключиться к Dropbox',
        );
        return;
      }

      logInfo('Dropbox инициализирован успешно', tag: 'ImportScreen');

      _updateProgress(0.4);

      ToastHelper.info(
        title: 'Импорт из облака',
        description: 'Загрузка архива...',
      );

      // Получаем путь для сохранения
      final destinationDir = await AppPaths.appStoragePath;

      // Импортируем самый новый архив из облака
      final importResult = await dropboxService.import(destinationDir);

      if (!importResult.success || importResult.data == null) {
        ToastHelper.error(
          title: 'Ошибка импорта',
          description: importResult.message ?? 'Не удалось загрузить архив',
        );
        return;
      }

      _updateProgress(0.7);

      final downloadedArchivePath = importResult.data!;

      logInfo(
        'Архив загружен из облака',
        tag: 'ImportScreen',
        data: {'archivePath': downloadedArchivePath},
      );

      // Спрашиваем пароль, если архив может быть защищён
      String? password;
      if (mounted) {
        password = await _showPasswordDialog();
      }

      _updateProgress(0.8);

      ToastHelper.info(
        title: 'Импорт из облака',
        description: 'Распаковка архива...',
      );

      // Распаковываем архив
      final service = ref.read(storageExportServiceProvider);
      final extractResult = await service.importStorage(
        archivePath: downloadedArchivePath,
        destinationDir: destinationDir,
        password: password?.isNotEmpty == true ? password : null,
      );

      _updateProgress(1.0);

      if (extractResult.success && extractResult.data != null) {
        setState(() {
          _importedStoragePath = extractResult.data;
        });

        ToastHelper.success(
          title: 'Успешно',
          description: 'Хранилище импортировано из облака',
        );

        logInfo(
          'Импорт из облака завершён успешно',
          tag: 'ImportScreen',
          data: {'clientKey': clientKey, 'storagePath': extractResult.data},
        );
      } else {
        ToastHelper.error(
          title: 'Ошибка распаковки',
          description: extractResult.message ?? 'Не удалось распаковать архив',
        );

        logError(
          'Ошибка распаковки архива',
          tag: 'ImportScreen',
          data: {'message': extractResult.message},
        );
      }
    } catch (e, st) {
      logError(
        'Исключение при импорте из облака',
        error: e,
        stackTrace: st,
        tag: 'ImportScreen',
      );

      ToastHelper.error(
        title: 'Ошибка',
        description: 'Произошла ошибка при импорте из облака',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    String? result;

    try {
      final dialogResult = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Пароль архива'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Если архив защищён паролем, введите его:'),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: primaryInputDecoration(
                  context,
                  labelText: 'Пароль',
                  helperText: 'Пароль (необязательно если его нет)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Пропустить'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Извлекаем значение ПОСЛЕ закрытия диалога, но ДО dispose
      if (dialogResult == true) {
        final pwd = _passwordController.text.trim();
        result = pwd.isNotEmpty ? pwd : null;
      }

      return result;
    } finally {
      // Dispose контроллера только после извлечения значения
      _passwordController.text = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Импорт хранилища')),
      body: SafeArea(
        child: Padding(
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
                  onPressed: _showCloudImportDialog,
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
      ),
    );
  }
}
