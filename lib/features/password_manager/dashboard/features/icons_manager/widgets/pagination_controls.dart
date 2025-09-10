import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'dart:math' as math;

/// Виджет управления пагинацией
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final int maxVisiblePages;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
    this.maxVisiblePages = 5,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    if (isMobile) {
      return _buildMobilePagination(context);
    } else {
      return _buildDesktopPagination(context);
    }
  }

  Widget _buildMobilePagination(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Предыдущая страница
        IconButton(
          onPressed: currentPage > 1
              ? () => onPageChanged(currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Предыдущая страница',
        ),

        // Информация о текущей странице
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$currentPage из $totalPages',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),

        // Следующая страница
        IconButton(
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Следующая страница',
        ),
      ],
    );
  }

  Widget _buildDesktopPagination(BuildContext context) {
    final visiblePages = _getVisiblePages();

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        // Первая страница
        if (visiblePages.first > 1) ...[
          _PageButton(
            page: 1,
            isActive: currentPage == 1,
            onPressed: () => onPageChanged(1),
          ),
          if (visiblePages.first > 2) _buildEllipsis(context),
        ],

        // Видимые страницы
        ...visiblePages.map(
          (page) => _PageButton(
            page: page,
            isActive: currentPage == page,
            onPressed: () => onPageChanged(page),
          ),
        ),

        // Последняя страница
        if (visiblePages.last < totalPages) ...[
          if (visiblePages.last < totalPages - 1) _buildEllipsis(context),
          _PageButton(
            page: totalPages,
            isActive: currentPage == totalPages,
            onPressed: () => onPageChanged(totalPages),
          ),
        ],
      ],
    );
  }

  Widget _buildEllipsis(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '...',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  List<int> _getVisiblePages() {
    final int halfVisible = maxVisiblePages ~/ 2;
    int startPage = math.max(1, currentPage - halfVisible);
    int endPage = math.min(totalPages, startPage + maxVisiblePages - 1);

    // Корректируем начальную страницу, если не хватает страниц в конце
    if (endPage - startPage + 1 < maxVisiblePages) {
      startPage = math.max(1, endPage - maxVisiblePages + 1);
    }

    return List.generate(endPage - startPage + 1, (index) => startPage + index);
  }
}

class _PageButton extends StatelessWidget {
  final int page;
  final bool isActive;
  final VoidCallback onPressed;

  const _PageButton({
    required this.page,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: isActive
          ? FilledButton(
              onPressed: null,
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                '$page',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
    );
  }
}
