import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store_control.dart';

/// Шаг 4: Подтверждение и создание
class Step4Confirmation extends ConsumerWidget {
  const Step4Confirmation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(createStoreControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок шага
        Text(
          'Подтверждение',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Проверьте введенные данные перед созданием хранилища',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),

        // Карточка с итоговой информацией
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.shield,
                  label: 'Название',
                  value: formState.storeName,
                ),
                if (formState.storeDescription.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildInfoRow(
                    context,
                    icon: Icons.description,
                    label: 'Описание',
                    value: formState.storeDescription,
                    maxLines: 3,
                  ),
                ],
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: Icons.lock,
                  label: 'Мастер-пароль',
                  value: '•' * formState.masterPassword.length,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: formState.saveMasterPassword
                      ? Icons.warning_amber
                      : Icons.check_circle,
                  label: 'Автоматический вход',
                  value: formState.saveMasterPassword ? 'Включен' : 'Выключен',
                  valueColor: formState.saveMasterPassword
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.tertiary,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: Icons.folder,
                  label: 'Путь',
                  value: formState.finalPath,
                  maxLines: 3,
                  isPath: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Предупреждение о сохранении пароля
        if (formState.saveMasterPassword)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Внимание!',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Вы включили автоматический вход. Это может поставить под угрозу безопасность ваших данных.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 24),

        // Финальная информация
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
                    'После создания хранилища вы сможете начать добавлять в него пароли и другую конфиденциальную информацию.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    int maxLines = 1,
    bool isPath = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                  fontFamily: isPath ? 'monospace' : null,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
