import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_transitions/go_transitions.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/route_observer.dart';
import 'package:hoplixi/core/secure_storage/index.dart';
import 'package:hoplixi/features/titlebar/titlebar.dart';
import 'package:hoplixi/global.dart';
import 'package:universal_platform/universal_platform.dart';

import 'routes_path.dart';
import 'routes.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    navigatorKey: navigatorKey, // Устанавливаем глобальный navigatorKey

    observers: [GoTransition.observer, LoggingRouteObserver()],
    redirect: (context, state) async {
      final initializationAsync = ref.watch(storageInitProvider);

      // final prefs = await SharedPreferences.getInstance();
      // final isFirstRun = prefs.getBool('is_first_run') ?? true;

      // // Если это первый запуск и пользователь не на setup экране
      // if (isFirstRun && state.fullPath != '/setup') {
      //   return '/setup';
      // }

      // // Если настройка завершена и пользователь на setup экране
      // if (!isFirstRun && state.fullPath == '/setup') {
      //   return '/';
      // }

      initializationAsync.when(
        data: (data) {
          return null; // Нет перенаправления, если инициализация успешна
        },
        error: (error, stack) {
          // Если произошла ошибка, перенаправляем на экран ошибки
          if (state.fullPath != '/error') {
            return '/error';
          }
          logError('Initialization error', error: error, stackTrace: stack);
          return null; // Уже на экране ошибки, не перенаправляем
        },
        loading: () {
          return '/loading'; // Перенаправление на страницу загрузки
        },
      );

      return null;
    },
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
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Oops! Something went wrong.'),
            SizedBox(width: 8),
            Text(state.error.toString()),
          ],
        ),
      ),
    ),
  );
});

void navigateBack(BuildContext context) {
  GoRouter.of(context).go(AppRoutes.home);
}
