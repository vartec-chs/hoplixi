import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/providers/auth_clients_provider.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/auth/services/oauth2_account_service.dart';

/// Модальное окно для выбора OAuth провайдера и авторизации
class AuthModal extends ConsumerStatefulWidget {
  const AuthModal({super.key});

  @override
  ConsumerState<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends ConsumerState<AuthModal> {
  final Map<AuthClientType, bool> _loadedButtons = {};
  bool _isAuthorizing = false;
  AuthClientType? _authorizingType;

  @override
  void initState() {
    super.initState();
    _startLoadingButtons();
  }

  /// Постепенная загрузка кнопок
  void _startLoadingButtons() {
    final types = AuthClientType.values;
    int index = 0;

    // Загружаем кнопки по одной с анимацией
    void loadNext() {
      if (index < types.length && mounted) {
        setState(() {
          _loadedButtons[types[index]] = true;
        });
        index++;
        Future.delayed(const Duration(milliseconds: 150), loadNext);
      }
    }

    // Начинаем загрузку после небольшой задержки
    Future.delayed(const Duration(milliseconds: 100), loadNext);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final credentialsAsync = ref.watch(authClientsListProvider);
    final accountServiceAsync = ref.watch(oauth2AccountProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.cloud, color: theme.colorScheme.primary, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Выберите провайдер',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isAuthorizing
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Список провайдеров
            Flexible(
              child: credentialsAsync.when(
                data: (credentials) {
                  if (credentials.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // Группируем credentials по типам
                  final credentialsByType =
                      <AuthClientType, List<AuthClientConfig>>{};
                  for (final cred in credentials) {
                    credentialsByType
                        .putIfAbsent(cred.type, () => [])
                        .add(cred);
                  }

                  return accountServiceAsync.when(
                    data: (service) => _buildProvidersList(
                      context,
                      credentialsByType,
                      service,
                    ),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => _buildErrorState(context, error),
                  );
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
    OAuth2AccountService service,
  ) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      children: AuthClientType.values.map((type) {
        final credentials = credentialsByType[type] ?? [];
        final isLoaded = _loadedButtons[type] ?? false;
        final hasCredentials = credentials.isNotEmpty;

        // Показываем только провайдеры с credentials
        if (!hasCredentials) {
          return const SizedBox.shrink();
        }

        return AnimatedOpacity(
          opacity: isLoaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedSlide(
            offset: isLoaded ? Offset.zero : const Offset(0, 0.2),
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProviderCard(context, type, credentials, service),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    AuthClientType type,
    List<AuthClientConfig> credentials,
    OAuth2AccountService service,
  ) {
    final theme = Theme.of(context);
    final isAuthorizing = _isAuthorizing && _authorizingType == type;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: isAuthorizing || _isAuthorizing
            ? null
            : () => _handleAuthorization(context, type, credentials, service),
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
                      type.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${credentials.length} ${_pluralizeCredentials(credentials.length)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isAuthorizing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
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
            'Сначала добавьте учётные данные OAuth',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
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
          Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('Ошибка загрузки', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _handleAuthorization(
    BuildContext context,
    AuthClientType type,
    List<AuthClientConfig> credentials,
    OAuth2AccountService service,
  ) async {
    // Если несколько credentials для этого типа, показываем выбор
    AuthClientConfig? selectedCredential;

    if (credentials.length == 1) {
      selectedCredential = credentials.first;
    } else {
      selectedCredential = await _showCredentialPicker(context, credentials);
    }

    if (selectedCredential == null) return;

    setState(() {
      _isAuthorizing = true;
      _authorizingType = type;
    });

    try {
      final result = await service.authorize(
        selectedCredential,
        onError: (error) {
          logError('OAuth authorization error', error: error, tag: 'AuthModal');
          if (!mounted) return;

          ToastHelper.error(
            title: 'Ошибка авторизации',
            description: error.toString(),
          );

          setState(() {
            _isAuthorizing = false;
            _authorizingType = null;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _isAuthorizing = false;
        _authorizingType = null;
      });

      if (result.success) {
        Navigator.of(context).pop(result.data);
        ToastHelper.success(
          title: 'Авторизация успешна',
          description: 'Ключ: ${result.data}',
        );
      } else {
        ToastHelper.error(
          title: 'Ошибка авторизации',
          description: result.message,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAuthorizing = false;
        _authorizingType = null;
      });

      ToastHelper.error(title: 'Ошибка авторизации', description: e.toString());
    }
  }

  Future<AuthClientConfig?> _showCredentialPicker(
    BuildContext context,
    List<AuthClientConfig> credentials,
  ) async {
    return await showDialog<AuthClientConfig>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите учётные данные'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: credentials.length,
            itemBuilder: (context, index) {
              final credential = credentials[index];
              return ListTile(
                title: Text(credential.name),
                subtitle: Text(
                  'ID: ${_maskString(credential.clientId)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => Navigator.of(context).pop(credential),
              );
            },
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
    // Map each provider type to an SVG asset and whether it should be tinted.
    String assetName;
    Color? tintColor;
    bool preserveColor = false;

    switch (type) {
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

/// Вспомогательная функция для показа модального окна
Future<String?> showAuthModal(BuildContext context) async {
  return await showDialog<String>(
    context: context,
    builder: (context) => const AuthModal(),
  );
}
