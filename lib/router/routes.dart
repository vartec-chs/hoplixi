import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/preferences/dynamic_settings_screen.dart';
import 'package:hoplixi/features/filters/category_filter/example/category_filter_example_screen.dart';
import 'package:hoplixi/features/home/home.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store.dart';
import 'package:hoplixi/features/password_manager/categories_manager/categories_picker/categories_picker_example.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';
import 'package:hoplixi/features/password_manager/categories_manager/categories_manager_screen.dart';
import 'package:hoplixi/features/password_manager/icons_manager/icons_management_screen.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_management_screen.dart';

import 'package:hoplixi/features/password_manager/before_opening/open_store/open_store.dart';
import 'package:hoplixi/features/filters/tag_filter/example/tag_filter_example_screen.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_picker/tags_picker_example.dart';
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
    builder: (context, state) => const TagsPickerExample(),
  ),
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
];

class SplashScreen extends StatelessWidget {
  final String? title;
  const SplashScreen({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(title ?? 'Splash Screen')));
  }
}
