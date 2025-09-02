import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/app.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/logger/models.dart';
import 'package:hoplixi/core/secure_storage/storage_service_locator.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:toastification/toastification.dart';
import 'package:hoplixi/core/utils/window_manager.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';


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
            child: App(),
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
