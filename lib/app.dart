import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app/constants/main_constants.dart';
import 'package:hoplixi/app/constants/responsive_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/providers/app_close_provider.dart';
import 'package:hoplixi/core/providers/app_lifecycle_provider.dart';
import 'package:hoplixi/core/utils/toast/toast_manager.dart';
import 'package:hoplixi/app/router/router_provider.dart';
import 'package:hoplixi/core/utils/scaffold_messenger_manager/scaffold_messenger_manager.dart';
import 'package:hoplixi/app/theme/index.dart';
import 'package:hoplixi/hoplixi_store/providers/hoplixi_store_providers.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onDetach: _onDetach,
      onHide: _onHide,
      onInactive: _onInactive,
      onPause: _onPause,
      onRestart: _onRestart,
      onResume: _onResume,
      onShow: _onShow,
      onExitRequested: _onExitRequested,
    );
  }

  @override
  void dispose() {
    ref.read(appLifecycleProvider.notifier).cleanup();
    _listener.dispose();
    super.dispose();
  }

  Future<void> _onDetach() async => {
    await ref.read(appLifecycleProvider.notifier).onDetach(),
  };

  Future<void> _onHide() async => {
    await ref.read(appLifecycleProvider.notifier).onHide(),
  };

  Future<void> _onInactive() async => {
    await ref.read(appLifecycleProvider.notifier).onInactive(),
  };

  Future<void> _onPause() async => {
    await ref.read(appLifecycleProvider.notifier).onPause(),
  };

  Future<void> _onRestart() async => {
    await ref.read(appLifecycleProvider.notifier).onRestart(),
  };

  Future<void> _onResume() async => {
    await ref.read(appLifecycleProvider.notifier).onResume(),
  };

  Future<void> _onShow() async => {
    await ref.read(appLifecycleProvider.notifier).onShow(),
  };

  Future<AppExitResponse> _onExitRequested() async {
    return await ref.read(appLifecycleProvider.notifier).onExitRequested();
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
