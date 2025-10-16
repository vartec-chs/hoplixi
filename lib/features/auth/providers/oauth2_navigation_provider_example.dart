/// Пример использования OAuth2NavigationProvider
///
/// Этот файл содержит примеры интеграции провайдера навигации OAuth2
/// в различные части приложения.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/services/cloud_sync_data_service.dart';
import 'package:hoplixi/features/auth/models/auth_client_config.dart';
import 'package:hoplixi/features/auth/providers/oauth2_account_provider.dart';
import 'package:hoplixi/features/auth/providers/oauth2_navigation_provider.dart';

/// Пример 1: Использование в кнопке авторизации
class OAuth2AuthButtonExample extends ConsumerWidget {
  final AuthClientConfig config;

  const OAuth2AuthButtonExample({super.key, required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationNotifier = ref.read(oauth2NavigationProvider.notifier);
    final oauth2Service = ref.watch(oauth2AccountProvider);

    return ElevatedButton(
      onPressed: () async {
        // 1. Сохраняем текущий путь перед началом авторизации
        await navigationNotifier.saveCurrentPath();

        // 2. Выполняем авторизацию
        oauth2Service.when(
          data: (service) async {
            final result = await service.authorize(
              config,
              onError: (error) {
                // При ошибке возвращаемся на сохранённый путь
                navigationNotifier.restorePathOnError();
              },
            );

            if (result.success) {
              // При успехе возвращаемся на сохранённый путь
              await navigationNotifier.restorePathOnSuccess();
            } else {
              // При ошибке возвращаемся на сохранённый путь
              await navigationNotifier.restorePathOnError();
            }
          },
          loading: () {},
          error: (error, stack) {
            // При ошибке загрузки сервиса возвращаемся на сохранённый путь
            navigationNotifier.restorePathOnError();
          },
        );
      },
      child: const Text('Авторизоваться'),
    );
  }
}

/// Пример 2: Виджет с индикатором процесса авторизации
class OAuth2AuthStatusWidget extends ConsumerWidget {
  const OAuth2AuthStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(oauth2NavigationProvider);

    return navigationState.when(
      data: (state) {
        if (state.isAuthInProgress) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Выполняется авторизация...'),
            ],
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Ошибка: $error'),
    );
  }
}

/// Пример 3: Обёртка для экрана авторизации с автоматическим возвратом
class OAuth2AuthScreenWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const OAuth2AuthScreenWrapper({super.key, required this.child});

  @override
  ConsumerState<OAuth2AuthScreenWrapper> createState() =>
      _OAuth2AuthScreenWrapperState();
}

class _OAuth2AuthScreenWrapperState
    extends ConsumerState<OAuth2AuthScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Сохраняем путь при входе на экран авторизации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(oauth2NavigationProvider.notifier).saveCurrentPath();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Пример 4: Хелпер-функция для упрощённой авторизации
Future<ServiceResult<String>> authorizeWithNavigation({
  required WidgetRef ref,
  required AuthClientConfig config,
  String? defaultReturnPath,
}) async {
  final navigationNotifier = ref.read(oauth2NavigationProvider.notifier);
  final oauth2Service = await ref.read(oauth2AccountProvider.future);

  // Сохраняем текущий путь
  await navigationNotifier.saveCurrentPath();

  try {
    // Выполняем авторизацию
    final result = await oauth2Service.authorize(
      config,
      onError: (error) async {
        // При ошибке возвращаемся на сохранённый путь или дефолтный
        await navigationNotifier.restorePathOrDefault(
          defaultPath: defaultReturnPath,
        );
      },
    );

    // Обрабатываем результат
    if (result.success) {
      // При успехе возвращаемся на сохранённый путь
      await navigationNotifier.restorePathOnSuccess();
    } else {
      // При ошибке возвращаемся на сохранённый путь или дефолтный
      await navigationNotifier.restorePathOrDefault(
        defaultPath: defaultReturnPath,
      );
    }

    return result;
  } catch (e) {
    // При исключении возвращаемся на сохранённый путь или дефолтный
    await navigationNotifier.restorePathOrDefault(
      defaultPath: defaultReturnPath,
    );
    rethrow;
  }
}
