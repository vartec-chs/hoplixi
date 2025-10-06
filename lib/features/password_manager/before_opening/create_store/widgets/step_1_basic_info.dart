import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store_control.dart';

/// Шаг 1: Основная информация о хранилище
class Step1BasicInfo extends ConsumerStatefulWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;

  const Step1BasicInfo({
    super.key,
    required this.nameController,
    required this.descriptionController,
  });

  @override
  ConsumerState<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends ConsumerState<Step1BasicInfo> {
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
            controller: widget.nameController,
            onChanged: controller.updateStoreName,
            autofocus: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Название хранилища обязательно';
              }
              if (value.length < 3) {
                return 'Название должно содержать минимум 3 символа';
              }
              if (value.length > 50) {
                return 'Название не должно превышать 50 символов';
              }
              if (!RegExp(r'^[a-zA-Zа-яА-Я0-9\s_-]+$').hasMatch(value)) {
                return 'Название содержит недопустимые символы';
              }
              return null;
            },
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
            controller: widget.descriptionController,
            onChanged: controller.updateStoreDescription,
            validator: (value) {
              if (value != null && value.length > 200) {
                return 'Описание не должно превышать 200 символов';
              }
              return null;
            },
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
      ),
    );
  }

  // Метод для валидации формы (вызывается извне)
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }
}
