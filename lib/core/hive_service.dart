// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:io';
// import 'dart:math';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:hoplixi/core/flutter_secure_storageo_impl.dart';

// class HiveServiceException implements Exception {
//   final String message;
//   final String? boxName;
//   final Exception? originalException;

//   const HiveServiceException(
//     this.message, {
//     this.boxName,
//     this.originalException,
//   });

//   @override
//   String toString() {
//     final boxInfo = boxName != null ? ' (box: $boxName)' : '';
//     final originalInfo = originalException != null
//         ? ' - Original: ${originalException.toString()}'
//         : '';
//     return 'HiveServiceException: $message$boxInfo$originalInfo';
//   }
// }

// class HiveService {
//   static const String _keyStoragePrefix = 'hive_key_';
//   static const String _appVersionKey = 'hive_app_version';
//   static const String _firstRunKey = 'hive_first_run';

//   static late SecureStorage _secureStorage;

//   static final Map<String, Box> _openBoxes = {};
//   static final Map<String, Uint8List> _cachedKeys = {}; // Cache keys in memory
//   static bool _isInitialized = false;
//   static String? _appVersion;

//   static Future<void> initialize({
//     String? appVersion,
//     required SecureStorage secureStorage,
//   }) async {
//     if (_isInitialized) return;

//     try {
//       await Hive.initFlutter();
//       _appVersion = appVersion ?? '1.0.0';
//       _secureStorage = secureStorage;

//       // Check if this is first run or version changed
//       await _handleFirstRunOrVersionChange();

//       _isInitialized = true;
//     } catch (e) {
//       throw HiveServiceException(
//         'Failed to initialize Hive',
//         originalException: e is Exception ? e : Exception(e.toString()),
//       );
//     }
//   }

//   static Future<void> _handleFirstRunOrVersionChange() async {
//     try {
//       final storedVersion = await _secureStorage?.read(key: _appVersionKey);
//       final isFirstRun = await _secureStorage?.read(key: _firstRunKey) == null;

//       if (isFirstRun) {
//         // First run - mark as completed
//         await _secureStorage?.write(key: _firstRunKey, value: 'completed');
//         await _secureStorage?.write(key: _appVersionKey, value: _appVersion!);
//       } else if (storedVersion != _appVersion) {
//         // Version changed - update stored version
//         await _secureStorage?.write(key: _appVersionKey, value: _appVersion!);
//       }
//     } catch (e) {
//       // If secure storage fails, log but continue
//       print('Warning: Could not handle version tracking: $e');
//     }
//   }

//   // Register adapters (call once for each adapter)
//   static void registerAdapter<T>(TypeAdapter<T> adapter) {
//     if (!Hive.isAdapterRegistered(adapter.typeId)) {
//       Hive.registerAdapter(adapter);
//     }
//   }

//   // Generate a cryptographically secure key
//   static Uint8List _generateSecureKey() {
//     final secureRandom = Random.secure();
//     return Uint8List.fromList(
//       List<int>.generate(32, (i) => secureRandom.nextInt(256)),
//     );
//   }

//   // Get or create encryption key for specific box with error recovery
//   static Future<Uint8List> _getOrCreateEncryptionKey(String boxName) async {
//     // Check memory cache first
//     if (_cachedKeys.containsKey(boxName)) {
//       return _cachedKeys[boxName]!;
//     }

//     final keyStorageKey = '$_keyStoragePrefix$boxName';

//     try {
//       // Try to read existing key
//       String? keyString = await _secureStorage.read(key: keyStorageKey);

//       if (keyString != null && keyString.isNotEmpty) {
//         try {
//           final key = base64.decode(keyString);
//           if (key.length == 32) {
//             _cachedKeys[boxName] = key;
//             return key;
//           } else {
//             print(
//               'Warning: Invalid key length for box $boxName, regenerating...',
//             );
//           }
//         } catch (e) {
//           print(
//             'Warning: Failed to decode key for box $boxName, regenerating...',
//           );
//         }
//       }

//       // Generate new key if none exists or invalid
//       final newKey = _generateSecureKey();
//       final newKeyString = base64.encode(newKey);

//       try {
//         await _secureStorage.write(key: keyStorageKey, value: newKeyString);
//       } catch (e) {
//         throw HiveServiceException(
//           'Failed to store encryption key',
//           boxName: boxName,
//           originalException: e is Exception ? e : Exception(e.toString()),
//         );
//       }

//       _cachedKeys[boxName] = newKey;
//       return newKey;
//     } catch (e) {
//       if (e is HiveServiceException) rethrow;

