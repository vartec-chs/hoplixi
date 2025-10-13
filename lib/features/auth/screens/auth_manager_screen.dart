import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/models/credential_app.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';
import 'package:hoplixi/features/auth/widgets/credential_picker.dart';
import 'package:hoplixi/shared/widgets/button.dart';

/// Экран для добавления OAuth авторизаций
class AuthManagerScreen extends ConsumerStatefulWidget {
  const AuthManagerScreen({super.key});

  @override
  ConsumerState<AuthManagerScreen> createState() => _AuthManagerScreenState();
}

class _AuthManagerScreenState extends ConsumerState<AuthManagerScreen> {
  CredentialApp? _selectedCredential;
  bool _isAuthorizing = false;
  String? _authResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountServiceAsync = ref.watch(oauth2AccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить авторизацию')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),

          child: Column(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Информационная карточка
              _buildInfoCard(theme),

              // Выбор credential
              _buildCredentialSelector(),

              // Информация о выбранном credential
              if (_selectedCredential != null) ...[
                _buildSelectedCredentialInfo(theme),
              ],

              // Кнопка авторизации
              accountServiceAsync.when(
                data: (service) => _buildAuthButton(service),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildErrorWidget(theme, error),
              ),

              // Результат авторизации
              if (_authResult != null) ...[_buildResultCard(theme)],

              // Список активных авторизаций
              _buildActiveAuthsList(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Авторизация облачного хранилища',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Выберите учётные данные OAuth и выполните авторизацию для синхронизации данных с облачным хранилищем.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialSelector() {
    return CredentialPicker(
      selected: _selectedCredential,
      onSelect: (credential) {
        setState(() {
          _selectedCredential = credential;
          _authResult = null;
        });
      },
      labelText: 'Учётные данные OAuth',
      hintText: 'Выберите учётные данные',
      enabled: !_isAuthorizing,
      onlyActive: true,
    );
  }

  Widget _buildSelectedCredentialInfo(ThemeData theme) {
    final credential = _selectedCredential!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getProviderIcon(credential.type, theme),
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
                      Text(
                        credential.type.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton(OAuth2AccountService service) {
    final canAuthorize = _selectedCredential != null && !_isAuthorizing;

    return SmoothButton(
      label: 'Авторизовать',
      onPressed: canAuthorize ? () => _handleAuthorization(service) : null,
      loading: _isAuthorizing,
      icon: const Icon(Icons.login),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, Object error) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Не удалось загрузить OAuth сервис: ${error.toString()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final isSuccess = _authResult != null && !_authResult!.startsWith('Ошибка');

    return Card(
      elevation: 0,
      color: isSuccess
          ? theme.colorScheme.primaryContainer
          : Colors.redAccent.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? theme.colorScheme.primary : Colors.redAccent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _authResult!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSuccess
                      ? theme.colorScheme.onPrimaryContainer
                      : Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAuthsList(ThemeData theme) {
    final accountServiceAsync = ref.watch(oauth2AccountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Активные клиенты',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        accountServiceAsync.when(
          data: (service) {
            final clients = service.clients;
            if (clients.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Нет активных авторизаций',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: clients.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      Icons.cloud_done,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(entry.key),
                    subtitle: const Text('Авторизован'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _handleRemoveAuth(entry.key),
                      color: theme.colorScheme.error,
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Не удалось загрузить список авторизаций',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleAuthorization(OAuth2AccountService service) async {
    if (_selectedCredential == null) return;

    setState(() {
      _isAuthorizing = true;
      _authResult = null;
    });

    try {
      final result = await service.authorize(
        _selectedCredential!,
        onError: (error) {
          if (mounted) {
            setState(() {
              _isAuthorizing = false;
              _authResult = 'Ошибка: $error';
            });
          }
          logError(
            'Ошибка авторизации OAuth',
            error: error,
            tag: 'AuthManagerScreen',
          );
        },
      );

      if (!mounted) return;

      setState(() {
        _isAuthorizing = false;
        if (result.success) {
          _authResult = 'Авторизация успешно выполнена! Ключ: ${result.data}';
          ToastHelper.success(title: 'Авторизация успешна');
        } else {
          _authResult = 'Ошибка: ${result.message}';
          ToastHelper.error(
            title: 'Ошибка авторизации',
            description: result.message,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAuthorizing = false;
        _authResult = 'Ошибка: ${e.toString()}';
      });

      ToastHelper.error(title: 'Ошибка авторизации', description: e.toString());
    }
  }

  Future<void> _handleRemoveAuth(String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить авторизацию'),
        content: Text('Вы действительно хотите удалить авторизацию "$key"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final accountService = await ref.read(oauth2AccountProvider.future);
      accountService.clients.remove(key);
      setState(() {});
      if (mounted) {
        ToastHelper.success(title: 'Авторизация удалена');
      }
    }
  }

  Widget _getProviderIcon(CredentialOAuthType type, ThemeData theme) {
    IconData icon;
    Color color;

    switch (type) {
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
      case CredentialOAuthType.yandex:
        icon = Icons.cloud_sync;
        color = Colors.orange;
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

  String _maskString(String value) {
    if (value.length <= 8) {
      return '${value.substring(0, 2)}***';
    }
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
}
