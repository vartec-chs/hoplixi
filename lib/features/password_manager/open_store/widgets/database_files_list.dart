import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/dto/database_file_info.dart';

/// Виджет для отображения списка найденных файлов БД
class DatabaseFilesList extends ConsumerWidget {
  final List<DatabaseFileInfo> files;
  final DatabaseFileInfo? selectedFile;
  final void Function(DatabaseFileInfo) onFileSelected;
  final bool showAllFiles;
  final VoidCallback? onToggleShowAll;

  const DatabaseFilesList({
    super.key,
    required this.files,
    this.selectedFile,
    required this.onFileSelected,
    this.showAllFiles = false,
    this.onToggleShowAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (files.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(
                Icons.folder_open,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Файлы хранилищ не найдены',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Создайте новое хранилище или выберите файл вручную',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Определяем какие файлы показывать
    final filesToShow = showAllFiles ? files : [files.first];
    final hasMoreFiles = files.length > 1;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  showAllFiles
                      ? 'Все найденные хранилища'
                      : 'Недавние хранилища',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (hasMoreFiles && onToggleShowAll != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 0),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onToggleShowAll,
                    icon: Icon(
                      showAllFiles ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                    ),
                    label: Text(
                      showAllFiles
                          ? 'Скрыть'
                          : 'Показать все (${files.length})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          ...filesToShow.map(
            (file) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _DatabaseFileItem(
                file: file,
                isSelected: selectedFile?.path == file.path,
                onTap: () => onFileSelected(file),
              ),
            ),
          ),

          const SizedBox(height: 8),

          if (!showAllFiles && hasMoreFiles)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Text(
                'И ещё ${files.length - 1} файл(ов)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Элемент списка файлов БД
class _DatabaseFileItem extends StatelessWidget {
  final DatabaseFileInfo file;
  final bool isSelected;
  final VoidCallback onTap;

  const _DatabaseFileItem({
    required this.file,
    required this.isSelected,
    required this.onTap,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.storage,
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        file.displayName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Изменён: ${_formatDate(file.lastModified)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Размер: ${_formatFileSize(file.sizeBytes)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.chevron_right),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
