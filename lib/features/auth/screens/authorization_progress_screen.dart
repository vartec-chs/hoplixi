import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/auth/models/auth_state.dart';
import 'package:hoplixi/features/auth/providers/authorization_notifier_provider.dart';
import 'package:hoplixi/shared/widgets/button.dart';

/// Экран прогресса авторизации
class AuthorizationProgressScreen extends ConsumerStatefulWidget {
  const AuthorizationProgressScreen({super.key});

  @override
  ConsumerState<AuthorizationProgressScreen> createState() =>
      _AuthorizationProgressScreenState();
}

class _AuthorizationProgressScreenState
    extends ConsumerState<AuthorizationProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authorizationProvider);

    // Слушаем изменения состояния авторизации
    // ref.listen ДОЛЖЕН быть вызван внутри build()
    ref.listen<AuthState>(authorizationProvider, (previous, next) {
      if (!mounted) return;

      next.when(
        idle: () {
          // Если вернулись в idle, возвращаемся назад
          if (context.canPop()) {
            context.pop();
          }
        },
        validatingToken: (_, __) {
          // Валидация токена в процессе
        },
        authorizing: (_, __, ___) {
          // Авторизация в процессе
        },
        success: (clientKey, returnPath) {
          // Успешная авторизация - переходим на returnPath
          ToastHelper.success(
            title: 'Авторизация успешна',
            description: 'Вы успешно авторизовались',
          );

          // Сбрасываем состояние
          ref.read(authorizationProvider.notifier).reset();

          if (context.canPop()) {
            context.pop();
          } else {
            context.go(returnPath);
          }

          // Переходим на целевой путь
        },
        failure: (error, credential, returnPath) {
          // Ошибка авторизации - показываем сообщение
          ToastHelper.error(title: 'Ошибка авторизации', description: error);

          // Остаемся на экране, чтобы пользователь мог повторить или вернуться
        },
        cancelled: (returnPath) {
          // Авторизация отменена - возвращаемся на returnPath
          ToastHelper.info(
            title: 'Авторизация отменена',
            description: 'Вы отменили процесс авторизации',
          );

          if (context.canPop()) {
            context.pop();
          } else {
            context.go(returnPath);
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: authState.when(
                idle: () => _buildIdleState(theme),
                validatingToken: (credential, returnPath) =>
                    _buildValidatingState(theme, credential.type.name),
                authorizing: (credential, returnPath, message) =>
                    _buildAuthorizingState(
                      theme,
                      credential.type.name,
                      message,
                    ),
                success: (clientKey, returnPath) => _buildSuccessState(theme),
                failure: (error, credential, returnPath) =>
                    _buildFailureState(theme, error, credential.type.name),
                cancelled: (returnPath) => _buildCancelledState(theme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdleState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline,
          size: 64,
          color: theme.colorScheme.primary.withOpacity(0.5),
        ),
        const SizedBox(height: 24),
        Text(
          'Ожидание авторизации',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildValidatingState(ThemeData theme, String providerName) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          'Проверка токена',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Проверяем существующий токен для $providerName...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        _buildCancelButton(theme),
      ],
    );
  }

  Widget _buildAuthorizingState(
    ThemeData theme,
    String providerName,
    String? message,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          strokeWidth: 3,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          'Авторизация',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          message ?? 'Выполняется авторизация через $providerName...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Пожалуйста, завершите авторизацию в браузере',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        _buildCancelButton(theme),
      ],
    );
  }

  Widget _buildSuccessState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
        const SizedBox(height: 24),
        Text(
          'Авторизация успешна!',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Перенаправление...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFailureState(
    ThemeData theme,
    String error,
    String providerName,
  ) {
    final authState = ref.watch(authorizationProvider);
    final returnPath = authState.maybeWhen(
      failure: (_, __, path) => path,
      orElse: () => '/',
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 24),
        Text(
          'Ошибка авторизации',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.error,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: SmoothButton(
                label: 'Назад',
                onPressed: () async {
                  // Сбрасываем состояние и возвращаемся на returnPath
                  ref.read(authorizationProvider.notifier).reset();
                  context.go(returnPath);
                },
                icon: const Icon(Icons.arrow_back),
                type: SmoothButtonType.outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SmoothButton(
                label: 'Повторить',
                onPressed: () {
                  ref.read(authorizationProvider.notifier).retry();
                },
                icon: const Icon(Icons.refresh),
                type: SmoothButtonType.filled,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelledState(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cancel_outlined,
          size: 64,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(height: 24),
        Text(
          'Авторизация отменена',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Возврат назад...',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCancelButton(ThemeData theme) {
    return SmoothButton(
      label: 'Отменить',
      onPressed: () async {
        await ref.read(authorizationProvider.notifier).cancel();
      },
      icon: const Icon(Icons.close),
      type: SmoothButtonType.outlined,
    );
  }
}
