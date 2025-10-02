import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/constants/responsive_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/global/providers/app_lifecycle_provider.dart';

// import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/core/utils/toast/toast_manager.dart';
import 'package:hoplixi/router/router_provider.dart';
import 'package:hoplixi/core/utils/scaffold_messenger_manager/scaffold_messenger_manager.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Добавляем наблюдатель жизненного цикла
    WidgetsBinding.instance.addObserver(this);

    // Инициализируем ScaffoldMessengerManager
  }

  @override
  void dispose() {
    // Удаляем наблюдатель жизненного цикла
    WidgetsBinding.instance.removeObserver(this);

    // Убираем вызов cleanup() из dispose, так как это может вызвать ошибку
    // обращения к деактивированному виджету
    ref.read(appLifecycleProvider.notifier).cleanup();

    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    // Жизненный цикл приложения 
    // await ref.read(appLifecycleProvider.notifier).handleLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        logInfo("AppLifecycleState: resumed");
        break;
      case AppLifecycleState.paused:
        logInfo("AppLifecycleState: paused");
        break;
      case AppLifecycleState.detached:
        logInfo(
          "AppLifecycleState: detached - resources cleared",
          tag: 'AppLifecycle',
        );
        break;
      case AppLifecycleState.inactive:
        logInfo("AppLifecycleState: inactive");
        break;
      case AppLifecycleState.hidden:
        logInfo("AppLifecycleState: hidden");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final theme = ref.watch(themeProvider);

    final themeMode = theme.value ?? ThemeMode.system;

    return MaterialApp.router(
      title: MainConstants.appName,
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      themeAnimationStyle: AnimationStyle.noAnimation,
      themeAnimationCurve: Curves.linear,

      scaffoldMessengerKey: ScaffoldMessengerManager.globalKey,

      debugShowCheckedModeBanner: false,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],

      routerConfig: router,
      themeMode: themeMode,

      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ToastManager().initialize();
        });

        final responsiveChild = ResponsiveBreakpoints.builder(
          child: ClampingScrollWrapper.builder(context, child!),
          breakpoints: const [
            Breakpoint(
              start: MobileBreakpoint.start,
              end: MobileBreakpoint.end,
              name: MOBILE,
            ),
            Breakpoint(
              start: TabletBreakpoint.start,
              end: TabletBreakpoint.end,
              name: TABLET,
            ),
            Breakpoint(
              start: DesktopBreakpoint.start,
              end: DesktopBreakpoint.end,
              name: DESKTOP,
            ),
          ],
        );

        return responsiveChild;

        // return Stack(
        //   children: [responsiveChild, const DatabaseClosedOverlay()],
        // );
      },
    );
  }
}
