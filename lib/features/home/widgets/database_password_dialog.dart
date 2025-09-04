import 'package:flutter/material.dart';
import 'package:hoplixi/common/index.dart';
import 'package:hoplixi/hoplixi_store/models/database_entry.dart';
import 'package:hoplixi/common/button.dart';

/// Результат модального окна ввода пароля
class PasswordDialogResult {
  final String password;
  final bool savePassword;

  const PasswordDialogResult({
    required this.password,
    required this.savePassword,
  });
}

/// Модальное окно для ввода мастер-пароля
class DatabasePasswordDialog extends StatefulWidget {
  final DatabaseEntry database;

  const DatabasePasswordDialog({required this.database, super.key});

  /// Показать диалог и получить результат
  static Future<PasswordDialogResult?> show(
    BuildContext context,
    DatabaseEntry database,
  ) {
    return showDialog<PasswordDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DatabasePasswordDialog(database: database),
    );
  }

  @override
  State<DatabasePasswordDialog> createState() => _DatabasePasswordDialogState();
}

class _DatabasePasswordDialogState extends State<DatabasePasswordDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _savePassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.key, color: colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Введите мастер-пароль',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о базе данных
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.database.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.database.description?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.database.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Поле ввода пароля
            // TextFormField(
            //   controller: _passwordController,
            //   obscureText: _obscurePassword,
            //   autofocus: true,
            //   enabled: !_isLoading,
            //   decoration: InputDecoration(
            //     labelText: 'Мастер-пароль',
            //     hintText: 'Введите пароль для открытия базы данных',
            //     prefixIcon: const Icon(Icons.lock),
            //     suffixIcon: IconButton(
            //       icon: Icon(
            //         _obscurePassword ? Icons.visibility : Icons.visibility_off,
            //       ),
            //       onPressed: () {
            //         setState(() {
            //           _obscurePassword = !_obscurePassword;
            //         });
            //       },
            //     ),
            //     border: const OutlineInputBorder(),
            //   ),
            //   validator: (value) {
            //     if (value == null || value.trim().isEmpty) {
            //       return 'Пароль не может быть пустым';
            //     }
            //     if (value.length < 3) {
            //       return 'Пароль слишком короткий';
            //     }
            //     return null;
            //   },
            //   onFieldSubmitted: (_) => _handleSubmit(),
            // ),
            CustomPasswordField(
              label: 'Мастер-пароль',
              controller: _passwordController,
              autofocus: true,
              enabled: !_isLoading,

              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пароль не может быть пустым';
                }
                if (value.length < 3) {
                  return 'Пароль слишком короткий';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleSubmit(),
              hintText: 'Введите пароль для открытия базы данных',
            ),

            const SizedBox(height: 16),

            // Чекбокс для сохранения пароля
            CheckboxListTile(
              value: _savePassword,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _savePassword = value ?? false;
                      });
                    },
              title: Text(
                'Сохранить пароль',
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                'Пароль будет зашифрован и сохранен для автоматического входа',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        // Кнопка отмены
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),

        // Кнопка открытия
        SmoothButton(
          onPressed: _isLoading ? null : _handleSubmit,
          label: 'Открыть',
          icon: const Icon(Icons.lock_open, size: 18),
          loading: _isLoading,
        ),
      ],
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim();
    final result = PasswordDialogResult(
      password: password,
      savePassword: _savePassword,
    );

    Navigator.of(context).pop(result);
  }
}
