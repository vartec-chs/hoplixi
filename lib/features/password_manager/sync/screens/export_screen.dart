import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/database_file_info.dart';
import 'package:hoplixi/hoplixi_store/models/database_entry.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:intl/intl.dart';

/// Экран выбора хранилища для экспорта
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<DatabaseEntry> _historyEntries = [];
  List<DatabaseFileInfo> _fileSystemEntries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final manager = await ref.read(hoplixiStoreManagerProvider.future);

      // Загружаем историю
      final history = await manager.getDatabaseHistory();

      // Загружаем файлы из файловой системы
      final filesResult = await manager.findDatabaseFiles();

      setState(() {
        _historyEntries = history;
        _fileSystemEntries = filesResult.files;
        _isLoading = false;
      });

      logInfo(
        'Данные для экспорта загружены',
        tag: 'ExportScreen',
        data: {
          'historyCount': history.length,
          'filesCount': filesResult.files.length,
        },
      );
    } catch (e, st) {
      logError(
        'Ошибка загрузки данных для экспорта',
        error: e,
        stackTrace: st,
        tag: 'ExportScreen',
      );
      setState(() {
        _error = 'Ошибка загрузки данных: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onSelectStorage(String path, String name) {
    logDebug(
      'Выбрано хранилище для экспорта',
      tag: 'ExportScreen',
      data: {'path': path, 'name': name},
    );
    context.push(AppRoutes.exportConfirm, extra: {'path': path, 'name': name});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Экспорт хранилища'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'История', icon: Icon(Icons.history)),
            Tab(text: 'Файловая система', icon: Icon(Icons.folder)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildHistoryTab(), _buildFileSystemTab()],
            ),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'История пуста',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _historyEntries.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final entry = _historyEntries[index];
        return _buildStorageCard(
          name: entry.name,
          path: entry.path,
          description: entry.description,
          lastAccessed: entry.lastAccessed,
          createdAt: entry.createdAt,
        );
      },
    );
  }

  Widget _buildFileSystemTab() {
    if (_fileSystemEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Хранилища не найдены',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _fileSystemEntries.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final entry = _fileSystemEntries[index];
        return _buildStorageCard(
          name: entry.displayName,
          path: entry.path,
          description: entry.description,
          lastModified: entry.lastModified,
          sizeBytes: entry.sizeBytes,
        );
      },
    );
  }

  Widget _buildStorageCard({
    required String name,
    required String path,
    String? description,
    DateTime? lastAccessed,
    DateTime? lastModified,
    DateTime? createdAt,
    int? sizeBytes,
  }) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final date = lastAccessed ?? lastModified ?? createdAt;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onSelectStorage(path, name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (date != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateFormat.format(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (sizeBytes != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.data_usage,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatBytes(sizeBytes),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} ГБ';
  }
}
