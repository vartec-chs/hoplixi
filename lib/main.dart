import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app.dart';
import 'package:hoplixi/app/app_preferences/app_preferences.dart';
import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/core/services/notification_helpers.dart';
import 'package:toastification/toastification.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:universal_platform/universal_platform.dart';

Future<void> main() async {
  if (UniversalPlatform.isWeb) {
    throw UnsupportedError(
      'Web platform is not supported in this version. Please use a different platform.',
    );
  }

  runZonedGuarded(
    () async {
      // Ensure Flutter binding is initialized
      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // Initialize AppLogger
      await AppLogger.instance.initialize(
        config: const LoggerConfig(
          maxFileSize: 10 * 1024 * 1024, // 10MB
          maxFileCount: 5,
          bufferSize: 50,
          bufferFlushInterval: Duration(seconds: 15),
          enableDebug: true,
          enableInfo: true,
          enableWarning: true,
          enableError: true,
          enableTrace: MainConstants.isProduction
              ? false
              : true, // Disable trace logs in production
          enableFatal: true,
          enableConsoleOutput: true,
          enableFileOutput: true,
          enableCrashReports: true,
        ),
      );

      // Инициализируем AppPreferences

      await Prefs.init();

      final container = ProviderContainer();

      // Инициализируем систему уведомлений
      try {
        await NotificationHelpers.initializeWithPermissions();
        logInfo('Система уведомлений инициализирована');
      } catch (e) {
        logWarning('Не удалось инициализировать систему уведомлений: $e');
      }

      // Handle Flutter errors
      FlutterError.onError = (FlutterErrorDetails details) {
        logError(
          'Flutter error: ${details.exceptionAsString()}',
          stackTrace: details.stack,
        );
        ToastHelper.error(
          title: 'Ошибка Flutter',
          description: details.exceptionAsString(),
          callbacks: ToastificationCallbacks(
            onTap: (toastItem) => Clipboard.setData(
              ClipboardData(text: details.exceptionAsString()),
            ),
          ),
        );
      };

      // Handle platform errors
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        logError('Platform error: $error', stackTrace: stackTrace);
        ToastHelper.error(
          title: 'Ошибка',
          description: error.toString(),
          callbacks: ToastificationCallbacks(
            onTap: (toastItem) =>
                Clipboard.setData(ClipboardData(text: error.toString())),
          ),
        );
        return true;
      };

      // Initialize window manager
      await WindowManager.initialize();

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: ToastificationWrapper(
            config: ToastificationConfig(
              maxTitleLines: 2,

              maxDescriptionLines: 5,
              maxToastLimit: 3,
              itemWidth: UniversalPlatform.isDesktop ? 400 : double.infinity,
              // alignment: Alignment.bottomRight,
              alignment: UniversalPlatform.isDesktop
                  ? Alignment.bottomRight
                  : Alignment.topCenter,
            ),
            child: const App(),
          ),
        ),
      );
    },
    (error, stackTrace) {
      logError('Uncaught error: $error', stackTrace: stackTrace);
      ToastHelper.error(
        // context: context,
        title: 'Ошибка',
        description: error.toString(),
        callbacks: ToastificationCallbacks(
          onTap: (toastItem) =>
              Clipboard.setData(ClipboardData(text: error.toString())),
        ),
      );
    },
  );
}
