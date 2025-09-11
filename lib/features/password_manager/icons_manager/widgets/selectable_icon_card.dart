import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Простая карточка иконки для выбора (без кнопок действий)
class SelectableIconCard extends StatelessWidget {
  final store.IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final double? size;

  const SelectableIconCard({
    super.key,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cardSize = size ?? 80.0;
    final theme = Theme.of(context);

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: cardSize,
          height: cardSize,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Иконка
              Expanded(
                flex: 3,
                child: Center(child: _buildIconWidget(context, cardSize * 0.5)),
              ),

              const SizedBox(height: 4),

              // Название (сокращенное)
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    icon.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconWidget(BuildContext context, double iconSize) {
    try {
      Widget iconWidget;

      if (icon.type == IconType.svg) {
        iconWidget = SvgPicture.memory(
          icon.data,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => _buildPlaceholder(context, iconSize),
        );
      } else {
        iconWidget = Image.memory(
          icon.data,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorIcon(context, iconSize),
        );
      }

      return Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: iconWidget,
        ),
      );
    } catch (e) {
      return _buildErrorIcon(context, iconSize);
    }
  }

  Widget _buildPlaceholder(BuildContext context, double iconSize) {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: iconSize * 0.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildErrorIcon(BuildContext context, double iconSize) {
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: iconSize * 0.4,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
