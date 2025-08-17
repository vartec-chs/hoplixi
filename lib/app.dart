import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/constants/responsive_constants.dart';

// import 'package:hoplixi/core/theme/theme.dart';
import 'package:hoplixi/core/theme_old/theme_provider.dart';
import 'package:hoplixi/router/router_provider.dart';
import 'package:hoplixi/core/utils/scaffold_messenger_manager/scaffold_messenger_manager.dart';
import 'package:hoplixi/core/theme/theme.dart';
import 'package:responsive_framework/responsive_framework.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // Инициализируем ScaffoldMessengerManager
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessengerManager.initializeApp();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    final theme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: MainConstants.appName,
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      scaffoldMessengerKey: ScaffoldMessengerManager.globalKey,

      debugShowCheckedModeBanner: false,

      routerConfig: router,
      themeMode: theme,

      builder: (context, child) => ResponsiveBreakpoints.builder(
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
      ),
    );
  }
}
