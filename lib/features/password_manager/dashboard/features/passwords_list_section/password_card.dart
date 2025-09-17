import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/password_manager/dashboard/features/passwords_list_section/passwords_list_controller.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers.dart';

/// Улучшенная версия карточки пароля.
/// Сохранён дизайн, исправлены ошибки и повышена читаемость/доступность.

Color parseHexColor(String? hexColor, Color fallbackColor) {
  if (hexColor == null || hexColor.trim().isEmpty) return fallbackColor;

  try {
    var clean = hexColor.trim().replaceAll('#', '').replaceAll('0x', '');
    logDebug('Парсинг hex цвета', data: {'hex': clean});

    // Если передан RRGGBB — добавляем альфу FF
    if (clean.length == 6) clean = 'FF$clean';

    if (clean.length != 8) {
      logError('Неподдерживаемая длина hex строки', data: {'hex': clean});
      return fallbackColor;
    }

    final value = int.tryParse(clean, radix: 16);
    if (value == null) throw FormatException('Не шестнадцатеричный формат');

    return Color(value);
  } catch (e, s) {
    logError('Не удалось распарсить hex цвет', error: e, stackTrace: s);
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
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;

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

  Future<void> _copyToClipboard(Future<String> textFn, String label) async {
    try {
      if (!mounted) return;
      final text = await textFn;
      if (text.isEmpty) {
        return ToastHelper.info(title: 'Пусто', description: label);
      }
      await Clipboard.setData(ClipboardData(text: text));
      ToastHelper.success(title: 'Копирование в буфер', description: label);
    } catch (e, s) {
      logError('Ошибка копирования в буфер', error: e, stackTrace: s);
      if (!mounted) return;
      ToastHelper.error(title: 'Ошибка копирования', description: e.toString());
    }
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Card Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with category chips and favorite
                    Row(
                      children: [
                        // Categories — используем Wrap чтобы корректно переносить при нехватке места
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: (widget.password.categories ?? [])
                                .map<Widget>(
                                  (category) => _CategoryChip(
                                    name: category.name,
                                    colorHex: category.color,
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Favorite Button — IconButton потребляет событие, родитель не раскроется при нажатии
                        IconButton(
                          onPressed: widget.onFavoriteToggle,
                          icon: Icon(
                            widget.password.isFavorite
                                ? Icons.star
                                : Icons.star_border,
                            size: 20,
                          ),
                          color: widget.password.isFavorite
                              ? Colors.amber
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                          tooltip: widget.password.isFavorite
                              ? 'Убрано из избранного'
                              : 'В избранное',
                          splashRadius: 20,
                        ),
                        Visibility(
                          visible: widget.password.isFrequentlyUsed,
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              Icon(
                                // Whatshot
                                Icons.whatshot,
                                size: 20,
                                color: Colors.red.withOpacity(0.8),
                              ),
                            ],
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

                    if (widget.password.description != null &&
                        widget.password.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.password.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    if (widget.password.tags != null &&
                        widget.password.tags!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: (widget.password.tags ?? [])
                            .map<Widget>(
                              (tag) =>
                                  _TagChip(name: tag.name, colorHex: tag.color),
                            )
                            .toList(),
                      ),
                    ],

                    // Login
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.password.login ??
                                widget.password.email ??
                                '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.8,
                              ),
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
                  child: Consumer(
                    builder: (context, ref, child) {
                      return Column(
                        children: [
                          // Action Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.link,
                                  label: 'URL',
                                  onPressed: () => _copyToClipboard(
                                    // предполагаем что в DTO есть поле url
                                    ref
                                        .read(
                                          passwordsListControllerProvider
                                              .notifier,
                                        )
                                        .getUrlById(widget.password.id),
                                    'URL',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.person,
                                  label: 'Логин',
                                  onPressed: () => _copyToClipboard(
                                    ref
                                        .read(
                                          passwordsListControllerProvider
                                              .notifier,
                                        )
                                        .getLoginById(widget.password.id),
                                    'Логин',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _ActionButton(
                                  icon: Icons.key,
                                  label: 'Пароль',
                                  onPressed: () => _copyToClipboard(
                                    // предполагаем что в DTO есть поле password
                                    ref
                                        .read(
                                          passwordsListControllerProvider
                                              .notifier,
                                        )
                                        .getPasswordById(widget.password.id),

                                    'Пароль',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Edit Button
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: widget.onEdit,
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
                      );
                    },
                  ),
                ),
              ),
            ],
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

class _CategoryChip extends StatelessWidget {
  final String name;
  final String? colorHex;

  const _CategoryChip({required this.name, this.colorHex});

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

class _TagChip extends StatelessWidget {
  final String name;
  final String? colorHex;

  const _TagChip({required this.name, this.colorHex});

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
