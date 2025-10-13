import 'package:flutter/material.dart';
import 'package:hoplixi/core/utils/parse_hex_color.dart';

class TagChip extends StatelessWidget {
  final String name;
  final String? colorHex;

  const TagChip({super.key, required this.name, this.colorHex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = parseHexColor(colorHex, theme.colorScheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(0x1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.tag, size: 16, color: baseColor),
          const SizedBox(width: 4),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String name;
  final String? colorHex;

  const CategoryChip({super.key, required this.name, this.colorHex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = parseHexColor(colorHex, theme.colorScheme.primary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withAlpha(0x1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder, size: 16, color: baseColor),
          const SizedBox(width: 4),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
