import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';

class AuthClientCard extends StatelessWidget {
  final AuthClientConfig credential;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AuthClientCard({
    super.key,
    required this.credential,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: InkWell(
        onTap: credential.isBuiltin ? null : onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 4,
                children: [
                  _buildIcon(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              credential.type.name,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!credential.type.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Неактивен',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  if (credential.isBuiltin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Встроенный',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  if (!credential.isBuiltin)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: theme.colorScheme.error,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                'Client ID',
                _maskString(credential.clientId),
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                context,
                'Client Secret',
                _maskString(credential.clientSecret),
                selectable: true,
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    // Map each provider type to an SVG asset and whether it should be tinted.
    String assetName;
    Color? tintColor;
    bool preserveColor = false;

    switch (credential.type) {
      case AuthClientType.google:
        assetName = 'assets/auth_img/google-color-svgrepo-com.svg';
        preserveColor = true;
        tintColor = null;
        break;
      case AuthClientType.onedrive:
        assetName = 'assets/auth_img/microsoft-svgrepo-com.svg';
        preserveColor = false;
        tintColor = Colors.lightBlue;
        break;
      case AuthClientType.dropbox:
        assetName = 'assets/auth_img/dropbox-color-svgrepo-com.svg';
        preserveColor = true;
        tintColor = null;
        break;
      case AuthClientType.icloud:
        assetName = 'assets/auth_img/microsoft-svgrepo-com.svg';
        preserveColor = false;
        tintColor = Colors.cyan;
        break;
      case AuthClientType.yandex:
        assetName = 'assets/auth_img/yandex-ru-svgrepo-com.svg';
        preserveColor = true;
        tintColor = null;
        break;
      case AuthClientType.other:
        assetName = 'assets/auth_img/microsoft-svgrepo-com.svg';
        preserveColor = false;
        tintColor = Colors.grey;
        break;
    }

    final bgColor = (tintColor ?? Theme.of(context).colorScheme.surface)
        .withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: 28,
        height: 28,
        child: SvgPicture.asset(
          assetName,
          // If asset has its own colors (brand icons), don't override them.
          colorFilter: preserveColor
              ? null
              : ColorFilter.mode(
                  tintColor ?? Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isWarning = false,
    bool selectable = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(
          child: selectable
              ? SelectableText(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isWarning ? theme.colorScheme.error : null,
                    fontWeight: isWarning ? FontWeight.bold : null,
                  ),
                )
              : Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isWarning ? theme.colorScheme.error : null,
                    fontWeight: isWarning ? FontWeight.bold : null,
                  ),
                ),
        ),
      ],
    );
  }

  String _maskString(String value) {
    if (value.length <= 8) {
      return '${value.substring(0, 2)}***';
    }
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
}
