import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store_control.dart';

/// Шаг 4: Подтверждение и создание хранилища
class Step4Confirmation extends ConsumerStatefulWidget {
  const Step4Confirmation({super.key});

  @override
  ConsumerState<Step4Confirmation> createState() => _Step4ConfirmationState();
}

class _Step4ConfirmationState extends ConsumerState<Step4Confirmation> {
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  bool _copyPasswordCheck = false;
  bool _copyPathCheck = false;

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createStoreControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          _buildSummaryCard(
            context,
            title: 'Название хранилища',
            value: formState.storeName.isNotEmpty
                ? formState.storeName
                : 'Не указано',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 12),
          if (formState.storeDescription.isNotEmpty)
            _buildSummaryCard(
              context,
              title: 'Описание',
              value: formState.storeDescription,
              icon: Icons.description_outlined,
            ),
          if (formState.storeDescription.isNotEmpty) const SizedBox(height: 12),
          _buildSummaryCard(
            context,
            title: 'Мастер-пароль',
            value: _showPassword
                ? formState.masterPassword
                : '•' * formState.masterPassword.length,
            icon: Icons.lock_outline,
            showActionIcon: true,
            actionIcon: _showPassword ? Icons.visibility_off : Icons.visibility,
            onActionPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
            action2Icon: _copyPasswordCheck ? Icons.check : Icons.copy,
            onAction2Pressed: () {
              setState(() {
                _copyPasswordCheck = true;
              });
              Clipboard.setData(ClipboardData(text: formState.masterPassword));
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    _copyPasswordCheck = false;
                  });
                }
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            context,
            title: 'Путь хранения',
            value: formState.useDefaultPath
                ? formState.defaultStoragePath ?? 'Путь по умолчанию'
                : formState.customStoragePath ?? 'Не выбран',
            icon: Icons.folder_outlined,
            showActionIcon: !formState.useDefaultPath,
            actionIcon: !formState.useDefaultPath && _copyPathCheck
                ? Icons.check
                : Icons.copy,
            onActionPressed: () {
              if (!formState.useDefaultPath &&
                  formState.customStoragePath != null) {
                setState(() {
                  _copyPathCheck = true;
                });
                Clipboard.setData(
                  ClipboardData(text: formState.customStoragePath!),
                );
               
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    setState(() {
                      _copyPathCheck = false;
                    });
                  }
                });
              }
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Убедитесь, что вы надежно сохранили мастер-пароль. Его восстановление невозможно!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Метод для валидации формы (вызывается извне)
  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    bool showActionIcon = false,
    IconData? actionIcon,
    IconData? action2Icon,
    VoidCallback? onAction2Pressed,
    VoidCallback? onActionPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              // color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (showActionIcon)
            IconButton(
              icon: Icon(actionIcon),
              onPressed: onActionPressed,
              tooltip: _showPassword ? 'Скрыть пароль' : 'Показать пароль',
            ),
          if (action2Icon != null && onAction2Pressed != null)
            IconButton(
              icon: Icon(action2Icon),
              onPressed: onAction2Pressed,
              tooltip: 'Дополнительное действие',
            ),
        ],
      ),
    );
  }
}
