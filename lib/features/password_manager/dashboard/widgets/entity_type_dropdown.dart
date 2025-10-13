import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/shared/widgets/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

import '../models/entety_type.dart';
import '../providers/filter_providers/entety_type_provider.dart';

/// Выпадающий список для выбора типа сущности
/// Интегрируется с entityTypeControllerProvider для управления состоянием
class EntityTypeDropdown extends ConsumerWidget {
  /// Callback при изменении типа сущности
  final ValueChanged<EntityType>? onEntityTypeChanged;

  /// Декорация для DropdownButtonFormField
  final InputDecoration? decoration;

  /// Стиль текста для выбранного значения
  final TextStyle? selectedItemStyle;

  /// Стиль текста для элементов списка
  final TextStyle? itemStyle;

  /// Иконка для раскрытия списка
  final Widget? icon;

  /// Цвет иконки
  final Color? iconColor;

  /// Включен ли dropdown
  final bool enabled;

  /// Фокус нод для dropdown
  final FocusNode? focusNode;

  /// Автофокус
  final bool autofocus;

  /// Подсказка при отсутствии выбранного значения
  final String? hint;

  /// Стиль подсказки
  final TextStyle? hintStyle;

  /// Ширина выпадающего меню
  final double? menuWidth;

  /// Максимальная высота выпадающего меню
  final double? menuMaxHeight;

  /// Выравнивание элементов в меню
  final AlignmentGeometry alignment;

  /// Отступы выпадающего меню
  final EdgeInsetsGeometry? menuPadding;

  const EntityTypeDropdown({
    super.key,
    this.onEntityTypeChanged,
    this.decoration,
    this.selectedItemStyle,
    this.itemStyle,
    this.icon,
    this.iconColor,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.hint,
    this.hintStyle,
    this.menuWidth,
    this.menuMaxHeight,
    this.alignment = AlignmentDirectional.centerStart,
    this.menuPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEntityType = ref.watch(currentEntityTypeProvider);
    final availableTypes = ref.watch(availableEntityTypesProvider);

    // Если нет доступных типов, показываем disabled dropdown
    if (availableTypes.isEmpty) {
      return DropdownButtonFormField<EntityType>(
        initialValue: null,
        items: const [],
        onChanged: null,
        decoration: (decoration ?? const InputDecoration()).copyWith(
          labelText: 'Типы сущностей недоступны',
          enabled: false,
        ),
      );
    }

    // Если текущий тип недоступен, автоматически переключаемся на первый доступный
    if (!availableTypes.contains(currentEntityType)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (availableTypes.isNotEmpty) {
          ref
              .read(entityTypeControllerProvider.notifier)
              .changeEntityType(availableTypes.first);
        }
      });
    }

