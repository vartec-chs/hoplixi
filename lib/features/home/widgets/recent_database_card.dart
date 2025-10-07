import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/models/database_entry.dart';
import 'package:hoplixi/features/global/widgets/button.dart';

/// Виджет для отображения недавно открытой базы данных
class RecentDatabaseCard extends StatelessWidget {
  final DatabaseEntry database;
  final bool isLoading;
  final bool isAutoOpening;
  final VoidCallback? onOpenAuto;
  final VoidCallback? onOpenManual;
  final VoidCallback? onRemove;

  const RecentDatabaseCard({
    required this.database,
    this.isLoading = false,
    this.isAutoOpening = false,
    this.onOpenAuto,
    this.onOpenManual,
    this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      // margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок секции
            Row(
              children: [
                Icon(Icons.history, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Недавно открытая база данных',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Информация о базе данных
            _buildDatabaseInfo(context),

            const SizedBox(height: 16),

            // Кнопки действий
            if (isAutoOpening)
              _buildAutoOpeningIndicator(context)
            else
              _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDatabaseInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Название базы данных
        Row(
          children: [
            Icon(Icons.storage, color: colorScheme.onSurfaceVariant, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                database.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (database.saveMasterPassword)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.key, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Пароль сохранен',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 8),

        // Описание (если есть)
        if (database.description?.isNotEmpty == true) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.description_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  database.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Путь к файлу
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.folder_outlined,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                database.path,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Дата последнего доступа
        Row(
          children: [
            Icon(
              Icons.access_time,
              color: colorScheme.onSurfaceVariant,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              _formatLastAccess(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final canAutoOpen =
        database.saveMasterPassword &&
        database.masterPassword?.isNotEmpty == true;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Кнопка автоматического открытия (если пароль сохранен)
        if (canAutoOpen)
          SmoothButton(
            type: SmoothButtonType.filled,
            isFullWidth: true,
            onPressed: isLoading ? null : onOpenAuto,
            label: 'Открыть',
            icon: const Icon(Icons.lock_open, size: 18),
            loading: isLoading,
          ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SmoothButton(
              onPressed: isLoading ? null : onOpenManual,
              type: canAutoOpen
                  ? SmoothButtonType.outlined
                  : SmoothButtonType.filled,
              label: canAutoOpen ? 'Другой пароль' : 'Открыть',
              icon: Icon(canAutoOpen ? Icons.key : Icons.lock_open, size: 18),
            ),

            // Кнопка удаления из истории
            IconButton(
              onPressed: isLoading ? null : onRemove,
              icon: const Icon(Icons.delete, size: 20),
              tooltip: 'Удалить из истории',
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),

        // Кнопка ручного открытия
      ],
    );
  }

  Widget _buildAutoOpeningIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Автоматическое открытие базы данных...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastAccess() {
    final date = database.lastAccessed ?? database.createdAt;
    if (date == null) return 'Дата неизвестна';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Только что';
        }
        return '${difference.inMinutes} мин назад';
      }
      return '${difference.inHours} ч назад';
    } else if (difference.inDays == 1) {
      return 'Вчера в ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return _formatDateTime(date);
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${_formatTime(date)}';
  }
}