//       // Last resort: use in-memory key (will be lost on app restart)
//       print(
//         'Warning: Using in-memory key for box $boxName due to secure storage error: $e',
//       );
//       final memoryKey = _generateSecureKey();
//       _cachedKeys[boxName] = memoryKey;
//       return memoryKey;
//     }
//   }

//   // Try to recover from box corruption
//   static Future<void> _recoverCorruptedBox(String boxName) async {
//     try {
//       // Delete corrupted box
//       await Hive.deleteBoxFromDisk(boxName);

//       // Clear cached key
//       _cachedKeys.remove(boxName);

//       // Remove stored key to force regeneration
//       final keyStorageKey = '$_keyStoragePrefix$boxName';
//       await _secureStorage.delete(key: keyStorageKey);

//       print('Recovered corrupted box: $boxName');
//     } catch (e) {
//       print('Failed to recover corrupted box $boxName: $e');
//     }
//   }

//   // Open encrypted box with automatic error recovery
//   static Future<Box<T>> openBox<T>(
//     String boxName, {
//     bool encrypted = true,
//   }) async {
//     if (!_isInitialized) {
//       throw const HiveServiceException(
//         'HiveService not initialized. Call HiveService.initialize() first.',
//       );
//     }

//     // Return existing box if already open
//     if (_openBoxes.containsKey(boxName)) {
//       return _openBoxes[boxName]! as Box<T>;
//     }

//     Box<T>? box;
//     int retryCount = 0;
//     const maxRetries = 2;

//     while (retryCount <= maxRetries) {
//       try {
//         if (encrypted) {
//           final encryptionKey = await _getOrCreateEncryptionKey(boxName);
//           box = await Hive.openBox<T>(
//             boxName,
//             encryptionCipher: HiveAesCipher(encryptionKey),
//           );
//         } else {
//           box = await Hive.openBox<T>(boxName);
//         }

//         // Test box by trying to access it
//         final _ = box.isEmpty;

//         _openBoxes[boxName] = box;
//         return box;
//       } catch (e) {
//         retryCount++;

//         if (retryCount <= maxRetries) {
//           print(
//             'Failed to open box $boxName (attempt $retryCount), trying to recover...',
//           );

//           // Try to recover from corruption
//           await _recoverCorruptedBox(boxName);

//           // Wait a bit before retry
//           await Future.delayed(Duration(milliseconds: 100 * retryCount));
//         } else {
//           // All retries failed
//           throw HiveServiceException(
//             'Failed to open box after $maxRetries attempts',
//             boxName: boxName,
//             originalException: e is Exception ? e : Exception(e.toString()),
//           );
//         }
//       }
//     }

//     // This should never be reached, but just in case
//     throw HiveServiceException(
//       'Unexpected error opening box',
//       boxName: boxName,
//     );
//   }

//   // Get information about a box
//   static Future<Map<String, dynamic>> getBoxInfo(String boxName) async {
//     final isOpen = _openBoxes.containsKey(boxName);
//     final hasKey = _cachedKeys.containsKey(boxName);

//     Map<String, dynamic> info = {
//       'boxName': boxName,
//       'isOpen': isOpen,
//       'hasStoredKey': hasKey,
//       'encrypted': true, // All boxes are encrypted in this implementation
//     };

//     if (isOpen) {
//       try {
//         final box = _openBoxes[boxName]!;
//         info.addAll({
//           'itemCount': box.length,
//           'keys': box.keys
//               .take(10)
//               .toList(), // Limit to first 10 keys for performance
//           'isEmpty': box.isEmpty,
//         });
//       } catch (e) {
//         info['error'] = e.toString();
//       }
//     }

//     return info;
//   }

//   // Close specific box
//   static Future<void> closeBox(String boxName) async {
//     final box = _openBoxes[boxName];
//     if (box != null) {
//       try {
//         await box.close();
//       } catch (e) {
//         print('Warning: Error closing box $boxName: $e');
//       } finally {
//         _openBoxes.remove(boxName);
//       }
//     }
//   }

//   // Close all boxes
//   static Future<void> closeAllBoxes() async {
//     final boxNames = _openBoxes.keys.toList();

//     for (final boxName in boxNames) {
//       await closeBox(boxName);
//     }

//     _cachedKeys.clear();
//   }

//   // Delete box and its encryption key
//   static Future<void> deleteBox(String boxName) async {
//     await closeBox(boxName);

//     try {
//       await Hive.deleteBoxFromDisk(boxName);
//     } catch (e) {
//       print('Warning: Failed to delete box from disk: $e');
//     }

