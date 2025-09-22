import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter/password_filter.dart';
import 'package:hoplixi/common/text_field.dart';

/// Секция для настройки специфических фильтров паролей
class PasswordFilterSection extends ConsumerWidget {
  final PasswordFilter filter;
  final Function(PasswordFilter) onFilterChanged;

  const PasswordFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Фильтры для паролей',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Поля поиска
        PrimaryTextField(
          label: 'Название',
          hintText: 'Поиск по названию пароля',
          controller: TextEditingController(text: filter.name ?? ''),
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            onFilterChanged(filter.copyWith(name: normalizedValue));
          },
          prefixIcon: const Icon(Icons.text_fields),
        ),
        const SizedBox(height: 12),

        PrimaryTextField(
          label: 'URL',
          hintText: 'Поиск по URL сайта',
          controller: TextEditingController(text: filter.url ?? ''),
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            onFilterChanged(filter.copyWith(url: normalizedValue));
          },
          prefixIcon: const Icon(Icons.link),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),

        PrimaryTextField(
          label: 'Имя пользователя',
          hintText: 'Поиск по имени пользователя',
          controller: TextEditingController(text: filter.username ?? ''),
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            onFilterChanged(filter.copyWith(username: normalizedValue));
          },
          prefixIcon: const Icon(Icons.person),
        ),
        const SizedBox(height: 16),

        // Булевые фильтры
        const Text(
          'Наличие данных',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CheckboxListTile(
          title: const Text('Есть URL'),
          value: filter.hasUrl,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasUrl: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Есть имя пользователя'),
          value: filter.hasUsername,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasUsername: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Есть TOTP'),
          value: filter.hasTotp,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasTotp: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),

        // Статус пароля
        const Text(
          'Статус пароля',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CheckboxListTile(
          title: const Text('Скомпрометированный'),
          value: filter.isCompromised,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isCompromised: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Истекший'),
          value: filter.isExpired,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isExpired: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Часто используемый'),
          subtitle: Text('Более $kFrequentUsedThreshold использований'),
          value: filter.isFrequent,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isFrequent: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),

        // Поле сортировки
        const Text('Сортировка', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<PasswordSortField>(
          decoration: primaryInputDecoration(
            context,
            labelText: 'Поле сортировки',
          ),
          value: filter.sortField,
          items: PasswordSortField.values.map((field) {
            return DropdownMenuItem(
              value: field,
              child: Text(_getPasswordSortFieldLabel(field)),
            );
          }).toList(),
          onChanged: (value) {
            onFilterChanged(filter.copyWith(sortField: value));
          },
        ),
      ],
    );
  }

  String _getPasswordSortFieldLabel(PasswordSortField field) {
    switch (field) {
      case PasswordSortField.name:
        return 'Название';
      case PasswordSortField.url:
        return 'URL';
      case PasswordSortField.username:
        return 'Имя пользователя';
      case PasswordSortField.createdAt:
        return 'Дата создания';
      case PasswordSortField.modifiedAt:
        return 'Дата изменения';
      case PasswordSortField.lastAccessed:
        return 'Последний доступ';
      case PasswordSortField.usedCount:
        return 'Количество использований';
      case PasswordSortField.strength:
        return 'Сила пароля';
    }
  }
}
