import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_transitions/go_transitions.dart';
import 'package:hoplixi/core/app_preferences/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/route_observer.dart';
import 'package:hoplixi/providers/app_lifecycle_provider.dart';
import 'package:hoplixi/core/secure_storage/storage_service_locator.dart';
import 'package:hoplixi/features/titlebar/titlebar.dart';
import 'package:hoplixi/global.dart';
import 'package:hoplixi/router/router_refresh_provider.dart';

import 'package:universal_platform/universal_platform.dart';

import 'routes_path.dart';
import 'routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    navigatorKey: navigatorKey, // Устанавливаем глобальный navigatorKey

    observers: [GoTransition.observer, LoggingRouteObserver()],
    // refreshListenable: ref.watch(routerRefreshProvider.notifier),
    // redirect: (context, state) async {
    //   final initializationAsync = ref.watch(storageInitProvider);
    //   // final isDatabaseOpen = ref.watch(isDatabaseOpenProvider);
    //   final dataCleared = ref.watch(dataClearedProvider);

    //   // Если данные были очищены, перенаправляем на home
    //   if (dataCleared) {
    //     logInfo(
    //       'Данные очищены, перенаправляем на home',
    //       tag: 'GoRouter',
    //       data: {'currentPath': state.fullPath},
    //     );
    //     return AppRoutes.home;
    //   }

    //   bool? isFirstRun = Prefs.get<bool>(Keys.isFirstRun);
    //   if (isFirstRun == false && state.fullPath == AppRoutes.setup) {
    //     return AppRoutes
    //         .home; // Если настройка завершена, перенаправляем на домашний экран
    //   }

    //   // if (!isDatabaseOpen) {
    //   //   logInfo('No database is open');
    //   //   if (afterOpenDBPath.contains(state.path)) {
    //   //     return AppRoutes.home;
    //   //   }
    //   //   return null; // Нет перенаправления, если база данных не открыта
    //   // }

    //   initializationAsync.when(
    //     data: (data) {
    //       return null; // Нет перенаправления, если инициализация успешна
    //     },
    //     error: (error, stack) {
    //       // Если произошла ошибка, перенаправляем на экран ошибки
    //       if (state.fullPath != '/error') {
    //         return '/error';
    //       }
    //       logError('Initialization error', error: error, stackTrace: stack);
    //       return null; // Уже на экране ошибки, не перенаправляем
    //     },
    //     loading: () {
    //       return '/loading'; // Перенаправление на страницу загрузки
    //     },
    //   );

    //   return null;
    // },
    routes: UniversalPlatform.isDesktop
        ? [
            ShellRoute(
              builder: (context, state, child) {
                return Column(
                  children: [
                    TitleBar(),
                    Expanded(child: child),
                  ],
                );
              },
              routes: appRoutes,
            ),
          ]
        : appRoutes,

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: Text('Error'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_left),
            onPressed: () {
              navigateBack(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Упс! Произошла ошибка:'),
              SizedBox(width: 8),
              Text(state.error.toString()),
            ],
          ),
        ),
      ),
    ),
  );
});

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
