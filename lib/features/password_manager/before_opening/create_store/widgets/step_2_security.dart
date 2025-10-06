import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/password_field.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store_control.dart';

/// Шаг 2: Настройка безопасности (мастер-пароль)
class Step2Security extends ConsumerStatefulWidget {
  final TextEditingController masterPasswordController;
  final TextEditingController confirmPasswordController;

  const Step2Security({
    super.key,
    required this.masterPasswordController,
    required this.confirmPasswordController,
  });

  @override
  ConsumerState<Step2Security> createState() => _Step2SecurityState();
}

class _Step2SecurityState extends ConsumerState<Step2Security> {
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
            'Безопасность',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Установите надежный мастер-пароль для защиты вашего хранилища',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.errorContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Запомните или надежно сохраните мастер-пароль. Восстановление невозможно!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomPasswordField(
            controller: widget.masterPasswordController,
            label: 'Мастер-пароль',
            helperText: 'Минимум 1 символ',
            errorText: formState.fieldErrors['masterPassword'],
            onChanged: controller.updateMasterPassword,
            autofocus: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Мастер-пароль обязателен';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomPasswordField(
            controller: widget.confirmPasswordController,
            label: 'Подтвердите мастер-пароль',
            helperText: 'Введите тот же пароль для подтверждения',
            errorText: formState.fieldErrors['confirmPassword'],
            onChanged: controller.updateConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Подтверждение пароля обязательно';
              }
              if (value != widget.masterPasswordController.text) {
                return 'Пароли не совпадают';
              }
              return null;
            },
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
