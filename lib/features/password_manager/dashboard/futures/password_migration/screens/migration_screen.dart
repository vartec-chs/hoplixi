import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/widgets/button.dart';
import 'package:hoplixi/shared/widgets/text_field.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hoplixi/features/password_manager/dashboard/providers/data_refresh_trigger_provider.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/migration_provider.dart';

class MigrationScreen extends ConsumerStatefulWidget {
  const MigrationScreen({super.key});

  @override
  ConsumerState<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends ConsumerState<MigrationScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Импорт / Экспорт'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.upload_file), text: 'Экспорт'),
              Tab(icon: Icon(Icons.download), text: 'Импорт'),
            ],
          ),
        ),
        body: const SafeArea(
          child: TabBarView(children: [ExportTab(), ImportTab()]),
        ),
      ),
    );
  }
}

// =============================================================================
// ТАБ ЭКСПОРТА
// =============================================================================

class ExportTab extends ConsumerStatefulWidget {
  const ExportTab({super.key});

  @override
  ConsumerState<ExportTab> createState() => _ExportTabState();
}

class _ExportTabState extends ConsumerState<ExportTab> {
  final _passwordCountController = TextEditingController(text: '10');
  final _categoryCountController = TextEditingController(text: '5');

  @override
  void dispose() {
    _passwordCountController.dispose();
    _categoryCountController.dispose();
    super.dispose();
  }

  Future<void> _generateAndExport() async {
    final passwordCount = int.tryParse(_passwordCountController.text);
    final categoryCount = int.tryParse(_categoryCountController.text);

    if (passwordCount == null || categoryCount == null) {
      ToastHelper.error(title: 'Введите корректные числа');
      return;
    }

    if (passwordCount < 1 || categoryCount < 1) {
      ToastHelper.error(title: 'Количество должно быть больше 0');
      return;
    }

    try {
      // Получаем папку загрузок
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        ToastHelper.error(title: 'Не удалось получить папку загрузок');
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/hoplixi_migration_$timestamp.json';

      await ref
          .read(exportNotifierProvider.notifier)
          .generateAndSave(
            passwordCount: passwordCount,
            categoryCount: categoryCount,
            filePath: filePath,
          );
    } catch (e) {
      ToastHelper.error(title: 'Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Генерация тестовых данных для миграции',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          PrimaryTextField(
            controller: _passwordCountController,
            label: 'Количество паролей',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          PrimaryTextField(
            controller: _categoryCountController,
            label: 'Количество категорий',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          if (exportState.state == ExportState.generating)
            const Center(child: CircularProgressIndicator())
          else if (exportState.state == ExportState.success)
            _buildSuccessWidget(exportState.filePath!)
          else if (exportState.state == ExportState.error)
            _buildErrorWidget(exportState.errorMessage!)
          else
            SmoothButton(
              onPressed: _generateAndExport,
              label: 'Сгенерировать и сохранить',
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget(String filePath) {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        Text(
          'Файл успешно сохранён',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          filePath,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SmoothButton(
          onPressed: () async {
            try {
              await OpenAppFile.open(filePath, mimeType: 'application/json');
            } catch (e) {
              ToastHelper.error(title: 'Не удалось открыть файл: $e');
            }
          },
          label: 'Открыть файл',
        ),
        const SizedBox(height: 16),
        const Text(
          'Заполните файл и возвращайтесь для импорта',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SmoothButton(
          onPressed: () {
            ref.read(exportNotifierProvider.notifier).reset();
          },
          label: 'Создать новый',
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Column(
      children: [
        const Icon(Icons.error, color: Colors.red, size: 64),
        const SizedBox(height: 16),
        Text(
          'Ошибка',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorMessage,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SmoothButton(
          onPressed: () {
            ref.read(exportNotifierProvider.notifier).reset();
          },
          label: 'Попробовать снова',
        ),
      ],
    );
  }
}

// =============================================================================
// ТАБ ИМПОРТА
// =============================================================================

class ImportTab extends ConsumerStatefulWidget {
  const ImportTab({super.key});

  @override
  ConsumerState<ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends ConsumerState<ImportTab> {
  Future<void> _pickAndParseFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;
      await ref.read(importNotifierProvider.notifier).parseFile(filePath);
    } catch (e) {
      ToastHelper.error(title: 'Ошибка при выборе файла: $e');
    }
  }

  Future<void> _confirmImport() async {
    await ref.read(importNotifierProvider.notifier).importToDatabase();
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Импорт данных из файла',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          if (importState.state == ImportState.idle)
            _buildIdleWidget()
          else if (importState.state == ImportState.parsing)
            const Center(child: CircularProgressIndicator())
          else if (importState.state == ImportState.preview)
            _buildPreviewWidget(importState)
          else if (importState.state == ImportState.importing)
            const Center(child: CircularProgressIndicator())
          else if (importState.state == ImportState.success)
            _buildSuccessImportWidget(importState.errorMessage!)
          else if (importState.state == ImportState.error)
            _buildErrorImportWidget(importState.errorMessage!),
        ],
      ),
    );
  }

  Widget _buildIdleWidget() {
    return Column(
      children: [
        const Icon(Icons.upload_file, size: 64, color: Colors.blue),
        const SizedBox(height: 16),
        const Text(
          'Выберите JSON файл для импорта',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SmoothButton(onPressed: _pickAndParseFile, label: 'Выбрать файл'),
      ],
    );
  }

  Widget _buildPreviewWidget(ImportStateModel state) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Предпросмотр данных',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Категорий: ${state.categories?.length ?? 0}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Паролей: ${state.passwords?.length ?? 0}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.categories != null &&
                      state.categories!.isNotEmpty) ...[
                    const Text(
                      'Категории:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...state.categories!
                        .take(5)
                        .map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• ${category.name}'),
                          ),
                        ),
                    if (state.categories!.length > 5)
                      Text('  ... и ещё ${state.categories!.length - 5}'),
                    const SizedBox(height: 16),
                  ],
                  if (state.passwords != null &&
                      state.passwords!.isNotEmpty) ...[
                    const Text(
                      'Пароли:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...state.passwords!
                        .take(5)
                        .map(
                          (password) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• ${password.name}'),
                          ),
                        ),
                    if (state.passwords!.length > 5)
                      Text('  ... и ещё ${state.passwords!.length - 5}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SmoothButton(onPressed: _confirmImport, label: 'Импортировать'),
          const SizedBox(height: 8),
          SmoothButton(
            onPressed: () {
              ref.read(importNotifierProvider.notifier).reset();
            },
            label: 'Отмена',
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessImportWidget(String warningMessage) {
    try {
      DataRefreshHelper.refreshPasswords(ref);
    } catch (e) {
      // Игнорируем ошибку обновления данных
    }
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        Text(
          'Импорт завершён успешно!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        if (warningMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            warningMessage,
            style: const TextStyle(fontSize: 16, color: Colors.orange),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        SmoothButton(
          onPressed: () {
            ref.read(importNotifierProvider.notifier).reset();
          },
          label: 'Импортировать ещё',
        ),
      ],
    );
  }

  Widget _buildErrorImportWidget(String errorMessage) {
    return Column(
      children: [
        const Icon(Icons.error, color: Colors.red, size: 64),
        const SizedBox(height: 16),
        Text(
          'Ошибка импорта',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          errorMessage,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SmoothButton(
          onPressed: () {
            ref.read(importNotifierProvider.notifier).reset();
          },
          label: 'Попробовать снова',
        ),
      ],
    );
  }
}
