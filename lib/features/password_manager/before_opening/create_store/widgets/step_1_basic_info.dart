import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store_control.dart';

/// Шаг 1: Основная информация о хранилище
class Step1BasicInfo extends ConsumerWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const Step1BasicInfo({
    super.key,
    required this.nameController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(createStoreControllerProvider);
    final controller = ref.read(createStoreControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок шага
        Text(
          'Основная информация',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Введите название и описание вашего хранилища паролей',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Название хранилища
        TextFormField(
          controller: nameController,
          onChanged: controller.updateStoreName,
          autofocus: true,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Название хранилища',
            helperText: 'Используйте понятное название для идентификации',
            filled: true,
            errorText: formState.fieldErrors['storeName'],
          ).copyWith(prefixIcon: const Icon(Icons.shield_outlined)),
        ),
        const SizedBox(height: 16),

        // Описание хранилища
        TextFormField(
          controller: descriptionController,
          onChanged: controller.updateStoreDescription,
          decoration: primaryInputDecoration(
            context,
            labelText: 'Описание хранилища (необязательно)',
            helperText: 'Добавьте краткое описание назначения хранилища',
            filled: true,
            errorText: formState.fieldErrors['storeDescription'],
          ).copyWith(prefixIcon: const Icon(Icons.description_outlined)),
          minLines: 3,
          maxLines: 5,
        ),
      ],
    );
  }
}
