import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app.dart';
import 'package:hoplixi/core/flutter_secure_storageo_impl.dart';
// import 'package:hoplixi/core/hive_service.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:hoplixi/core/secure_storage/storage_service_locator.dart';
import 'package:hoplixi/core/utils/scaffold_messenger_manager/scaffold_messenger_manager.dart';
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
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize AppLogger
      await AppLogger.instance.initialize(
        config: const LoggerConfig(
          maxFileSize: 5 * 1024 * 1024, // 5MB
          maxFileCount: 5,
          bufferSize: 50,
          bufferFlushInterval: Duration(seconds: 15),
          enableDebug: true,
          enableConsoleOutput: true,
          enableFileOutput: true,
          enableCrashReports: true,
        ),
      );

      final container = ProviderContainer();

      // Инициализируем сервис-локатор
      StorageServiceLocator.initialize(container);

      // Инициализируем хранилище
      await StorageServiceLocator.initializeStorage();

      // HiveService.initialize(appVersion: '1.0.0', secureStorage: secureStorage);

      // Handle Flutter errors
      FlutterError.onError = (FlutterErrorDetails details) {
        logError(
          'Flutter error: ${details.exceptionAsString()}',
          stackTrace: details.stack,
        );
        ScaffoldMessengerManager.instance.showError(
          'Ошибка Flutter: ${details.exceptionAsString()}',
          onCopyPressed: () => Clipboard.setData(
            ClipboardData(text: details.exceptionAsString()),
          ),
        );
      };

      // Handle platform errors
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        logError('Platform error: $error', stackTrace: stackTrace);
        ScaffoldMessengerManager.instance.showError(
          'Ошибка платформы: $error',
          onCopyPressed: () =>
              Clipboard.setData(ClipboardData(text: error.toString())),
        );
        return true;
      };

      // Initialize window manager
      await WindowManager.initialize();

      runApp(UncontrolledProviderScope(container: container, child: App()));
    },
    (error, stackTrace) {
      logError('Uncaught error: $error', stackTrace: stackTrace);
      ScaffoldMessengerManager.instance.showError(
        'Неизвестная ошибка: $error',
        onCopyPressed: () =>
            Clipboard.setData(ClipboardData(text: error.toString())),
      );
    },
  );
}
