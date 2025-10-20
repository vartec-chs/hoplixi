/// Библиотека провайдеров для роутера
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_transitions/go_transitions.dart';
import 'package:hoplixi/app/router/router_refresh_provider.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/route_observer.dart';
import 'package:hoplixi/core/providers/app_close_provider.dart';
import 'package:hoplixi/features/auth/models/auth_state.dart';
import 'package:hoplixi/features/auth/providers/authorization_notifier_provider.dart';
import 'package:hoplixi/features/cloud_sync/widgets/export_progress_overlay.dart';

import 'package:hoplixi/features/global/screens/error_screen.dart';
import 'package:hoplixi/features/titlebar/titlebar.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';

import 'package:universal_platform/universal_platform.dart';

import 'routes_path.dart';
import 'routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    navigatorKey: navigatorKey, // Устанавливаем глобальный navigatorKey
    observers: [GoTransition.observer, LoggingRouteObserver()],
    refreshListenable: ref.watch(routerRefreshProvider.notifier),

    redirect: (context, state) {
      // log current path for debugging
      logInfo('Current path: ${state.fullPath}', tag: 'GoRouterPath');
      final dbState = ref.read(hoplixiStoreProvider).asData?.value;
      final databaseLocked = ref.read(databaseLockedProvider);
      final dataCleared = ref.read(dataClearedProvider);

      // Проверяем, идет ли процесс авторизации или есть ошибка
      final authState = ref.read(authorizationProvider);
      final isAuthorizing = authState.isLoading;
      final hasAuthError = authState.maybeWhen(
        failure: (_, __, ___) => true,
        orElse: () => false,
      );

      // Если идет авторизация или есть ошибка, и мы не на экране авторизации - блокируем переход
      if ((isAuthorizing || hasAuthError) &&
          state.matchedLocation != AppRoutes.authorizationProgress) {
        logInfo(
          'Блокировка навигации - идет процесс авторизации или есть ошибка',
          tag: 'GoRouter',
          data: {'currentPath': state.fullPath, 'hasError': hasAuthError},
        );
        return AppRoutes.authorizationProgress;
      } else if (!isAuthorizing &&
          !hasAuthError &&
          state.matchedLocation == AppRoutes.authorizationProgress) {
        // Если авторизация завершена и мы на экране авторизации - возвращаем назад
        logInfo(
          'Авторизация завершена, возвращаемся с экрана авторизации',
          tag: 'GoRouter',
          data: {'currentPath': state.fullPath},
        );
        return authState.returnPath; // GoRouter вернет нас назад автоматически
      }

      // Если база данных заблокирована (проверяем по флагу из lifecycle), перенаправляем на экран блокировки
      if (databaseLocked == true &&
          state.matchedLocation != AppRoutes.lockedDb) {
        logInfo(
          'База данных заблокирована (lifecycle), перенаправляем на экран блокировки',
          tag: 'GoRouter',
          data: {'currentPath': state.fullPath},
        );

        return AppRoutes.lockedDb;
      }

      // Альтернативная проверка по состоянию БД
      if (dbState?.isLocked == true &&
          state.matchedLocation != AppRoutes.lockedDb &&
          databaseLocked == false) {
        logInfo(
          'База данных заблокирована (dbState), перенаправляем на экран блокировки',
          tag: 'GoRouter',
          data: {'currentPath': state.fullPath},
        );

        return AppRoutes.lockedDb;
      }

      // Если данные были очищены, перенаправляем на home
      if (dataCleared == true) {
        logInfo(
          'Данные очищены, перенаправляем на home',
          tag: 'GoRouter',
          data: {'currentPath': state.fullPath},
        );

        ref.read(appLifecycleProvider.notifier).cleanup();

        return AppRoutes.home;
      }

      return null;
    },
    routes: UniversalPlatform.isDesktop
        ? [
            ShellRoute(
              builder: (context, state, child) {
                return ExportProgressOverlay(
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          SizedBox(height: 40),
                          // TitleBar(),
                          Expanded(child: child),
                        ],
                      ),
                      Positioned(top: 0, left: 0, right: 0, child: TitleBar()),
                      Consumer(
                        builder: (context, ref, _) {
                          final appCloseState = ref.watch(appCloseProvider);
                          if (appCloseState.value == AppCloseState.closing) {
                            return Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text(
                                      'Закрытие приложения...',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                );
              },
              routes: appRoutes,
            ),
          ]
        : [
            ShellRoute(
              builder: (context, state, child) {
                return ExportProgressOverlay(child: child);
              },
              routes: appRoutes,
            ),
          ],

    errorBuilder: (context, state) =>
        ErrorScreen(errorMessage: state.error.toString()),
  );

  ref.onDispose(() {
    router.dispose();
  });

  return router;
});

class ProtectedRoutes {
  static const List<String> routes = [
    AppRoutes.dashboard,
    AppRoutes.categoryManager,
    AppRoutes.tagsManager,
    AppRoutes.passwordForm,
    AppRoutes.passwordHistory,
    AppRoutes.universalFilterDemo,
    AppRoutes.notesForm,
    AppRoutes.otpForm,
    AppRoutes.importOtpCodes,
    AppRoutes.cloudSyncSetup,
    AppRoutes.passwordMigration,
    // Добавьте другие защищённые маршруты сюда
  ];
}

const beforeOpenDBPath = [
  AppRoutes.home,
  AppRoutes.createStore,
  AppRoutes.openStore,
  AppRoutes.splash,
  AppRoutes.setup,
];

const afterOpenDBPath = [
  AppRoutes.dashboard,
  AppRoutes.categoryManager,
  AppRoutes.tagsManager,
  AppRoutes.passwordForm,
];

void navigateBack(BuildContext context) {
  final path = GoRouter.of(context).state.path;
  if (GoRouter.of(context).canPop()) {
    context.pop();
  } else if (path != null && path.contains('dashboard')) {
    GoRouter.of(context).go(AppRoutes.dashboard);
  } else {
    GoRouter.of(context).go(AppRoutes.home);
  }
}
