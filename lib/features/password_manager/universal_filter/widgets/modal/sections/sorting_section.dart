import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/universal_filter/universal_filter_barrel.dart';
import 'package:hoplixi/hoplixi_store/models/password_filter.dart'
    show PasswordFilter, PasswordSortField;
import 'package:hoplixi/hoplixi_store/models/password_filter.dart'
    as password_filter
    show SortDirection;
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart'
    show BaseFilter;
import 'package:hoplixi/hoplixi_store/models/filter/base_filter.dart'
    as base_filter
    show SortDirection;
import 'package:hoplixi/hoplixi_store/models/filter/notes_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/otp_filter.dart';
import 'package:hoplixi/hoplixi_store/models/filter/attachments_filter.dart';
import '../mixins/filter_helper_mixin.dart';

/// Компонент для настройки сортировки
class SortingSection extends ConsumerWidget with FilterHelperMixin {
  final UniversalFilter filter;
  final Function(UniversalFilter) onFilterChanged;

  const SortingSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortOptions = getSortOptions(filter.entityType);
    final currentSortField = _getCurrentSortField();
    final isAscending = _isCurrentSortAscending();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Сортировка',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Поле сортировки
        DropdownButtonFormField<String?>(
          decoration: const InputDecoration(
            labelText: 'Сортировать по',
            border: OutlineInputBorder(),
          ),
          value: currentSortField,
          items: [
            const DropdownMenuItem(value: null, child: Text('По умолчанию')),
            ...sortOptions.map(
              (option) => DropdownMenuItem(
                value: option['value'],
                child: Text(option['label']!),
              ),
            ),
          ],
          onChanged: (value) {
            _updateSortField(value);
          },
        ),
        const SizedBox(height: 16),

        // Направление сортировки
        if (currentSortField != null) ...[
          Row(
            children: [
              const Text('Направление: '),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: isAscending,
                      onChanged: (value) {
                        if (value != null) {
                          _updateSortDirection(value);
                        }
                      },
                    ),
                    const Text('По возрастанию'),
                    const SizedBox(width: 16),
                    Radio<bool>(
                      value: false,
                      groupValue: isAscending,
                      onChanged: (value) {
                        if (value != null) {
                          _updateSortDirection(value);
                        }
                      },
                    ),
                    const Text('По убыванию'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String? _getCurrentSortField() {
    switch (filter.entityType) {
      case UniversalEntityType.password:
        return filter.passwordFilter?.sortField?.name;
      case UniversalEntityType.note:
        return filter.notesFilter?.sortField?.name;
      case UniversalEntityType.otp:
        return filter.otpFilter?.sortField?.name;
      case UniversalEntityType.attachment:
        return filter.attachmentsFilter?.sortField?.name;
    }
  }

  bool _isCurrentSortAscending() {
    switch (filter.entityType) {
      case UniversalEntityType.password:
        return filter.passwordFilter?.sortDirection ==
            password_filter.SortDirection.asc;
      case UniversalEntityType.note:
        return filter.notesFilter?.sortDirection.name == 'asc';
      case UniversalEntityType.otp:
        return filter.otpFilter?.sortDirection.name == 'asc';
      case UniversalEntityType.attachment:
        return filter.attachmentsFilter?.sortDirection.name == 'asc';
    }
  }

  void _updateSortField(String? fieldName) {
    switch (filter.entityType) {
      case UniversalEntityType.password:
        final passwordField = fieldName != null
            ? PasswordSortField.values.firstWhere((e) => e.name == fieldName)
            : null;
        final updatedPasswordFilter =
            filter.passwordFilter?.copyWith(sortField: passwordField) ??
            PasswordFilter(sortField: passwordField);
        onFilterChanged(filter.copyWith(passwordFilter: updatedPasswordFilter));
        break;

      case UniversalEntityType.note:
        final notesField = fieldName != null
            ? NotesSortField.values.firstWhere((e) => e.name == fieldName)
            : null;
        final updatedNotesFilter =
            filter.notesFilter?.copyWith(sortField: notesField) ??
            NotesFilter(base: const BaseFilter(), sortField: notesField);
        onFilterChanged(filter.copyWith(notesFilter: updatedNotesFilter));
        break;

      case UniversalEntityType.otp:
        final otpField = fieldName != null
            ? OtpSortField.values.firstWhere((e) => e.name == fieldName)
            : null;
        final updatedOtpFilter =
            filter.otpFilter?.copyWith(sortField: otpField) ??
            OtpFilter(base: const BaseFilter(), sortField: otpField);
        onFilterChanged(filter.copyWith(otpFilter: updatedOtpFilter));
        break;

      case UniversalEntityType.attachment:
        final attachmentField = fieldName != null
            ? AttachmentsSortField.values.firstWhere((e) => e.name == fieldName)
            : null;
        final updatedAttachmentsFilter =
            filter.attachmentsFilter?.copyWith(sortField: attachmentField) ??
            AttachmentsFilter(
              base: const BaseFilter(),
              sortField: attachmentField,
            );
        onFilterChanged(
          filter.copyWith(attachmentsFilter: updatedAttachmentsFilter),
        );
        break;
    }
  }

  void _updateSortDirection(bool isAscending) {
    switch (filter.entityType) {
      case UniversalEntityType.password:
        final direction = isAscending
            ? password_filter.SortDirection.asc
            : password_filter.SortDirection.desc;
        final updatedPasswordFilter =
            filter.passwordFilter?.copyWith(sortDirection: direction) ??
            PasswordFilter(sortDirection: direction);
        onFilterChanged(filter.copyWith(passwordFilter: updatedPasswordFilter));
        break;

      case UniversalEntityType.note:
        final direction = isAscending
            ? base_filter.SortDirection.asc
            : base_filter.SortDirection.desc;
        final updatedNotesFilter =
            filter.notesFilter?.copyWith(sortDirection: direction) ??
            NotesFilter(base: const BaseFilter(), sortDirection: direction);
        onFilterChanged(filter.copyWith(notesFilter: updatedNotesFilter));
        break;

      case UniversalEntityType.otp:
        final direction = isAscending
            ? base_filter.SortDirection.asc
            : base_filter.SortDirection.desc;
        final updatedOtpFilter =
            filter.otpFilter?.copyWith(sortDirection: direction) ??
            OtpFilter(base: const BaseFilter(), sortDirection: direction);
        onFilterChanged(filter.copyWith(otpFilter: updatedOtpFilter));
        break;

      case UniversalEntityType.attachment:
        final direction = isAscending
            ? base_filter.SortDirection.asc
            : base_filter.SortDirection.desc;
        final updatedAttachmentsFilter =
            filter.attachmentsFilter?.copyWith(sortDirection: direction) ??
            AttachmentsFilter(
              base: const BaseFilter(),
              sortDirection: direction,
            );
        onFilterChanged(
          filter.copyWith(attachmentsFilter: updatedAttachmentsFilter),
        );
        break;
    }
  }
}
