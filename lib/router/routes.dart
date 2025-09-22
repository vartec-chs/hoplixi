import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/preferences/dynamic_settings_screen.dart';
import 'package:hoplixi/features/home/home.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store.dart';
import 'package:hoplixi/features/password_manager/dashboard/example/filter_modal_example_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard_old/dashboard.dart';
import 'package:hoplixi/features/password_manager/categories_manager/categories_manager_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard_old/features/password_form/password_form_screen.dart';
import 'package:hoplixi/features/password_manager/icons_manager/icons_management_screen.dart';
import 'package:hoplixi/features/password_manager/screens/password_manager_screen.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_management_screen.dart';

import 'package:hoplixi/features/password_manager/before_opening/open_store/open_store.dart';
import 'package:hoplixi/features/password_manager/universal_filter/example/universal_filter_example_screen.dart';
import 'package:hoplixi/features/setup/setup.dart';
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
    builder: (context, state) => const SetupScreen(),
  ),
  GoRoute(
    path: AppRoutes.home,
    builder: (context, state) => const ModernHomeScreen(),
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
    path: AppRoutes.dashboard,
    builder: (context, state) => const FilterModalExampleScreen(),
  ),
  // GoRoute(
  //   path: AppRoutes.passwordManager,
  //   builder: (context, state) => const PasswordManagerScreen(),
  // ),
  GoRoute(
    path: AppRoutes.baseSettings,
    builder: (context, state) => const DynamicSettingsScreen(),
  ),
  GoRoute(
    path: AppRoutes.categoryManager,
    builder: (context, state) => const CategoriesManagerScreen(),
  ),
  GoRoute(
    path: AppRoutes.iconManager,
    builder: (context, state) => const IconsManagementScreen(),
  ),
  GoRoute(
    path: AppRoutes.tagsManager,
    builder: (context, state) => const TagsManagementScreen(),
  ),
  GoRoute(
    path: AppRoutes.passwordForm,
    builder: (context, state) => const PasswordFormScreen(),
  ),
  GoRoute(
    path: '${AppRoutes.passwordForm}/:passwordId',
    builder: (context, state) {
      final passwordId = state.pathParameters['passwordId'];
      return PasswordFormScreen(passwordId: passwordId);
    },
  ),
  GoRoute(
    path: AppRoutes.universalFilterDemo,
    builder: (context, state) => const UniversalFilterExampleScreen(),
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
