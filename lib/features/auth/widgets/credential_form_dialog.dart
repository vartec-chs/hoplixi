import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/features/auth/models/credential_app.dart';
import 'package:hoplixi/features/auth/providers/credential_provider.dart';
import 'package:hoplixi/shared/widgets/button.dart';
import 'package:hoplixi/shared/widgets/text_field.dart';

class CredentialFormDialog extends ConsumerStatefulWidget {
  final CredentialApp? credential;

  const CredentialFormDialog({super.key, this.credential});

  @override
  ConsumerState<CredentialFormDialog> createState() =>
      _CredentialFormDialogState();
}

class _CredentialFormDialogState extends ConsumerState<CredentialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late CredentialOAuthType _selectedType;
  late TextEditingController _clientIdController;
  late TextEditingController _clientSecretController;
  late TextEditingController _nameController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.credential?.type ?? CredentialOAuthType.dropbox;
    _clientIdController = TextEditingController(
      text: widget.credential?.clientId ?? '',
    );
    _clientSecretController = TextEditingController(
      text: widget.credential?.clientSecret ?? '',
    );

    _nameController = TextEditingController(
      text: widget.credential?.name ?? '',
    );
  }

  bool _isValid = false;

  void _onChanged() {
    // Проверяем форму при каждом изменении
    final valid = _formKey.currentState?.validate() ?? false;
    if (valid != _isValid) {
      setState(() => _isValid = valid);
    }
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.credential != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              onChanged: _onChanged,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              key: _formKey,
              child: Column(
                spacing: 12,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? 'Редактировать учётные данные'
                        : 'Добавить учётные данные',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  _buildTypeSelector(),

                  _buildTextField(
                    controller: _nameController,
                    label: 'Название',
                    helpText: 'Имя приложения которого вы создали для OAuth',
                    hint: 'Например "Dropbox App"',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Обязательное поле';
                      }
                      return null;
                    },
                  ),

                  _buildTextField(
                    controller: _clientIdController,
                    label: 'Client ID',
                    hint: 'Введите Client ID',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Обязательное поле';
                      }
                      return null;
                    },
                  ),

                  _buildTextField(
                    controller: _clientSecretController,
                    label: 'Client Secret',
                    hint: 'Введите Client Secret',
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Обязательное поле';
                      }
                      return null;
                    },
                  ),

                  _buildReadOnlyField(
                    label: 'Redirect URI Mobile',
                    value: AuthConstants.redirectUriMobile,
                  ),

                  _buildReadOnlyField(
                    label: 'Redirect URI Desktop',
                    value: AuthConstants.redirectUriDesktop,
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SmoothButton(
                        label: 'Отмена',
                        onPressed: () => Navigator.of(context).pop(false),
                        type: SmoothButtonType.text,
                      ),
                      const SizedBox(width: 12),
                      SmoothButton(
                        label: _isEditing ? 'Сохранить' : 'Добавить',
                        onPressed: _isValid && !_isSubmitting
                            ? _handleSubmit
                            : null,
                        loading: _isSubmitting,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<CredentialOAuthType>(
      initialValue: _selectedType,
      decoration: primaryInputDecoration(context, labelText: 'Тип'),
      items: CredentialOAuthType.values
          .map(
            (type) => DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getTypeIcon(type), size: 20),
                  const SizedBox(width: 8),
                  Text(type.name),
                  if (!type.isActive) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(неактивен)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
          });
        }
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? helpText,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: primaryInputDecoration(
        context,
        labelText: label,
        hintText: hint,
      ).copyWith(helperText: helpText),
      obscureText: obscureText,
      validator: validator,
    );
  }

  Widget _buildReadOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SelectableText(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                onPressed: () => {
                  Clipboard.setData(ClipboardData(text: value)),
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Скопировано в буфер обмена'),
                      duration: Duration(seconds: 1),
                    ),
                  ),
                },
                icon: const Icon(Icons.copy, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Дополнительная валидация подключения для Dropbox

      bool success;

      if (_isEditing) {
        final updated = widget.credential!.copyWith(
          type: _selectedType,
          clientId: _clientIdController.text.trim(),
          clientSecret: _clientSecretController.text.trim(),
        );
        success = await ref
            .read(credentialListProvider.notifier)
            .updateCredential(updated);
      } else {
        success = await ref
            .read(credentialListProvider.notifier)
            .createCredential(
              name: _nameController.text.trim(),
              type: _selectedType,
              clientId: _clientIdController.text.trim(),
              clientSecret: _clientSecretController.text.trim(),
              
            );
      }

      if (mounted && success) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  IconData _getTypeIcon(CredentialOAuthType type) {
    switch (type) {
      case CredentialOAuthType.google:
        return Icons.cloud;
      case CredentialOAuthType.onedrive:
        return Icons.cloud_circle;
      case CredentialOAuthType.dropbox:
        return Icons.cloud_queue;
      case CredentialOAuthType.icloud:
        return Icons.cloud_done;
      case CredentialOAuthType.yandex:
        return Icons.cloud_sync;
      case CredentialOAuthType.other:
        return Icons.cloud_outlined;
    }
  }

  /// Валидация подключения к Dropbox
  // Future<bool> _validateDropboxConnection() async {
  //   try {
  //     // Создаем временный credential для проверки
  //     final tempCredential = CredentialApp(
  //       id: 'temp_validation',
  //       type: CredentialOAuthType.dropbox,
  //       clientId: _clientIdController.text.trim(),
  //       clientSecret: _clientSecretController.text.trim(),
  //       expiresAt: _expiresAt,
  //     );

  //     // Инициализируем Dropbox сервис
  //     final dropboxService = ref.read(dropboxServiceProvider);
  //     final initResult = await dropboxService.init(tempCredential);

  //     if (!initResult.success) {
  //       return false;
  //     }

  //     // Проверяем подключение (без полного OAuth flow)
  //     final checkResult = await dropboxService.check();
  //     return checkResult.success;
  //   } catch (e) {
  //     // В случае ошибки валидации считаем подключение невалидным
  //     return false;
  //   }
  // }
}
