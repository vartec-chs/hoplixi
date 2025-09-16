import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';

Color parseHexColor(String? hexColor, Color fallbackColor) {
  if (hexColor == null || hexColor.isEmpty) return fallbackColor;

  try {
    // Убираем # если есть
    final cleanHex = hexColor.replaceAll('#', '');
    logDebug('Парсинг hex цвета', data: {'hex': cleanHex});

    // Если в строке только RRGGBB, добавляем FF для полной непрозрачности
    final hexValue = cleanHex.length == 6
        ? 'FF$cleanHex'
        : cleanHex; // поддержка AARRGGBB тоже

    return Color(int.parse(hexValue, radix: 16));
  } catch (e) {
    logError('Не удалось распарсить hex цвет', error: e);
    return fallbackColor;
  }
}

class PasswordCard extends StatefulWidget {
  final CardPasswordDto password;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PasswordCard({
    super.key,
    required this.password,
    required this.onFavoriteToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label скопирован в буфер обмена'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main Card Content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with category and favorite
                        Row(
                          children: [
                            Column(
                              children: (widget.password.categories ?? [])
                                  .map(
                                    (category) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: parseHexColor(
                                          category.color,
                                          theme.colorScheme.primary,
                                        ).withAlpha(0x1A),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        category.name,
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: parseHexColor(
                                                category.color,
                                                theme.colorScheme.primary,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),

                            // Category Chip
                            const Spacer(),
                            // Favorite Button
                            GestureDetector(
                              onTap: () => widget.onFavoriteToggle(),
                              child: Icon(
                                widget.password.isFavorite
                                    ? Icons.star
                                    : Icons.star_border,
                                color: widget.password.isFavorite
                                    ? Colors.amber
                                    : theme.colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          widget.password.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Description
                        Text(
                          widget.password.description ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Login
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.password.login ??
                                    widget.password.email ??
                                    '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expanded Content
                  SizeTransition(
                    sizeFactor: _expandAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Action Buttons Row
                          Row(
                            children: [
                              // Copy URL Button
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.link,
                                  label: 'URL',
                                  onPressed: () => _copyToClipboard("", 'URL'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Copy Login Button
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.person,
                                  label: 'Логин',
                                  onPressed: () => _copyToClipboard(
                                    widget.password.login ??
                                        widget.password.email ??
                                        '',
                                    'Логин',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Copy Password Button
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.key,
                                  label: 'Пароль',
                                  onPressed: () =>
                                      _copyToClipboard("", 'Пароль'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Edit Button
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => widget.onEdit(),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Редактировать'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        // backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
