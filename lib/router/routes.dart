import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/home/home.dart';
import 'package:hoplixi/features/password_manager/create_store/create_store.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/open_store/open_store.dart';
import 'package:hoplixi/features/test/test.dart';
import 'routes_path.dart';

final List<GoRoute> appRoutes = [
  GoRoute(
    path: AppRoutes.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: AppRoutes.logs,
    builder: (context, state) => const SplashScreen(title: 'Logs Screen'),
  ),
  GoRoute(
    path: AppRoutes.setup,
    builder: (context, state) => const SplashScreen(title: 'Setup Screen'),
  ),
  GoRoute(
    path: AppRoutes.home,
    builder: (context, state) => const HomeScreen(),
  ),
  GoRoute(
    path: AppRoutes.createStore,
    builder: (context, state) => const CreateStoreScreen(),
  ),
  GoRoute(
    path: AppRoutes.openStore,
    builder: (context, state) => const OpenStoreScreen(),
  ),
  GoRoute(
    path: AppRoutes.testDemo,
    builder: (context, state) => const TestScreen(),
  ),
  GoRoute(
    path: AppRoutes.dashboard,
    builder: (context, state) => const DashboardScreen(),
  ),
];

class SplashScreen extends StatelessWidget {
  final String? title;
  const SplashScreen({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title ?? 'Splash Screen')));
  }
}
