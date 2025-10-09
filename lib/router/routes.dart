import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/features/demo/notification_demo_screen.dart';
import 'package:hoplixi/features/home/home.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:hoplixi/features/localsend/models/localsend_device_info.dart';
import 'package:hoplixi/features/localsend/screens/discovery_screen.dart';
import 'package:hoplixi/features/localsend/screens/transceive_screen.dart';
import 'package:hoplixi/features/password_manager/before_opening/create_store/create_store.dart';
import 'package:hoplixi/features/password_manager/dashboard/futures/notes_form/notes_form.dart';
import 'package:hoplixi/features/password_manager/dashboard/futures/otp_form/otp_form.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/dashboard_screen.dart';
import 'package:hoplixi/features/password_manager/categories_manager/categories_manager_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/futures/password_form/password_form_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/import_otp_screen.dart';
import 'package:hoplixi/features/password_manager/dashboard/screens/password_history_screen.dart';
import 'package:hoplixi/features/password_manager/icons_manager/icons_management_screen.dart';

import 'package:hoplixi/features/password_manager/qr_scaner/qr_scaner_screen.dart';
import 'package:hoplixi/features/password_manager/qr_scaner/qr_test_screen.dart';
import 'package:hoplixi/features/password_manager/tags_manager/tags_management_screen.dart';
import 'package:hoplixi/features/password_manager/before_opening/open_store/open_store.dart';
import 'package:hoplixi/features/setup/setup.dart';
import 'package:hoplixi/features/settings/screens/settings_screen.dart';
import 'package:hoplixi/router/router_provider.dart';
import 'package:universal_platform/universal_platform.dart';
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
    builder: (context, state) => const DashboardScreen(),
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
    path: AppRoutes.localSend,
    builder: (context, state) => const DiscoveryScreen(),
  ),

  GoRoute(
    path: '${AppRoutes.passwordHistory}/:passwordId',
    builder: (context, state) {
      if (state.pathParameters['passwordId'] == null) {
        return const SplashScreen(title: 'Ошибка: нет ID пароля');
      }
      final passwordId = state.pathParameters['passwordId'];
      return PasswordHistoryScreen(passwordId: passwordId!);
    },
  ),

  GoRoute(
    path: AppRoutes.demoNotification,
    builder: (context, state) => const NotificationDemoScreen(),
  ),

  GoRoute(
    path: AppRoutes.notesForm,
    builder: (context, state) => NotesFormScreen(),
  ),

  GoRoute(
    path: '${AppRoutes.notesForm}/:noteId',
    builder: (context, state) {
      final noteId = state.pathParameters['noteId'];
      return NotesFormScreen(id: noteId);
    },
  ),

  GoRoute(
    path: AppRoutes.qrScanner,
    builder: (context, state) {
      if (UniversalPlatform.isDesktop) {
        return const InfoScreen(
          title: 'Ошибка: недоступно на этой платформе',
          info: 'Сканирование QR-кодов не поддерживается на этой платформе.',
          type: InfoType.error,
        );
      }

      return const QrScannerScreen();
    },
  ),

  GoRoute(
    path: AppRoutes.importOtpCodes,
    builder: (context, state) => const ImportOtpScreen(),
  ),

  GoRoute(
    path: AppRoutes.qrTest,
    builder: (context, state) => const QrTestScreen(),
  ),

  GoRoute(
    path: AppRoutes.localSendTransfer,
    builder: (context, state) {
      if (state.extra is Map<String, dynamic>) {
        final data = state.extra as Map<String, dynamic>;
        logDebug(data.toString(), tag: "Route");
        final deviceInfo = data['device'] as LocalSendDeviceInfo?;
        final connectionMode = data['mode'] as ConnectionMode?;
        return TransceiveScreen(mode: connectionMode, deviceInfo: deviceInfo);
      }
      return const InfoScreen(
        title: 'Ошибка: нет данных',
        info: 'Попробуйте снова отправить файл из LocalSend.',
        type: InfoType.error,
      );
    },
  ),

  GoRoute(
    path: AppRoutes.otpForm,
    builder: (context, state) => const OtpForm(),
  ),

  GoRoute(
    path: AppRoutes.settings,
    builder: (context, state) => const SettingsScreen(),
  ),
];

class SplashScreen extends StatefulWidget {
  final String? title;
  const SplashScreen({super.key, this.title});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _animation.value.clamp(0.0, 1.0),
                    child: ScaleTransition(
                      scale: _animation,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              blurRadius: 40 * _animation.value,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(60),
                        ),
                        child: Image.asset(
                          'assets/img/logo_light.png',
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

enum InfoType { info, warning, error }

class InfoScreen extends StatelessWidget {
  final String? title;
  final String? info;
  final InfoType type;

  const InfoScreen({
    super.key,
    this.title,
    this.info,
    this.type = InfoType.info,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hoplixi Info'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            navigateBack(context);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == InfoType.info
                    ? Icons.info
                    : type == InfoType.warning
                    ? Icons.warning
                    : Icons.error,
                size: 64,
                color: type == InfoType.info
                    ? Colors.blue
                    : type == InfoType.warning
                    ? Colors.orange
                    : Colors.red,
              ),
              const SizedBox(height: 16),
              if (title != null)
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (info != null) ...[
                const SizedBox(height: 8),
                Text(
                  info!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
