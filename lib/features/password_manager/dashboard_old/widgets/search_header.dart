import 'package:flutter/material.dart';
import '../../../../common/text_field.dart';

class SearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onDrawerPressed;
  final VoidCallback onFilterPressed;

  const SearchHeader({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    required this.onDrawerPressed,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Search Field
          Expanded(
            // child: PrimaryTextField(
            //   controller: controller,
            //   onChanged: onSearchChanged,
            //   hintText: 'Поиск паролей...',
            //   prefixIcon: Icon(
            //     Icons.search,
            //     color: theme.colorScheme.onSurface.withOpacity(0.6),
            //   ),
            // ),
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              decoration:
                  primaryInputDecoration(
                    context,
                    hintText: 'Поиск паролей...',
                  ).copyWith(
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter Button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: onFilterPressed,
              icon: Icon(
                Icons.tune,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              tooltip: 'Фильтры',
            ),
          ),
          const SizedBox(width: 8),
          // Drawer Button
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: onDrawerPressed,
              icon: Icon(
                Icons.menu,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              tooltip: 'Меню',
            ),
          ),
        ],
      ),
    );
  }
}
