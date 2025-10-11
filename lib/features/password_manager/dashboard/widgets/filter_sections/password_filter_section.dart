import 'package:flutter/material.dart';
import 'package:hoplixi/hoplixi_store/models/filter_models/password_filter.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';

/// Секция для настройки специфических фильтров паролей
class PasswordFilterSection extends StatefulWidget {
  final PasswordFilter filter;
  final Function(PasswordFilter) onFilterChanged;

  const PasswordFilterSection({
    super.key,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  State<PasswordFilterSection> createState() => _PasswordFilterSectionState();
}

class _PasswordFilterSectionState extends State<PasswordFilterSection> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.filter.name ?? '');
    _urlController = TextEditingController(text: widget.filter.url ?? '');
    _usernameController = TextEditingController(
      text: widget.filter.username ?? '',
    );
  }

  // @override
  // void didUpdateWidget(PasswordFilterSection oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // Обновляем текст контроллеров при изменении фильтра извне
  //   if (oldWidget.filter.name != widget.filter.name) {
  //     _nameController.text = widget.filter.name ?? '';
  //   }
  //   if (oldWidget.filter.url != widget.filter.url) {
  //     _urlController.text = widget.filter.url ?? '';
  //   }
  //   if (oldWidget.filter.username != widget.filter.username) {
  //     _usernameController.text = widget.filter.username ?? '';
  //   }
  // }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          controller: _nameController,
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            widget.onFilterChanged(
              widget.filter.copyWith(name: normalizedValue),
            );
          },
          prefixIcon: const Icon(Icons.text_fields),
        ),
        const SizedBox(height: 12),

        PrimaryTextField(
          label: 'URL',
          hintText: 'Поиск по URL сайта',
          controller: _urlController,
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            widget.onFilterChanged(
              widget.filter.copyWith(url: normalizedValue),
            );
          },
          prefixIcon: const Icon(Icons.link),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),

        PrimaryTextField(
          label: 'Имя пользователя',
          hintText: 'Поиск по имени пользователя',
          controller: _usernameController,
          onChanged: (value) {
            final normalizedValue = value.trim().isEmpty ? null : value.trim();
            widget.onFilterChanged(
              widget.filter.copyWith(username: normalizedValue),
            );
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
          value: widget.filter.hasUrl,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(hasUrl: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Есть имя пользователя'),
          value: widget.filter.hasUsername,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(hasUsername: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Есть TOTP'),
          value: widget.filter.hasTotp,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(hasTotp: value));
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
          value: widget.filter.isCompromised,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(
              widget.filter.copyWith(isCompromised: value),
            );
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Истекший'),
          value: widget.filter.isExpired,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(isExpired: value));
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          title: const Text('Часто используемый'),
          subtitle: Text('Более $kFrequentUsedThreshold использований'),
          value: widget.filter.isFrequent,
          tristate: true,
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(isFrequent: value));
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
          initialValue: widget.filter.sortField,
          items: PasswordSortField.values.map((field) {
            return DropdownMenuItem(
              value: field,
              child: Text(_getPasswordSortFieldLabel(field)),
            );
          }).toList(),
          onChanged: (value) {
            widget.onFilterChanged(widget.filter.copyWith(sortField: value));
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
