import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/app/constants/responsive_constants.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';
import 'package:hoplixi/core/utils/toast/toast_manager.dart';
import 'package:hoplixi/app/router/router_provider.dart';
import 'package:hoplixi/core/utils/scaffold_messenger_manager/scaffold_messenger_manager.dart';
import 'package:hoplixi/app/theme/index.dart';
import 'package:hoplixi/main.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tray_manager/tray_manager.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with TrayListener {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
    final appLifecycleNotifier = ref.read(appLifecycleProvider.notifier);
    _listener = AppLifecycleListener(
      onDetach: () => appLifecycleNotifier.onDetach(),
      onHide: () => appLifecycleNotifier.onHide(),
      onInactive: () => appLifecycleNotifier.onInactive(),
      onPause: () => appLifecycleNotifier.onPause(),
      onRestart: () => appLifecycleNotifier.onRestart(),
      onResume: () => appLifecycleNotifier.onResume(),
      onShow: () => appLifecycleNotifier.onShow(),
      onExitRequested: () => appLifecycleNotifier.onExitRequested(),
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    // Handle tray icon mouse down event
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconMouseUp() {
    // Handle tray icon mouse up event
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    // TODO: implement onTrayIconRightMouseDown
    super.onTrayIconRightMouseDown();
  }

  @override
  void onTrayIconRightMouseUp() {
    // TODO: implement onTrayIconRightMouseUp
    super.onTrayIconRightMouseUp();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == null) {
      logWarning('Tray menu item clicked with null key', tag: 'TrayManager');
      return;
    }
    final menuItemKey = AppTrayMenuItemKeyExtension.fromKey(menuItem.key!);
    if (menuItemKey == null) {
      logWarning(
        'Unknown tray menu item key: ${menuItem.key}',
        tag: 'TrayManager',
      );
      return;
    }
    switch (menuItemKey) {
      case AppTrayMenuItemKey.showWindow:
        await WindowManager.show();
        break;
      case AppTrayMenuItemKey.exitApp:
        await WindowManager.close();
        break;
    }
    super.onTrayMenuItemClick(menuItem);
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
