import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter/password_filter.dart';
import 'base_filter_section.dart';

/// Секция для фильтров паролей
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
        // Базовые фильтры
        BaseFilterSection(
          filter: filter.base,
          entityTypeName: 'паролей',
          onFilterChanged: (baseFilter) {
            onFilterChanged(filter.copyWith(base: baseFilter));
          },
        ),
        const SizedBox(height: 24),

        // Специфичные для паролей фильтры
        const Text(
          'Специфичные фильтры для паролей',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Фильтр по названию
        TextField(
          decoration: const InputDecoration(
            labelText: 'Фильтр по названию',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: filter.name ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(name: value.trim().isEmpty ? null : value.trim()),
            );
          },
        ),
        const SizedBox(height: 16),

        // Фильтр по URL
        TextField(
          decoration: const InputDecoration(
            labelText: 'Фильтр по URL',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: filter.url ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(url: value.trim().isEmpty ? null : value.trim()),
            );
          },
        ),
        const SizedBox(height: 16),

        // Фильтр по имени пользователя
        TextField(
          decoration: const InputDecoration(
            labelText: 'Фильтр по имени пользователя',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: filter.username ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(
                username: value.trim().isEmpty ? null : value.trim(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Булевые фильтры
        CheckboxListTile(
          title: const Text('Только часто используемые'),
          value: filter.isFrequent,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isFrequent: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только с URL'),
          value: filter.hasUrl,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasUrl: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только с именем пользователя'),
          value: filter.hasUsername,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasUsername: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только с TOTP'),
          value: filter.hasTotp,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasTotp: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только скомпрометированные'),
          value: filter.isCompromised,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isCompromised: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Только истекшие'),
          value: filter.isExpired,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(isExpired: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}
