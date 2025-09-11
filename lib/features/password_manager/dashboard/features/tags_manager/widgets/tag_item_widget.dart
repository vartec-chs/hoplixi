import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store.dart' as store;
import 'package:hoplixi/hoplixi_store/enums/entity_types.dart';

class TagItemWidget extends StatelessWidget {
  final store.Tag tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TagItemWidget({
    Key? key,
    required this.tag,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  Color get tagColor {
    if (tag.color != null && tag.color!.isNotEmpty) {
      try {
        return Color(int.parse(tag.color!.replaceAll('#', '0xFF')));
      } catch (e) {
        return _getDefaultTypeColor();
      }
    }
    return _getDefaultTypeColor();
  }

  Color _getDefaultTypeColor() {
    switch (tag.type) {
      case TagType.password:
        return Colors.blue;
      case TagType.notes:
        return Colors.green;
      case TagType.totp:
        return Colors.orange;
      case TagType.mixed:
        return Colors.purple;
    }
  }

  String get typeLabel {
    switch (tag.type) {
      case TagType.password:
        return 'Пароли';
      case TagType.notes:
        return 'Заметки';
      case TagType.totp:
        return 'TOTP';
      case TagType.mixed:
        return 'Смешанный';
    }
  }

  IconData get typeIcon {
    switch (tag.type) {
      case TagType.password:
        return Icons.lock;
      case TagType.notes:
        return Icons.note;
      case TagType.totp:
        return Icons.security;
      case TagType.mixed:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: tagColor,
          child: Icon(typeIcon, color: Colors.white, size: 20),
        ),
        title: Text(
          tag.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  typeIcon,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(typeLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Создан: ${_formatDateTime(tag.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (tag.modifiedAt.difference(tag.createdAt).inSeconds > 1)
              Text(
                'Изменен: ${_formatDateTime(tag.modifiedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Редактировать'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem<String>(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Удалить'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}г назад';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}мес назад';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}мин назад';
    } else {
      return 'Только что';
    }
  }
}