//     // Remove encryption key
//     final keyStorageKey = '$_keyStoragePrefix$boxName';
//     try {
//       await _secureStorage.delete(key: keyStorageKey);
//     } catch (e) {
//       print('Warning: Failed to delete encryption key: $e');
//     }

//     _cachedKeys.remove(boxName);
//   }

//   // Clear all Hive data and keys (for complete reset)
//   static Future<void> clearAllData() async {
//     await closeAllBoxes();

//     try {
//       await Hive.deleteFromDisk();
//     } catch (e) {
//       print('Warning: Failed to delete Hive data from disk: $e');
//     }

//     try {
//       await _secureStorage.deleteAll();
//     } catch (e) {
//       print('Warning: Failed to clear secure storage: $e');
//     }

//     _cachedKeys.clear();
//   }

//   // Get list of all boxes and their info
//   static Future<List<Map<String, dynamic>>> getAllBoxesInfo() async {
//     final List<Map<String, dynamic>> boxesInfo = [];

//     // Get box names from secure storage keys
//     final Set<String> boxNames = {};

//     try {
//       final allKeys = await _secureStorage.readAll();
//       for (final key in allKeys.keys) {
//         if (key.startsWith(_keyStoragePrefix)) {
//           boxNames.add(key.substring(_keyStoragePrefix.length));
//         }
//       }
//     } catch (e) {
//       print('Warning: Could not read from secure storage: $e');
//     }

//     // Add currently open boxes
//     boxNames.addAll(_openBoxes.keys);

//     for (final boxName in boxNames) {
//       try {
//         final info = await getBoxInfo(boxName);
//         boxesInfo.add(info);
//       } catch (e) {
//         boxesInfo.add({
//           'boxName': boxName,
//           'isOpen': false,
//           'hasStoredKey': false,
//           'encrypted': true,
//           'error': e.toString(),
//         });
//       }
//     }

//     return boxesInfo;
//   }

//   // Health check for the service
//   static Future<Map<String, dynamic>> healthCheck() async {
//     final Map<String, dynamic> health = {
//       'initialized': _isInitialized,
//       'appVersion': _appVersion,
//       'openBoxesCount': _openBoxes.length,
//       'cachedKeysCount': _cachedKeys.length,
//       'platformInfo': getPlatformInfo(),
//       'secureStorageAvailable': await isSecureStorageAvailable(),
//     };

//     // Test secure storage
//     try {
//       const testKey = 'hive_health_check';
//       const testValue = 'test_value';

//       await _secureStorage.write(key: testKey, value: testValue);
//       final readValue = await _secureStorage.read(key: testKey);
//       await _secureStorage.delete(key: testKey);

//       health['secureStorageWorking'] = readValue == testValue;
//     } catch (e) {
//       health['secureStorageWorking'] = false;
//       health['secureStorageError'] = e.toString();
//     }

//     return health;
//   }

//   // Check if secure storage is available
//   static Future<bool> isSecureStorageAvailable() async {
//     try {
//       await _secureStorage.read(key: 'test');
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }

//   // Get platform-specific secure storage info
//   static String getPlatformInfo() {
//     if (Platform.isWindows) {
//       return 'Windows Credential Store';
//     } else if (Platform.isMacOS) {
//       return 'macOS Keychain';
//     } else if (Platform.isLinux) {
//       return 'Linux Session Keyring';
//     } else if (Platform.isAndroid) {
//       return 'Android Encrypted SharedPreferences';
//     } else if (Platform.isIOS) {
//       return 'iOS Keychain';
//     } else {
//       return 'Platform-specific secure storage';
//     }
//   }

//   // Repair method to fix issues
//   static Future<List<String>> repairAllBoxes() async {
//     final List<String> repairLog = [];

//     try {
//       final allBoxInfo = await getAllBoxesInfo();

//       for (final boxInfo in allBoxInfo) {
//         final boxName = boxInfo['boxName'] as String;

//         if (boxInfo.containsKey('error')) {
//           repairLog.add('Attempting to repair box: $boxName');
//           try {
//             await _recoverCorruptedBox(boxName);
//             repairLog.add('Successfully repaired box: $boxName');
//           } catch (e) {
//             repairLog.add('Failed to repair box $boxName: $e');
//           }
//         }
//       }

//       if (repairLog.isEmpty) {
//         repairLog.add('No boxes required repair');
//       }
//     } catch (e) {
//       repairLog.add('Repair process failed: $e');
//     }

//     return repairLog;
//   }
// }
