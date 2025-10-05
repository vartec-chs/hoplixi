import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/utils/parse_hex_color.dart';
import 'package:hoplixi/hoplixi_store/dto/db_dto.dart';
import 'package:hoplixi/hoplixi_store/providers/service_providers.dart';

class NoteCard extends ConsumerStatefulWidget {
  final CardNoteDto note;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onPinToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onFavoriteToggle,
    required this.onPinToggle,
    required this.onEdit,
    required this.onDelete,
    this.onLongPress,
  });

  @override
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late final AnimationController _animationController;
  late final Animation<double> _expandAnimation;
  String? _fullContent;

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
    _fullContent = widget.note.content;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() async {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
        // Загружаем полный content если preview короткий
        if (_fullContent == null || _fullContent!.length < 200) {
          _loadFullContent();
        }
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _loadFullContent() async {
    try {
      final result = await ref
          .read(notesServiceProvider)
          .getNoteContentById(widget.note.id);
      if (result.success && result.data != null && mounted) {
        setState(() {
          _fullContent = result.data!;
        });
      }
    } catch (e, s) {
      logError(
        'Ошибка загрузки полного содержимого заметки',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _copyTitleToClipboard() async {
    try {
      if (!mounted) return;

      final title = widget.note.title;
      if (title.isEmpty) {
        ToastHelper.info(title: 'Пусто', description: 'Заголовок не указан');
        return;
      }
      await Clipboard.setData(ClipboardData(text: title));
      ToastHelper.success(title: 'Заголовок скопирован в буфер');
    } catch (e, s) {
      logError('Ошибка копирования заголовка в буфер', error: e, stackTrace: s);
      if (!mounted) return;
      ToastHelper.error(title: 'Ошибка копирования', description: e.toString());
    }
  }

  Future<void> _copyContentToClipboard() async {
    try {
      if (!mounted) return;

      final content = _fullContent ?? widget.note.content ?? '';
      if (content.isEmpty) {
        ToastHelper.info(title: 'Пусто', description: 'Содержимое не указано');
        return;
      }
      await Clipboard.setData(ClipboardData(text: content));
      ToastHelper.success(title: 'Содержимое скопировано в буфер');
    } catch (e, s) {
      logError(
        'Ошибка копирования содержимого в буфер',
        error: e,
        stackTrace: s,
      );
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
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main Card Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Icons Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.note.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Favorite Icon
                        IconButton(
                          onPressed: widget.onFavoriteToggle,
                          icon: Icon(
                            widget.note.isFavorite ?? false
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.note.isFavorite ?? false
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        // Pin Icon
                        IconButton(
                          onPressed: widget.onPinToggle,
                          icon: Icon(
                            widget.note.isPinned ?? false
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            color: widget.note.isPinned ?? false
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),

                    // Description
                    if (widget.note.description?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.note.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Content Preview
                    if (widget.note.content?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.note.content!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Categories and Tags
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (widget.note.category != null)
                          _CategoryChip(
                            name: widget.note.category!.name,
                            colorHex: widget.note.category!.color,
                          ),
                        ...?widget.note.tags?.map(
                          (tag) =>
                              _TagChip(name: tag.name, colorHex: tag.color),
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Content
                      if (_fullContent != null && _fullContent!.isNotEmpty) ...[
                        Text(
                          'Содержимое:',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(_fullContent!, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                      ],

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.title,
                              label: 'Копировать заголовок',
                              onPressed: _copyTitleToClipboard,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.content_copy,
                              label: 'Копировать содержимое',
                              onPressed: _copyContentToClipboard,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.edit,
                              label: 'Редактировать',
                              onPressed: widget.onEdit,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.delete,
                              label: 'Удалить',
                              onPressed: widget.onDelete,
                            ),
                          ),
                        ],
                      ),
                    ],
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
