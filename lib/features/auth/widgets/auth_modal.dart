import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/app/router/routes_path.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/providers/auth_clients_provider.dart';
import 'package:hoplixi/features/auth/providers/authorization_notifier_provider.dart';

/// Вспомогательная функция для показа модального окна
/// Принимает returnPath - путь для возврата после авторизации
/// Возвращает ключ клиента или null, если отменено
Future<String?> showNewAuthModal(
  BuildContext context, {
  required String returnPath,
}) async {
  return await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AuthModal(returnPath: returnPath),
  );
}

/// Модальное окно для выбора OAuth провайдера и авторизации
class AuthModal extends ConsumerStatefulWidget {
  final String returnPath;

  const AuthModal({super.key, required this.returnPath});

  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends ConsumerState<AuthModal> {
  final Map<AuthClientType, bool> _loadedButtons = {};

  @override
  void initState() {
    super.initState();
    _startLoadingButtons();
  }

  /// Постепенная загрузка кнопок
  void _startLoadingButtons() {
    final types = AuthClientType.values;
    int index = 0;

    void loadNext() {
      if (index < types.length && mounted) {
        setState(() {
          _loadedButtons[types[index]] = true;
        });
        index++;
        Future.delayed(const Duration(milliseconds: 150), loadNext);
      }
    }

    Future.delayed(const Duration(milliseconds: 100), loadNext);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final credentialsAsync = ref.watch(authClientsListProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_sync,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Выберите провайдера',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Для синхронизации данных',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Закрыть',
                  ),
                ],
              ),
            ),

            // Список провайдеров
            Flexible(
              child: credentialsAsync.when(
                data: (credentials) {
                  if (credentials.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  final credentialsByType =
                      <AuthClientType, List<AuthClientConfig>>{};
                  for (final credential in credentials) {
                    credentialsByType
                        .putIfAbsent(credential.type, () => [])
                        .add(credential);
                  }

                  return _buildProvidersList(context, credentialsByType);
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => _buildErrorState(context, error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersList(
    BuildContext context,
    Map<AuthClientType, List<AuthClientConfig>> credentialsByType,
  ) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      children: AuthClientType.values.map((type) {
        final credentials = credentialsByType[type] ?? [];
        final isLoaded = _loadedButtons[type] ?? false;
        final hasCredentials = credentials.isNotEmpty;

        if (!hasCredentials) {
          return const SizedBox.shrink();
        }

        return AnimatedOpacity(
          opacity: isLoaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedSlide(
            offset: isLoaded ? Offset.zero : const Offset(0, 0.2),
            duration: const Duration(milliseconds: 300),
            child: _buildProviderCard(context, type, credentials),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    AuthClientType type,
    List<AuthClientConfig> credentials,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => _handleProviderSelection(context, type, credentials),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _getProviderIcon(type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.name.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${credentials.length} ${_pluralizeCredentials(credentials.length)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text('Нет доступных провайдеров', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Добавьте учетные данные провайдера в настройках',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Ошибка загрузки', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(error.toString(), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Future<void> _handleProviderSelection(
    BuildContext context,
    AuthClientType type,
    List<AuthClientConfig> credentials,
  ) async {
    AuthClientConfig? selectedCredential;

    if (credentials.length == 1) {
      selectedCredential = credentials.first;
    } else {
      selectedCredential = await _showCredentialPicker(context, credentials);
    }

    if (selectedCredential == null) return;

    // Закрываем модальное окно
    if (!mounted) return;
    Navigator.of(context).pop();

    // Переходим на экран прогресса авторизации
    if (!mounted) return;
    context.go(AppRoutes.authorizationProgress);

    // Запускаем процесс авторизации через провайдер
    // Делаем это ПОСЛЕ навигации, чтобы AuthorizationProgressScreen уже слушал изменения
    await Future.microtask(() {
      ref
          .read(authorizationProvider.notifier)
          .startAuthorization(
            credential: selectedCredential!,
            returnPath: widget.returnPath,
          );
    });
  }

  Future<AuthClientConfig?> _showCredentialPicker(
    BuildContext context,
    List<AuthClientConfig> credentials,
  ) async {
    return await showDialog<AuthClientConfig>(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(12),
        title: const Text('Выберите провайдера'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: credentials.map((credential) {
                return ListTile(
                  title: Text(credential.name),
                  subtitle: Text(_maskString(credential.clientId)),
                  onTap: () => Navigator.of(context).pop(credential),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Widget _getProviderIcon(AuthClientType type) {
    String assetName;
    Color? tintColor;
    bool preserveColor = false;

    switch (type) {
      case AuthClientType.google:
        assetName = 'assets/auth_img/google-color-svgrepo-com.svg';
        preserveColor = true;
        break;
      case AuthClientType.onedrive:
        assetName = 'assets/auth_img/microsoft-svgrepo-com.svg';
        tintColor = Colors.lightBlue;
        break;
      case AuthClientType.dropbox:
        assetName = 'assets/auth_img/dropbox-color-svgrepo-com.svg';
        preserveColor = true;
        break;
      case AuthClientType.icloud:
        assetName = 'assets/auth_img/microsoft-svgrepo-com.svg';
        tintColor = Colors.cyan;
        break;
      case AuthClientType.yandex:
        assetName = 'assets/auth_img/yandex-ru-svgrepo-com.svg';
        preserveColor = true;
        break;
      case AuthClientType.other:
        assetName = 'assets/auth_img/microsoft-svgrepo-com.svg';
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
          colorFilter: preserveColor
              ? null
              : ColorFilter.mode(
                  tintColor ?? Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  String _pluralizeCredentials(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'credential';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'credentials';
    } else {
      return 'credentials';
    }
  }

  String _maskString(String value) {
    if (value.length <= 8) {
      return '${value.substring(0, 2)}***';
    }
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }
}
