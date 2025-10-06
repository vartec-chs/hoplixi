import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store_control.dart';

/// Шаг 3: Выбор пути хранения
class Step3StoragePath extends ConsumerStatefulWidget {
  const Step3StoragePath({super.key});

  @override
  ConsumerState<Step3StoragePath> createState() => _Step3StoragePathState();
}

class _Step3StoragePathState extends ConsumerState<Step3StoragePath> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createStoreControllerProvider);
    final controller = ref.read(createStoreControllerProvider.notifier);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Путь хранения',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите расположение файла базы данных',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          RadioListTile<bool>(
            value: true,
            groupValue: formState.useDefaultPath,
            onChanged: (value) {
              if (value != null) {
                controller.toggleUseDefaultPath(value);
              }
            },
            title: const Text('Использовать путь по умолчанию'),
            subtitle: Text(
              formState.defaultStoragePath ?? 'Путь не определен',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            value: false,
            groupValue: formState.useDefaultPath,
            onChanged: (value) {
              if (value != null) {
                controller.toggleUseDefaultPath(value);
              }
            },
            title: const Text('Выбрать свой путь'),
            subtitle: const Text(
              'Укажите собственное расположение базы данных',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          if (!formState.useDefaultPath) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    validator: (value) {
                      if (!formState.useDefaultPath &&
                          (value == null || value.isEmpty)) {
                        return 'Выберите путь для хранения';
                      }
                      return null;
                    },
                    decoration:
                        primaryInputDecoration(
                          context,
                          labelText: 'Путь к файлу базы данных',
                          helperText: 'Нажмите кнопку для выбора расположения',
                          filled: true,
                          errorText: formState.fieldErrors['customPath'],
                        ).copyWith(
                          hintText: formState.customStoragePath ?? 'Не выбран',
                        ),
                    controller: TextEditingController(
                      text: formState.customStoragePath ?? '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SmoothButton(
                  onPressed: () async {
                    String? selectedDirectory = await FilePicker.platform
                        .getDirectoryPath();
                    if (selectedDirectory != null) {
                      controller.updateCustomPath(selectedDirectory);
                    }
                  },
                  label: 'Обзор',
                  icon: const Icon(Icons.folder_open),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Метод для валидации формы (вызывается извне)
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }
}
