import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/hoplixi_store/models/filter/otp_filter.dart';
import 'base_filter_section.dart';

/// Секция для фильтров OTP
class OtpFilterSection extends ConsumerWidget {
  final OtpFilter filter;
  final Function(OtpFilter) onFilterChanged;

  const OtpFilterSection({
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
          entityTypeName: 'OTP',
          onFilterChanged: (baseFilter) {
            onFilterChanged(filter.copyWith(base: baseFilter));
          },
        ),
        const SizedBox(height: 24),

        // Специфичные для OTP фильтры
        const Text(
          'Специфичные фильтры для OTP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Тип OTP
        DropdownButtonFormField<OtpType?>(
          decoration: const InputDecoration(
            labelText: 'Тип OTP',
            border: OutlineInputBorder(),
          ),
          initialValue: filter.type,
          items: [
            const DropdownMenuItem(value: null, child: Text('Все типы')),
            ...OtpType.values.map(
              (type) => DropdownMenuItem(
                value: type,
                child: Text(type.name.toUpperCase()),
              ),
            ),
          ],
          onChanged: (value) {
            onFilterChanged(filter.copyWith(type: value));
          },
        ),
        const SizedBox(height: 16),

        // Фильтр по издателю (issuer)
        TextField(
          decoration: const InputDecoration(
            labelText: 'Издатель (Google, GitHub, и т.д.)',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: filter.issuer ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(
                issuer: value.trim().isEmpty ? null : value.trim(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Фильтр по имени аккаунта
        TextField(
          decoration: const InputDecoration(
            labelText: 'Имя аккаунта',
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: filter.accountName ?? ''),
          onChanged: (value) {
            onFilterChanged(
              filter.copyWith(
                accountName: value.trim().isEmpty ? null : value.trim(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Количество цифр
        DropdownButtonFormField<int?>(
          decoration: const InputDecoration(
            labelText: 'Количество цифр',
            border: OutlineInputBorder(),
          ),
          initialValue: filter.digits,
          items: const [
            DropdownMenuItem(value: null, child: Text('Любое количество')),
            DropdownMenuItem(value: 6, child: Text('6 цифр')),
            DropdownMenuItem(value: 8, child: Text('8 цифр')),
          ],
          onChanged: (value) {
            onFilterChanged(filter.copyWith(digits: value));
          },
        ),
        const SizedBox(height: 16),

        // Период (только для TOTP)
        if (filter.type == null || filter.type == OtpType.totp) ...[
          TextField(
            decoration: const InputDecoration(
              labelText: 'Период (секунды, для TOTP)',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(
              text: filter.period?.toString() ?? '',
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              onFilterChanged(filter.copyWith(period: intValue));
            },
          ),
          const SizedBox(height: 16),
        ],

        // Алгоритмы
        const Text('Алгоритмы', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['SHA1', 'SHA256', 'SHA512'].map((algorithm) {
            final isSelected = filter.algorithms?.contains(algorithm) ?? false;
            return FilterChip(
              label: Text(algorithm),
              selected: isSelected,
              onSelected: (selected) {
                final currentAlgorithms = filter.algorithms ?? <String>[];
                List<String> newAlgorithms;
                if (selected) {
                  newAlgorithms = [...currentAlgorithms, algorithm];
                } else {
                  newAlgorithms = currentAlgorithms.where((a) => a != algorithm).toList();
                }
                onFilterChanged(
                  filter.copyWith(
                    algorithms: newAlgorithms.isEmpty ? null : newAlgorithms,
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Связь с паролем
        CheckboxListTile(
          title: const Text('Только связанные с паролем'),
          value: filter.hasPasswordLink,
          tristate: true,
          onChanged: (value) {
            onFilterChanged(filter.copyWith(hasPasswordLink: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}