    return DropdownButtonFormField<EntityType>(
      initialValue: availableTypes.contains(currentEntityType)
          ? currentEntityType
          : null,
      items: availableTypes.map((entityType) {
        return DropdownMenuItem<EntityType>(
          value: entityType,
          child: Row(
            children: [
              Icon(
                _getEntityTypeIcon(entityType),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                entityType.label,
                style: itemStyle ?? Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled
          ? (EntityType? newType) {
              if (newType != null) {
                logInfo(
                  'Изменение типа сущности через dropdown',
                  data: {
                    'oldType': currentEntityType.id,
                    'newType': newType.id,
                  },
                );

                ref
                    .read(entityTypeControllerProvider.notifier)
                    .changeEntityType(newType);

                onEntityTypeChanged?.call(newType);
              }
            }
          : null,
      decoration:
          decoration ??
          primaryInputDecoration(
            context,
            labelText: 'Тип сущности',
            hintText: hint ?? 'Выберите тип',
          ),
      style: selectedItemStyle ?? Theme.of(context).textTheme.bodyLarge,
      icon: icon ?? const Icon(Icons.arrow_drop_down),
      iconEnabledColor: iconColor,
      focusNode: focusNode,
      autofocus: autofocus,
      isExpanded: true,
      menuMaxHeight: menuMaxHeight,
      alignment: alignment,
      padding: menuPadding,
    );
  }

  /// Возвращает иконку для типа сущности
  IconData _getEntityTypeIcon(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return Icons.lock;
      case EntityType.note:
        return Icons.note;
      case EntityType.otp:
        return Icons.security;
    }
  }
}

/// Компактная версия EntityTypeDropdown для использования в AppBar или тулбарах
class EntityTypeCompactDropdown extends ConsumerWidget {
  /// Callback при изменении типа сущности
  final ValueChanged<EntityType>? onEntityTypeChanged;

  /// Цвет текста
  final Color? textColor;

  /// Цвет иконки
  final Color? iconColor;

  /// Размер иконки
  final double iconSize;

  /// Стиль текста
  final TextStyle? textStyle;

  const EntityTypeCompactDropdown({
    super.key,
    this.onEntityTypeChanged,
    this.textColor,
    this.iconColor,
    this.iconSize = 20,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEntityType = ref.watch(currentEntityTypeProvider);
    final availableTypes = ref.watch(availableEntityTypesProvider);

    if (availableTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<EntityType>(
      padding: EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(16),
      splashRadius: 16,
      menuPadding: EdgeInsets.all(0),
      enableFeedback: true,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      style: ButtonStyle(
        textStyle: WidgetStateProperty.all(
          textStyle ?? Theme.of(context).textTheme.bodyLarge,
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      tooltip: 'Выберите тип сущности',
      onSelected: (EntityType newType) {
        logInfo(
          'Изменение типа сущности через compact dropdown',
          data: {'oldType': currentEntityType.id, 'newType': newType.id},
        );

        ref
            .read(entityTypeControllerProvider.notifier)
            .changeEntityType(newType);

        onEntityTypeChanged?.call(newType);
      },
      itemBuilder: (BuildContext context) {
        return availableTypes.map((entityType) {
          return PopupMenuItem<EntityType>(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            value: entityType,

            child: Row(
              children: [
                Icon(
                  _getEntityTypeIcon(entityType),
                  size: iconSize,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  entityType.label,
                  style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getEntityTypeIcon(currentEntityType),
            size: iconSize,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            currentEntityType.label,
            style: (textStyle ?? Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(color: textColor),
          ),
          Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: iconColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  /// Возвращает иконку для типа сущности
  IconData _getEntityTypeIcon(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return Icons.lock;
      case EntityType.note:
        return Icons.note;
      case EntityType.otp:
        return Icons.security;
    }
  }
}

/// Виджет-чип для выбора типа сущности
/// Полезен для компактного отображения с возможностью быстрого переключения
class EntityTypeChips extends ConsumerWidget {
  /// Callback при изменении типа сущности
  final ValueChanged<EntityType>? onEntityTypeChanged;

  /// Показывать иконки в чипах
  final bool showIcons;

  /// Размер иконок
  final double iconSize;

  /// Стиль текста
  final TextStyle? textStyle;

  /// Цвет выбранного чипа
  final Color? selectedColor;

  /// Цвет невыбранных чипов
  final Color? unselectedColor;

  const EntityTypeChips({
    super.key,
    this.onEntityTypeChanged,
    this.showIcons = true,
    this.iconSize = 18,
    this.textStyle,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEntityType = ref.watch(currentEntityTypeProvider);
    final availableTypes = ref.watch(availableEntityTypesProvider);

    if (availableTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      children: availableTypes.map((entityType) {
        final isSelected = entityType == currentEntityType;

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showIcons) ...[
                Icon(
                  _getEntityTypeIcon(entityType),
                  size: iconSize,
                  color: isSelected
                      ? (selectedColor ??
                            Theme.of(context).colorScheme.onPrimary)
                      : (unselectedColor ??
                            Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                entityType.label,
                style: (textStyle ?? Theme.of(context).textTheme.bodyMedium)
                    ?.copyWith(
                      color: isSelected
                          ? (selectedColor ??
                                Theme.of(context).colorScheme.onPrimary)
                          : (unselectedColor ??
                                Theme.of(context).colorScheme.onSurface),
                    ),
              ),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              logInfo(
                'Изменение типа сущности через chips',
                data: {
                  'oldType': currentEntityType.id,
                  'newType': entityType.id,
                },
              );

              ref
                  .read(entityTypeControllerProvider.notifier)
                  .changeEntityType(entityType);

              onEntityTypeChanged?.call(entityType);
            }
          },
          selectedColor: selectedColor ?? Theme.of(context).colorScheme.primary,
          backgroundColor:
              unselectedColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          checkmarkColor:
              selectedColor ?? Theme.of(context).colorScheme.onPrimary,
        );
      }).toList(),
    );
  }

  /// Возвращает иконку для типа сущности
  IconData _getEntityTypeIcon(EntityType entityType) {
    switch (entityType) {
      case EntityType.password:
        return Icons.lock;
      case EntityType.note:
        return Icons.note;
      case EntityType.otp:
        return Icons.security;
    }
  }
}
