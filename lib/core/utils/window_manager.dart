import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/logger/app_logger.dart';

import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

class WindowManager {
  static Future<void> initialize() async {
    if (UniversalPlatform.isWindows) {
      await windowManager.ensureInitialized();
      WindowOptions windowOptions = const WindowOptions(
        title: MainConstants.appName,
        minimumSize: MainConstants.minWindowSize, // Минимальный размер окна
        maximumSize: MainConstants.maxWindowSize, // Максимальный размер окна
        size: MainConstants.defaultWindowSize, // Начальный размер окна
        center: MainConstants.isCenter, // Центрировать окно при запуске
      );

      await windowManager.waitUntilReadyToShow(windowOptions).then((_) async {
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        await windowManager.show();
      });

      windowManager.addListener(AppWindowListener());
    }
  }
}

class AppWindowListener with WindowListener {
  @override
  void onWindowEvent(String eventName) {
    if (eventName != "move" || eventName != "moved") {
      logInfo('Window $eventName', tag: 'WindowManager');
    }
  }
}
