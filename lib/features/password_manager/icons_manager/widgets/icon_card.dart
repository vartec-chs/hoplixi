import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Карточка для отображения иконки в списке или сетке
class IconCard extends StatelessWidget {
  final store.IconData icon;
  final bool isListView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const IconCard({
    super.key,
    required this.icon,
    this.isListView = false,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isListView) {
      return _buildListTile(context);
    } else {
      return _buildGridCard(context);
    }
  }

  Widget _buildListTile(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildIconImage(context, size: 48),
        title: Text(
          icon.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _buildTypeChip(context),
            const SizedBox(height: 4),
            Text(
              _formatFileSize(icon.data.length),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: _buildActionButtons(context),
        onTap: onTap,
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    final isMobile = breakpoints.isMobile;
    final isTablet = breakpoints.isTablet;
    final isDesktop = breakpoints.isDesktop;

    // Определяем размер иконки в зависимости от экрана
    double iconSize;
    if (isMobile) {
      iconSize = 48;
    } else if (isTablet) {
      iconSize = 64;
    } else {
      iconSize = 80;
    }

    // Определяем тип отображения кнопок действий
    final showCompactButtons = isDesktop;
    final showBottomActionBar = isMobile;
    final showPopupMenu = isTablet;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Превью иконки
            Expanded(
              flex: showBottomActionBar ? 3 : 2,
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                ),
                child: Center(child: _buildIconImage(context, size: iconSize)),
              ),
            ),

            // Информация об иконке
            Expanded(
              flex: showBottomActionBar ? 2 : 3,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 8 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название
                    Text(
                      icon.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: isMobile ? 12 : null,
                      ),
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 2 : 4),

                    // Тип и размер
                    Row(
                      children: [
                        Expanded(child: _buildTypeChip(context, compact: true)),
                      ],
                    ),
                    SizedBox(height: isMobile ? 2 : 4),

                    Text(
                      _formatFileSize(icon.data.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: isMobile ? 10 : null,
                      ),
                    ),

                    const Spacer(),

                    // Кнопки действий для десктопа
                    if (showCompactButtons)
                      _buildActionButtons(context, compact: true),

                    // Popup меню для планшета
                    if (showPopupMenu)
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildActionButtons(context),
                      ),
                  ],
                ),
              ),
            ),

            // Мобильные кнопки действий внизу
            if (showBottomActionBar) _buildMobileActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIconImage(BuildContext context, {required double size}) {
    try {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImageWidget(size),
        ),
      );
    } catch (e) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.broken_image,
          size: size * 0.5,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      );
    }
  }

  Widget _buildImageWidget(double size) {
    // Проверяем тип иконки для выбора правильного виджета рендеринга
    if (icon.type == IconType.svg) {
      return SvgPicture.memory(
        icon.data,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              Icons.image,
              size: size * 0.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else {
      return Image.memory(
        icon.data,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.broken_image,
              size: size * 0.5,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          );
        },
      );
    }
  }

  Widget _buildTypeChip(BuildContext context, {bool compact = false}) {
    final color = _getTypeColor(context, icon.type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        icon.type.name.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, {bool compact = false}) {
    final breakpoints = ResponsiveBreakpoints.of(context);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              iconSize: breakpoints.isMobile ? 16 : 18,
              constraints: BoxConstraints(
                minWidth: breakpoints.isMobile ? 28 : 32,
                minHeight: breakpoints.isMobile ? 28 : 32,
              ),
              padding: EdgeInsets.zero,
              tooltip: 'Редактировать',
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete),
              iconSize: breakpoints.isMobile ? 16 : 18,
              constraints: BoxConstraints(
                minWidth: breakpoints.isMobile ? 28 : 32,
                minHeight: breakpoints.isMobile ? 28 : 32,
              ),
              padding: EdgeInsets.zero,
              tooltip: 'Удалить',
              color: Theme.of(context).colorScheme.error,
            ),
        ],
      );
    }

    return PopupMenuButton<String>(
      iconSize: breakpoints.isTablet ? 20 : 24,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: breakpoints.isTablet ? 32 : 40,
        minHeight: breakpoints.isTablet ? 32 : 40,
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('Редактировать'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading: Icon(
                Icons.delete,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Удалить',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildMobileActionBar(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    final isMobile = breakpoints.isMobile;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 4 : 8,
        vertical: isMobile ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (onEdit != null)
            Expanded(
              child: TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(
                  isMobile ? 'Изменить' : 'Редактировать',
                  style: TextStyle(fontSize: isMobile ? 11 : 12),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 4 : 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          if (onEdit != null && onDelete != null)
            SizedBox(width: isMobile ? 4 : 8),
          if (onDelete != null)
            Expanded(
              child: TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 16),
                label: Text(
                  'Удалить',
                  style: TextStyle(fontSize: isMobile ? 11 : 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 4 : 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getTypeColor(BuildContext context, IconType type) {
    switch (type) {
      case IconType.png:
        return Colors.blue;
      case IconType.jpg:
        return Colors.orange;
      case IconType.svg:
        return Colors.green;
      case IconType.gif:
        return Colors.purple;
      case IconType.bmp:
        return Colors.red;
      case IconType.webp:
        return Colors.teal;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
}
