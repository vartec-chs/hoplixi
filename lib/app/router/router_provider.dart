/// Библиотека провайдеров для роутера
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_transitions/go_transitions.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/route_observer.dart';
import 'package:hoplixi/core/providers/notification_providers.dart';

import 'package:hoplixi/features/global/screens/error_screen.dart';
import 'package:hoplixi/features/titlebar/titlebar.dart';
import 'package:hoplixi/global_key.dart';
import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';
import 'package:hoplixi/app/router/router_refresh_provider.dart';

import 'package:universal_platform/universal_platform.dart';

import 'routes_path.dart';
import 'routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    navigatorKey: navigatorKey, // Устанавливаем глобальный navigatorKey
    observers: [GoTransition.observer, LoggingRouteObserver()],
    refreshListenable: ref.watch(routerRefreshProvider.notifier),

    redirect: (context, state) async {
      // final isDatabaseOpen = ref.watch(isDatabaseOpenProvider);
      final dataCleared = ref.watch(dataClearedProvider);

      // Если данные были очищены, перенаправляем на home
      if (dataCleared == true) {
        logInfo(
          'Данные очищены, перенаправляем на home',
          tag: 'GoRouter',
          data: {'currentPath': state.fullPath},
        );

        try {
          await ref
              .read(notificationProvider.notifier)
              .showSecurityAlert(
                'Безопасность',
                'Бд была автоматический закрыта из-за неактивности',
              );
        } catch (e) {
          logWarning('Не удалось отправить уведомление безопасности: $e');
        }

        ref.read(appLifecycleProvider.notifier).cleanup();

        return AppRoutes.home;
      }

      return null;
    },
    routes: UniversalPlatform.isDesktop
        ? [
            ShellRoute(
              builder: (context, state, child) {
                return Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(height: 40),
                        // TitleBar(),
                        Expanded(child: child),
                      ],
                    ),
                    Positioned(top: 0, left: 0, right: 0, child: TitleBar()),
                  ],
                );
              },
              routes: appRoutes,
            ),
          ]
        : appRoutes,

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
  if (GoRouter.of(context).canPop()) {
    context.pop();
  } else if (beforeOpenDBPath.contains(GoRouter.of(context).state.path)) {
    GoRouter.of(context).go(AppRoutes.home);
  } else {
    GoRouter.of(context).go(AppRoutes.dashboard);
  }
}
