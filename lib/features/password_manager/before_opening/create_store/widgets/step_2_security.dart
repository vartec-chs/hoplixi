import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/global/widgets/password_field.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store_control.dart';

/// Шаг 2: Настройка безопасности
class Step2Security extends ConsumerWidget {
  final TextEditingController masterPasswordController;
  final TextEditingController confirmPasswordController;

  const Step2Security({
    super.key,
    required this.masterPasswordController,
    required this.confirmPasswordController,
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
          'Настройка безопасности',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Создайте надежный мастер-пароль для защиты ваших данных',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Информационная карточка
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Мастер-пароль — это главный ключ к вашему хранилищу. '
                    'Убедитесь, что он достаточно сложный и вы его запомните.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Мастер пароль
        CustomPasswordField(
          label: 'Мастер-пароль',
          controller: masterPasswordController,
          onChanged: controller.updateMasterPassword,
          errorText: formState.fieldErrors['masterPassword'],
          autofocus: true,
        ),
        const SizedBox(height: 16),

        // Подтверждение пароля
        CustomPasswordField(
          label: 'Подтвердите мастер-пароль',
          controller: confirmPasswordController,
          onChanged: controller.updateConfirmPassword,
          errorText: formState.fieldErrors['confirmPassword'],
        ),
        const SizedBox(height: 24),

        // Переключатель сохранения пароля с предупреждением
        Card(
          color: formState.saveMasterPassword
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: formState.saveMasterPassword,
                  onChanged: controller.toggleSaveMasterPassword,
                  title: const Text('Сохранить мастер-пароль'),
                  subtitle: const Text(
                    'Автоматически открывать хранилище без ввода пароля',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (formState.saveMasterPassword) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ВНИМАНИЕ: РИСК БЕЗОПАСНОСТИ',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Сохранение мастер-пароля крайне рискованно! Включайте эту опцию только если:\n'
                          '• Вы уверены в безопасности своего окружения\n'
                          '• На устройстве нет вирусов и вредоносного ПО\n'
                          '• Устройство защищено надежным паролем/биометрией\n'
                          '• Никто другой не имеет доступа к устройству\n\n'
                          'При компрометации устройства злоумышленники получат доступ ко всем вашим паролям!',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
