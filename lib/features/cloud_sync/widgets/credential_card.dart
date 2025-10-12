import 'package:flutter/material.dart';
import 'package:hoplixi/features/cloud_sync/models/credential_app.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:intl/intl.dart';

class CredentialCard extends StatelessWidget {
  final CredentialApp credential;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CredentialCard({
    super.key,
    required this.credential,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = credential.expiresAt.isBefore(DateTime.now());
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildIcon(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential.type.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isExpired)
                          Text(
                            'Истёк',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
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
              _buildInfoRow(
                context,
                'Redirect URI Mobile',
                AuthConstants.redirectUriMobile,
                selectable: true,
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                context,
                'Redirect URI Desktop',
                AuthConstants.redirectUriDesktop,
                selectable: true,
              ),
              const SizedBox(height: 4),
              _buildInfoRow(
                context,
                'Истекает',
                DateFormat('dd.MM.yyyy HH:mm').format(credential.expiresAt),
                isWarning: isExpired,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (credential.type) {
      case CredentialOAuthType.google:
        icon = Icons.cloud;
        color = Colors.blue;
        break;
      case CredentialOAuthType.onedrive:
        icon = Icons.cloud_circle;
        color = Colors.lightBlue;
        break;
      case CredentialOAuthType.dropbox:
        icon = Icons.cloud_queue;
        color = Colors.indigo;
        break;
      case CredentialOAuthType.icloud:
        icon = Icons.cloud_done;
        color = Colors.cyan;
        break;
      case CredentialOAuthType.other:
        icon = Icons.cloud_outlined;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 28),
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
