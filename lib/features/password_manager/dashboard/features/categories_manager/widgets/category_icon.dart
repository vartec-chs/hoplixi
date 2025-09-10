import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';
import 'package:hoplixi/hoplixi_store/services_providers.dart';

/// Виджет для отображения иконки категории
///
/// Если у категории есть иконка из БД, отображает её.
/// Если нет - отображает иконку по умолчанию для типа категории.
class CategoryIcon extends StatelessWidget {
  final store.Category? category;
  final CategoryType? categoryType;
  final store.IconData? iconData;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final Color? borderColor;
  final EdgeInsets? padding;

  const CategoryIcon({
    super.key,
    this.category,
    this.categoryType,
    this.iconData,
    this.size = 24,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.showBorder = false,
    this.borderColor,
    this.padding,
  }) : assert(
         category != null || categoryType != null || iconData != null,
         'Должна быть предоставлена category, categoryType или iconData',
       );

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size;
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(6);
    final effectivePadding = padding ?? EdgeInsets.all(effectiveSize * 0.15);

    return Container(
      width: effectiveSize,
      height: effectiveSize,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: effectiveBorderRadius,
        border: showBorder
            ? Border.all(
                color:
                    borderColor ??
                    Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: _buildIconWidget(context),
      ),
    );
  }

  Widget _buildIconWidget(BuildContext context) {
    // Если передана иконка из БД напрямую
    if (iconData != null) {
      return _buildDatabaseIcon(context, iconData!);
    }

    // Если передана категория с иконкой
    if (category?.iconId != null) {
      // Здесь нужно получить иконку из БД по iconId
      // Пока возвращаем placeholder, так как нужен доступ к DAO
      return _buildPlaceholderIcon(context);
    }

    // Возвращаем иконку по умолчанию для типа
    final type = category?.type ?? categoryType;
    if (type != null) {
      return _buildDefaultIcon(context, type);
    }

    // Fallback иконка
    return _buildDefaultIcon(context, CategoryType.mixed);
  }

  Widget _buildDatabaseIcon(BuildContext context, store.IconData iconData) {
    try {
      final iconSize = size - (padding?.horizontal ?? size * 0.3);

      if (iconData.type == IconType.svg) {
        return SvgPicture.memory(
          iconData.data,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          colorFilter: color != null
              ? ColorFilter.mode(color!, BlendMode.srcIn)
              : null,
          placeholderBuilder: (context) => _buildLoadingIcon(context),
        );
      } else {
        return Image.memory(
          iconData.data,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          color: color,
          colorBlendMode: color != null ? BlendMode.srcIn : null,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorIcon(context),
        );
      }
    } catch (e) {
      return _buildErrorIcon(context);
    }
  }

  Widget _buildDefaultIcon(BuildContext context, CategoryType type) {
    return Icon(
      _getCategoryTypeIcon(type),
      size: size - (padding?.horizontal ?? size * 0.3),
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return Icon(
      Icons.image_outlined,
      size: size - (padding?.horizontal ?? size * 0.3),
      color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
    );
  }

  Widget _buildLoadingIcon(BuildContext context) {
    return Container(
      width: size - (padding?.horizontal ?? size * 0.3),
      height: size - (padding?.horizontal ?? size * 0.3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: Center(
        child: SizedBox(
          width: (size - (padding?.horizontal ?? size * 0.3)) * 0.5,
          height: (size - (padding?.horizontal ?? size * 0.3)) * 0.5,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIcon(BuildContext context) {
    return Icon(
      Icons.broken_image_outlined,
      size: size - (padding?.horizontal ?? size * 0.3),
      color: color ?? Theme.of(context).colorScheme.error.withOpacity(0.7),
    );
  }

  IconData _getCategoryTypeIcon(CategoryType type) {
    switch (type) {
      case CategoryType.password:
        return Icons.lock_outlined;
      case CategoryType.notes:
        return Icons.note_outlined;
      case CategoryType.totp:
        return Icons.security_outlined;
      case CategoryType.mixed:
        return Icons.folder_outlined;
    }
  }
}

/// Виджет для отображения иконки категории с получением данных из БД
///
/// Автоматически загружает иконку из базы данных, если она есть
class CategoryIconWithData extends ConsumerWidget {
  final store.Category category;
  final double size;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final bool showBorder;
  final Color? borderColor;
  final EdgeInsets? padding;

  const CategoryIconWithData({
    super.key,
    required this.category,
    this.size = 24,
    this.color,
    this.backgroundColor,
    this.borderRadius,
    this.showBorder = false,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Если у категории нет иконки, возвращаем обычную иконку
    if (category.iconId == null) {
      return CategoryIcon(
        category: category,
        size: size,
        color: color,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        showBorder: showBorder,
        borderColor: borderColor,
        padding: padding,
      );
    }

    // Загружаем иконку из БД
    final iconAsyncValue = ref.watch(iconByIdProvider(category.iconId!));

    return iconAsyncValue.when(
      data: (iconData) {
        if (iconData != null) {
          return CategoryIcon(
            iconData: iconData,
            size: size,
            color: color,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius,
            showBorder: showBorder,
            borderColor: borderColor,
            padding: padding,
          );
        } else {
          // Иконка не найдена, показываем fallback
          return CategoryIcon(
            category: category,
            size: size,
            color: color,
            backgroundColor: backgroundColor,
            borderRadius: borderRadius,
            showBorder: showBorder,
            borderColor: borderColor,
            padding: padding,
          );
        }
      },
      loading: () => CategoryIcon(
        categoryType: category.type,
        size: size,
        color:
            color?.withOpacity(0.5) ??
            Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        showBorder: showBorder,
        borderColor: borderColor,
        padding: padding,
      ),
      error: (error, stack) => CategoryIcon(
        category: category,
        size: size,
        color: color,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        showBorder: showBorder,
        borderColor: borderColor,
        padding: padding,
      ),
    );
  }
}
