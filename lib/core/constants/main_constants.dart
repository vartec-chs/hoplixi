import 'package:flutter/material.dart';

class MainConstants {
  static const String appName = 'Hoplixi';
  // static const List<String> appNameWords = ['Maze', 'X', 'Fort'];

  static const String appDescription =
      'Cross platform local password manager with future support for cloud sync.';

  static const String appFolderName = 'Hoplixi';

  static const String appAuthor = 'Vartec';
  static const String appLicense = 'MIT';
  static const String appVersion = '1.0.0';

  static const String dbExtension = 'hpl';

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  static const Size defaultWindowSize = Size(650, 720);
  static const Size minWindowSize = Size(400, 500);
  static const Size maxWindowSize = Size(1000, 1000);
  static const bool isCenter = true;

  static const String logPath = 'Hoplixi/logs';
  static const int maxLogFileSizeMB = 10; // Maximum log file size in MB
  static const int maxLogFiles = 5; // Maximum number of log files to keep

  static const int dbSchemaVersion = 1;
}
