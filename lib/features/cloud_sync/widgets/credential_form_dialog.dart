import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';
import 'package:hoplixi/features/cloud_sync/providers/credential_provider.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/features/global/widgets/text_field.dart';

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
  late TextEditingController _redirectUriController;
  late DateTime _expiresAt;
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
    _redirectUriController = TextEditingController(
      text: widget.credential?.redirectUri ?? '',
    );
    _expiresAt =
        widget.credential?.expiresAt ??
        DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _redirectUriController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.credential != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEditing
                        ? 'Редактировать учётные данные'
                        : 'Добавить учётные данные',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  _buildTypeSelector(),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _redirectUriController,
                    label: 'Redirect URI',
                    hint: 'Введите Redirect URI',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Обязательное поле';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDatePicker(context),
                  const SizedBox(height: 24),
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
                        onPressed: _isSubmitting ? null : _handleSubmit,
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
      value: _selectedType,
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
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: primaryInputDecoration(
        context,
        labelText: label,
        hintText: hint,
      ),
      obscureText: obscureText,
      validator: validator,
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: primaryInputDecoration(context, labelText: 'Срок действия'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_expiresAt.day.toString().padLeft(2, '0')}.${_expiresAt.month.toString().padLeft(2, '0')}.${_expiresAt.year}',
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (picked != null) {
      setState(() {
        _expiresAt = picked;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    bool success;

    if (_isEditing) {
      final updated = widget.credential!.copyWith(
        type: _selectedType,
        clientId: _clientIdController.text.trim(),
        clientSecret: _clientSecretController.text.trim(),
        redirectUri: _redirectUriController.text.trim(),
        expiresAt: _expiresAt,
      );
      success = await ref
          .read(credentialListProvider.notifier)
          .updateCredential(updated);
    } else {
      success = await ref
          .read(credentialListProvider.notifier)
          .createCredential(
            type: _selectedType,
            clientId: _clientIdController.text.trim(),
            clientSecret: _clientSecretController.text.trim(),
            redirectUri: _redirectUriController.text.trim(),
            expiresAt: _expiresAt,
          );
    }

    setState(() {
      _isSubmitting = false;
    });

    if (mounted && success) {
      Navigator.of(context).pop(true);
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
      case CredentialOAuthType.other:
        return Icons.cloud_outlined;
    }
  }
}
