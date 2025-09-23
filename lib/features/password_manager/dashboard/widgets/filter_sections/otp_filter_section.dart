import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/models/filter/otp_filter.dart';
import 'package:hoplixi/common/text_field.dart';

/// Секция для настройки специфических фильтров OTP
class OtpFilterSection extends StatefulWidget {
  final OtpFilter filter;
  final Function(OtpFilter) onFilterChanged;

  const OtpFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<OtpFilterSection> createState() => _OtpFilterSectionState();
}

class _OtpFilterSectionState extends State<OtpFilterSection> {
  late final TextEditingController _issuerController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _periodController;

  @override
  void initState() {
    super.initState();
    _issuerController = TextEditingController(text: widget.filter.issuer ?? '');
    _accountNameController = TextEditingController(
      text: widget.filter.accountName ?? '',
    );
    _periodController = TextEditingController(
      text: widget.filter.period?.toString() ?? '',
    );
  }

  // @override
  // void didUpdateWidget(OtpFilterSection oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // Обновляем текст контроллеров при изменении фильтра извне
  //   if (oldWidget.filter.issuer != widget.filter.issuer) {
  //     _issuerController.text = widget.filter.issuer ?? '';
  //   }
  //   if (oldWidget.filter.accountName != widget.filter.accountName) {
  //     _accountNameController.text = widget.filter.accountName ?? '';
  //   }
  //   if (oldWidget.filter.period != widget.filter.period) {
  //     _periodController.text = widget.filter.period?.toString() ?? '';
  //   }
  // }

  @override
  void dispose() {
    _issuerController.dispose();
    _accountNameController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Фильтры для OTP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Тип OTP
        const Text('Тип OTP', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<OtpType>(
          decoration: primaryInputDecoration(context, labelText: 'Тип OTP'),
          initialValue: widget.filter.type,
          items: [
            const DropdownMenuItem<OtpType>(
              value: null,
              child: Text('Все типы'),
            ),
            ...OtpType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getOtpTypeLabel(type)),
              );
            }),
          ],
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(type: value));
          },
        ),
        const SizedBox(height: 16),

        // Поля поиска
        PrimaryTextField(
          label: 'Издатель (Issuer)',
          hintText: 'Поиск по издателю (например, Google, GitHub)',
          controller: _issuerController,
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            widget.onFilterChanged(
              widget.filter.copyWith(issuer: normalizedValue),
            );
          },
          prefixIcon: const Icon(Icons.business),
        ),
        const SizedBox(height: 12),

        PrimaryTextField(
          label: 'Имя аккаунта',
          hintText: 'Поиск по имени аккаунта',
          controller: _accountNameController,
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            widget.onFilterChanged(
              widget.filter.copyWith(accountName: normalizedValue),
            );
          },
          prefixIcon: const Icon(Icons.account_circle),
        ),
        const SizedBox(height: 16),

        // Алгоритмы
        const Text(
          'Алгоритмы хеширования',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _getSupportedAlgorithms().map((algorithm) {
            final isSelected =
                widget.filter.algorithms?.contains(algorithm) ?? false;
            return FilterChip(
              label: Text(algorithm),
              selected: isSelected,
              onSelected: (selected) {
                List<String> newAlgorithms = List.from(
                  widget.filter.algorithms ?? [],
                );
                if (selected) {
                  if (!newAlgorithms.contains(algorithm)) {
                    newAlgorithms.add(algorithm);
                  }
                } else {
                  newAlgorithms.remove(algorithm);
                }
                widget.onFilterChanged(
                  widget.filter.copyWith(
                    algorithms: newAlgorithms.isEmpty ? null : newAlgorithms,
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Количество цифр
        const Text(
          'Количество цифр',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          decoration: primaryInputDecoration(
            context,
            labelText: 'Количество цифр в коде',
          ),
          initialValue: widget.filter.digits,
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('Любое количество'),
            ),
            ...(_getSupportedDigits()).map((digits) {
              return DropdownMenuItem(
                value: digits,
                child: Text('$digits цифр'),
              );
            }),
          ],
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(digits: value));
          },
        ),
        const SizedBox(height: 16),

        // Период для TOTP
        if (widget.filter.type == null ||
            widget.filter.type == OtpType.totp) ...[
          const Text(
            'Период обновления (TOTP)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          PrimaryTextField(
            label: 'Период в секундах',
            hintText: 'От 1 до 300 секунд (например, 30)',
            controller: _periodController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final intValue = int.tryParse(value);
              final validValue =
                  intValue != null && intValue > 0 && intValue <= 300
                  ? intValue
                  : null;
              widget.onFilterChanged(
                widget.filter.copyWith(period: validValue),
              );
            },
            prefixIcon: const Icon(Icons.timer),
          ),
          if (widget.filter.period != null && !widget.filter.isValidPeriod) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Период должен быть от 1 до 300 секунд',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],

        // Булевые фильтры
        const Text(
          'Свойства OTP',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        CheckboxListTile(
          title: const Text('Есть связь с паролем'),
          value: widget.filter.hasPasswordLink,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(
              widget.filter.copyWith(hasPasswordLink: value),
            );
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),

        // Поле сортировки
        const Text('Сортировка', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<OtpSortField>(
          decoration: primaryInputDecoration(
            context,
            labelText: 'Поле сортировки',
          ),
          initialValue: widget.filter.sortField,
          items: OtpSortField.values.map((field) {
            return DropdownMenuItem(
              value: field,
              child: Text(_getOtpSortFieldLabel(field)),
            );
          }).toList(),
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(sortField: value));
          },
        ),
      ],
    );
  }

  String _getOtpTypeLabel(OtpType type) {
    switch (type) {
      case OtpType.totp:
        return 'TOTP (Time-based)';
      case OtpType.hotp:
        return 'HOTP (Counter-based)';
    }
  }

  String _getOtpSortFieldLabel(OtpSortField field) {
    switch (field) {
      case OtpSortField.issuer:
        return 'Издатель';
      case OtpSortField.accountName:
        return 'Имя аккаунта';
      case OtpSortField.createdAt:
        return 'Дата создания';
      case OtpSortField.modifiedAt:
        return 'Дата изменения';
      case OtpSortField.lastAccessed:
        return 'Последний доступ';
    }
  }

  List<String> _getSupportedAlgorithms() {
    return ['SHA1', 'SHA256', 'SHA512'];
  }

  List<int> _getSupportedDigits() {
    return [6, 8];
  }
}
