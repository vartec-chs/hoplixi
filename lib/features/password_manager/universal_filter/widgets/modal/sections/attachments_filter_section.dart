import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter/attachments_filter.dart';
import 'base_filter_section.dart';

/// Секция для фильтров вложений
class AttachmentsFilterSection extends ConsumerWidget {
  final AttachmentsFilter filter;
  final Function(AttachmentsFilter) onFilterChanged;

  const AttachmentsFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Базовые фильтры
        BaseFilterSection(
          filter: filter.base,
          entityTypeName: 'вложений',
          onFilterChanged: (baseFilter) {
            onFilterChanged(filter.copyWith(base: baseFilter));
          },
        ),
        const SizedBox(height: 24),

        // Специфичные для вложений фильтры
        const Text(
          'Специфичные фильтры для вложений',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Фильтр по имени файла
        TextField(
          decoration: const InputDecoration(
            labelText: 'Фильтр по имени файла',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: filter.name ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(
                name: value.trim().isEmpty ? null : value.trim(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Фильтр по описанию
        TextField(
          decoration: const InputDecoration(
            labelText: 'Фильтр по описанию',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: filter.description ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(
                description: value.trim().isEmpty ? null : value.trim(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Расширение файла
        TextField(
          decoration: const InputDecoration(
            labelText: 'Расширение файла',
            border: OutlineInputBorder(),
            hintText: 'Например: pdf, jpg, txt',
          ),
          controller: TextEditingController(text: filter.fileExtension ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(
                fileExtension: value.trim().isEmpty ? null : value.trim(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Тип прикрепления
        DropdownButtonFormField<AttachmentType?>(
          decoration: const InputDecoration(
            labelText: 'Тип прикрепления',
            border: OutlineInputBorder(),
          ),
          value: filter.attachedToType,
          items: [
            const DropdownMenuItem(value: null, child: Text('Все типы')),
            ...AttachmentType.values.map(
              (type) => DropdownMenuItem(
                value: type,
                child: Text(_getAttachmentTypeLabel(type)),
              ),
            ),
          ],
          onChanged: (value) {
            onFilterChanged(filter.copyWith(attachedToType: value));
          },
        ),
        const SizedBox(height: 16),

        // Размер файла
        const Text(
          'Размер файла',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Минимальный размер (байты)',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: filter.minFileSize?.toString() ?? '',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  onFilterChanged(filter.copyWith(minFileSize: intValue));
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Максимальный размер (байты)',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(
                  text: filter.maxFileSize?.toString() ?? '',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  onFilterChanged(filter.copyWith(maxFileSize: intValue));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // MIME типы
        const Text(
          'MIME типы',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            'image/jpeg',
            'image/png',
            'application/pdf',
            'text/plain',
            'application/msword',
            'application/zip'
          ].map((mimeType) {
            final isSelected = filter.mimeTypes?.contains(mimeType) ?? false;
            return FilterChip(
              label: Text(_getMimeTypeLabel(mimeType)),
              selected: isSelected,
              onSelected: (selected) {
                final currentTypes = filter.mimeTypes ?? <String>[];
                List<String> newTypes;
                if (selected) {
                  newTypes = [...currentTypes, mimeType];
                } else {
                  newTypes = currentTypes.where((t) => t != mimeType).toList();
                }
                onFilterChanged(
                  filter.copyWith(
                    mimeTypes: newTypes.isEmpty ? null : newTypes,
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Дополнительные фильтры
        CheckboxListTile(
          title: const Text('Только с контрольной суммой'),
          value: filter.hasChecksum,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasChecksum: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  String _getAttachmentTypeLabel(AttachmentType type) {
    switch (type) {
      case AttachmentType.password:
        return 'Пароль';
      case AttachmentType.totp:
        return 'TOTP';
      case AttachmentType.note:
        return 'Заметка';
    }
  }

  String _getMimeTypeLabel(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
        return 'JPEG';
      case 'image/png':
        return 'PNG';
      case 'application/pdf':
        return 'PDF';
      case 'text/plain':
        return 'Текст';
      case 'application/msword':
        return 'Word';
      case 'application/zip':
        return 'ZIP';
      default:
        return mimeType;
    }
  }
}