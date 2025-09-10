import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'icon_picker_modal.dart';

/// Универсальная кнопка для выбора иконки
///
/// Примечание: Все вызовы setState() в связанных компонентах (IconPickerModal, примеры)
/// были обернуты в SchedulerBinding.instance.addPostFrameCallback() или используют
/// дебаунсинг для предотвращения ошибки "Build scheduled during frame".
class IconPickerButton extends StatelessWidget {
  /// ID выбранной иконки
  final String? selectedIconId;

  /// Данные выбранной иконки для отображения превью
  final store.IconData? selectedIcon;

  /// Callback при выборе иконки
  final ValueChanged<String> onIconSelected;

  /// Callback при отмене выбора иконки
  final VoidCallback? onIconCleared;

  /// Размер кнопки
  final double? size;

  /// Подпись под кнопкой
  final String? label;

  /// Показывать ли кнопку очистки
  final bool showClearButton;

  /// Форма кнопки
  final IconPickerButtonShape shape;

  /// Текст для пустого состояния
  final String emptyText;

  /// Включена ли кнопка
  final bool enabled;

  const IconPickerButton({
    super.key,
    this.selectedIconId,
    this.selectedIcon,
    required this.onIconSelected,
    this.onIconCleared,
    this.size,
    this.label,
    this.showClearButton = true,
    this.shape = IconPickerButtonShape.square,
    this.emptyText = 'Выбрать иконку',
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonSize = size ?? _getDefaultSize(context);
    final hasIcon = selectedIcon != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Основная кнопка
        Stack(
          children: [
            _buildMainButton(context, buttonSize, hasIcon),

            // Кнопка очистки (показывается только при наличии выбранной иконки)
            if (hasIcon && showClearButton && enabled)
              Positioned(top: -4, right: -4, child: _buildClearButton(context)),
          ],
        ),

        // Подпись
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildMainButton(
    BuildContext context,
    double buttonSize,
    bool hasIcon,
  ) {
    final borderRadius = _getBorderRadius();

    return Material(
      color: hasIcon
          ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)
          : Theme.of(context).colorScheme.surface,
      borderRadius: borderRadius,
      elevation: hasIcon ? 1 : 0,
      child: InkWell(
        onTap: enabled ? () => _openIconPicker(context) : null,
        borderRadius: borderRadius,
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: hasIcon
                  ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.5),
              width: hasIcon ? 1 : 2,
              style: hasIcon ? BorderStyle.solid : BorderStyle.none,
            ),
          ),
          child: hasIcon
              ? _buildIconPreview(context, buttonSize)
              : _buildEmptyState(context, buttonSize),
        ),
      ),
    );
  }

  Widget _buildIconPreview(BuildContext context, double buttonSize) {
    if (selectedIcon == null) return const SizedBox.shrink();

    final iconSize = buttonSize * 0.7;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: _getBorderRadius(reduced: true),
        child: _buildIconWidget(iconSize),
      ),
    );
  }

  Widget _buildIconWidget(double iconSize) {
    try {
      if (selectedIcon!.type == IconType.svg) {
        return SvgPicture.memory(
          selectedIcon!.data,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
        );
      } else {
        return Image.memory(
          selectedIcon!.data,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorIcon(iconSize),
        );
      }
    } catch (e) {
      return _buildErrorIcon(iconSize);
    }
  }

  Widget _buildErrorIcon(double iconSize) {
    return Icon(Icons.broken_image, size: iconSize * 0.6, color: Colors.grey);
  }

  Widget _buildEmptyState(BuildContext context, double buttonSize) {
    final iconSize = buttonSize * 0.4;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: iconSize,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
        ),
        const SizedBox(height: 4),
        Text(
          emptyText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildClearButton(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.error,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onIconCleared,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onError,
              width: 1,
            ),
          ),
          child: Icon(
            Icons.close,
            size: 16,
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius({bool reduced = false}) {
    switch (shape) {
      case IconPickerButtonShape.square:
        return BorderRadius.circular(reduced ? 4 : 8);
      case IconPickerButtonShape.rounded:
        return BorderRadius.circular(reduced ? 8 : 16);
      case IconPickerButtonShape.circle:
        return BorderRadius.circular(1000); // Максимальное скругление
    }
  }

  double _getDefaultSize(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);
    if (breakpoints.isMobile) return 80;
    if (breakpoints.isTablet) return 100;
    return 120;
  }

  void _openIconPicker(BuildContext context) {
    final breakpoints = ResponsiveBreakpoints.of(context);

    if (breakpoints.isMobile) {
      // Показываем bottom sheet на мобильных
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => IconPickerModal(
          selectedIconId: selectedIconId,
          onIconSelected: (iconId, iconData) {
            onIconSelected(iconId);
            Navigator.of(context).pop();
          },
          isBottomSheet: true,
        ),
      );
    } else {
      // Показываем диалог на планшетах и десктопе
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: breakpoints.isTablet ? 600 : 800,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: IconPickerModal(
              selectedIconId: selectedIconId,
              onIconSelected: (iconId, iconData) {
                onIconSelected(iconId);
                Navigator.of(context).pop();
              },
              isBottomSheet: false,
            ),
          ),
        ),
      );
    }
  }
}

/// Форма кнопки выбора иконки
enum IconPickerButtonShape { square, rounded, circle }
