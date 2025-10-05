import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store_control.dart';

/// Шаг 3: Выбор пути хранения
class Step3StoragePath extends ConsumerWidget {
  const Step3StoragePath({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(createStoreControllerProvider);
    final controller = ref.read(createStoreControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок шага
        Text(
          'Место хранения',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Выберите, где будет сохранен файл хранилища',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Выбор типа пути
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: true,
              label: Text('Предустановленный'),
              icon: Icon(Icons.folder_special),
            ),
            ButtonSegment(
              value: false,
              label: Text('Пользовательский'),
              icon: Icon(Icons.create_new_folder),
            ),
          ],
          selected: <bool>{formState.isDefaultPath},
          onSelectionChanged: (Set<bool> newSelection) {
            controller.togglePathType(newSelection.first);
          },
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Информационная карточка
        if (formState.isDefaultPath)
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Хранилище будет сохранено в стандартной папке приложения',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Итоговый путь
        TextFormField(
          decoration:
              primaryInputDecoration(
                context,
                labelText: 'Путь к файлу хранилища',
                helperText: 'Файл будет сохранен в этой директории',
                filled: true,
              ).copyWith(
                prefixIcon: const Icon(Icons.folder_outlined),
                suffixIcon: !formState.isDefaultPath
                    ? IconButton(
                        icon: const Icon(Icons.edit_location_alt),
                        onPressed: controller.selectCustomPath,
                        tooltip: 'Изменить путь',
                      )
                    : null,
              ),
          minLines: 1,
          maxLines: 3,
          readOnly: true,
          initialValue: formState.finalPath,
          key: ValueKey(formState.finalPath),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
        ),
        const SizedBox(height: 16),

        // Кнопка выбора пути (только для пользовательского пути)
        if (!formState.isDefaultPath)
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: formState.isLoading
                  ? null
                  : controller.selectCustomPath,
              icon: const Icon(Icons.folder_open),
              label: const Text('Выбрать место сохранения'),
            ),
          ),
      ],
    );
  }
}
