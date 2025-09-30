import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:universal_platform/universal_platform.dart';

import '../logger/app_logger.dart';

/// Сервис для работы с локальными уведомлениями
/// Предоставляет унифицированный API для всех поддерживаемых платформ
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  int _notificationId = 0;

  /// Канал уведомлений по умолчанию
  static const String _defaultChannelId = 'hoplixi_default';
  static const String _defaultChannelName = 'Hoplixi Notifications';
  static const String _defaultChannelDescription = 'Общие уведомления Hoplixi';

  /// Канал для важных уведомлений
  static const String _importantChannelId = 'hoplixi_important';
  static const String _importantChannelName = 'Важные уведомления';
  static const String _importantChannelDescription =
      'Важные уведомления системы безопасности';

  /// Канал для TOTP уведомлений
  static const String _totpChannelId = 'hoplixi_totp';
  static const String _totpChannelName = 'TOTP коды';
  static const String _totpChannelDescription =
      'Уведомления о генерации TOTP кодов';

  /// Инициализация сервиса уведомлений
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      logInfo('Инициализация сервиса уведомлений', tag: 'NotificationService');

      // Настройка timezone для планирования уведомлений
      await _configureLocalTimeZone();

      // Настройки для Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Настройки для iOS/macOS
      final DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
            notificationCategories: _getDarwinNotificationCategories(),
          );

      // Настройки для Linux
      final LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(
            defaultActionName: 'Открыть Hoplixi',
            defaultIcon: AssetsLinuxIcon('icons/app_icon.png'),
          );

      // Настройки для Windows
      const WindowsInitializationSettings windowsSettings =
          WindowsInitializationSettings(
            appName: 'Hoplixi',
            appUserModelId: 'com.hoplixi.PasswordManager',
            guid: 'hoplixi-password-manager',
          );

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: androidSettings,
            iOS: darwinSettings,
            macOS: darwinSettings,
            linux: linuxSettings,
            windows: windowsSettings,
          );

      // Инициализация плагина
      final bool? result = await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse:
            _onBackgroundNotificationTapped,
      );

      if (result == false) {
        logError(
          'Не удалось инициализировать сервис уведомлений',
          tag: 'NotificationService',
        );
        return false;
      }

      // Создание каналов уведомлений для Android
      if (UniversalPlatform.isAndroid) {
        await _createNotificationChannels();
      }

      _isInitialized = true;
      logInfo(
        'Сервис уведомлений успешно инициализирован',
        tag: 'NotificationService',
      );
      return true;
    } catch (e, stackTrace) {
      logError(
        'Ошибка инициализации сервиса уведомлений: $e',
        tag: 'NotificationService',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Запрос разрешений на уведомления
  Future<bool> requestPermissions() async {
    try {
      logInfo('Запрос разрешений на уведомления', tag: 'NotificationService');

      if (UniversalPlatform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        final bool? granted = await androidImplementation
            ?.requestNotificationsPermission();

        if (granted == true) {
          logInfo(
            'Разрешения на уведомления получены (Android)',
            tag: 'NotificationService',
          );
          return true;
        } else {
          logWarning(
            'Разрешения на уведомления отклонены (Android)',
            tag: 'NotificationService',
          );
          return false;
        }
      }

      if (UniversalPlatform.isIOS || UniversalPlatform.isMacOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();

        final bool? granted = await iosImplementation?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

        if (granted == true) {
          logInfo(
            'Разрешения на уведомления получены (iOS)',
            tag: 'NotificationService',
          );
          return true;
        } else {
          logWarning(
            'Разрешения на уведомления отклонены (iOS)',
            tag: 'NotificationService',
          );
          return false;
        }
      }

      // Для других платформ считаем, что разрешения не требуются
      return true;
    } catch (e, stackTrace) {
      logError(
        'Ошибка запроса разрешений на уведомления: $e',
        tag: 'NotificationService',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Проверка, включены ли уведомления
  Future<bool> areNotificationsEnabled() async {
    try {
      if (UniversalPlatform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >();

        return await androidImplementation?.areNotificationsEnabled() ?? false;
      }

      if (UniversalPlatform.isIOS || UniversalPlatform.isMacOS) {
        final IOSFlutterLocalNotificationsPlugin? iosImplementation =
            _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >();

        final NotificationsEnabledOptions? options = await iosImplementation
            ?.checkPermissions();
        return options?.isEnabled ?? false;
      }

      return true;
    } catch (e, stackTrace) {
      logError(
        'Ошибка проверки состояния уведомлений: $e',
        tag: 'NotificationService',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Показать простое уведомление
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationChannel channel = NotificationChannel.general,
    NotificationImportance importance = NotificationImportance.normal,
  }) async {
    if (!_isInitialized) {
      logWarning(
        'Сервис уведомлений не инициализирован',
        tag: 'NotificationService',
      );
      return;
    }

    try {
      final int id = _getNextNotificationId();
      final NotificationDetails details = _buildNotificationDetails(
        channel,
        importance,
      );

      logInfo(
        'Отправка уведомления: $title',
        tag: 'NotificationService',
        data: {'id': id, 'channel': channel.name},
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка отправки уведомления: $e',
        tag: 'NotificationService',
        stackTrace: stackTrace,
      );
    }
  }

  /// Показать уведомление с кнопками действий
  Future<void> showNotificationWithActions({
    required String title,
    required String body,
    required List<NotificationAction> actions,
    String? payload,
    NotificationChannel channel = NotificationChannel.general,
    NotificationImportance importance = NotificationImportance.normal,
  }) async {
    if (!_isInitialized) {
      logWarning(
        'Сервис уведомлений не инициализирован',
        tag: 'NotificationService',
      );
      return;
    }

    try {
      final int id = _getNextNotificationId();
      final NotificationDetails details = _buildNotificationDetailsWithActions(
        channel,
        importance,
        actions,
      );

      logInfo(
        'Отправка уведомления с действиями: $title',
        tag: 'NotificationService',
        data: {'id': id, 'channel': channel.name, 'actions': actions.length},
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка отправки уведомления с действиями: $e',
        tag: 'NotificationService',
        stackTrace: stackTrace,
      );
    }
  }

  /// Запланировать уведомление
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationChannel channel = NotificationChannel.general,
    NotificationImportance importance = NotificationImportance.normal,
  }) async {
    if (!_isInitialized) {
      logWarning(
        'Сервис уведомлений не инициализирован',
        tag: 'NotificationService',
      );
      return;
    }

    try {
      final int id = _getNextNotificationId();
      final NotificationDetails details = _buildNotificationDetails(
        channel,
        importance,
      );
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      logInfo(
        'Планирование уведомления: $title на ${scheduledTime.toIso8601String()}',
        tag: 'NotificationService',
        data: {'id': id, 'channel': channel.name},
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e, stackTrace) {
      logError(
        'Ошибка планирования уведомления: $e',
        tag: 'NotificationService',
        stackTrace: stackTrace,
      );
    }
  }

  /// Отменить уведомление по ID
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      logInfo('Уведомление отменено: $id', tag: 'NotificationService');
    } catch (e, stackTrace) {
      logError(
        'Ошибка отмены уведомления: $e',
        tag: 'NotificationService',
        stackTrace: stackTrace,
      );
    }
  }

  /// Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      logInfo('Все уведомления отменены', tag: 'NotificationService');
    } catch (e, stackTrace) {
      logError(
        'Ошибка отмены всех уведомлений: $e',
        tag: 'NotificationService',
        stackTrace: stackTrace,
      );
    }
  }

  /// Получить список запланированных уведомлений
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e, stackTrace) {
      logError(
        'Ошибка получения запланированных уведомлений: $e',
        tag: 'NotificationService',
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // ==================== ПРИВАТНЫЕ МЕТОДЫ ====================

  /// Настройка локальной временной зоны
  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb || UniversalPlatform.isLinux) {
      return;
    }

    tz.initializeTimeZones();

    if (UniversalPlatform.isWindows) {
      return;
    }

    try {
      final TimezoneInfo timeZoneInfo =
          await FlutterTimezone.getLocalTimezone();
      if (timeZoneInfo.identifier.isNotEmpty) {
        tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
      }
    } catch (e) {
      logWarning(
        'Не удалось настроить временную зону: $e',
        tag: 'NotificationService',
      );
    }
  }

  /// Получение категорий уведомлений для Darwin (iOS/macOS)
  List<DarwinNotificationCategory> _getDarwinNotificationCategories() {
    return [
      DarwinNotificationCategory(
        'general',
        actions: [
          DarwinNotificationAction.plain('open', 'Открыть'),
          DarwinNotificationAction.plain('dismiss', 'Отклонить'),
        ],
      ),
      DarwinNotificationCategory(
        'security',
        actions: [
          DarwinNotificationAction.plain('open', 'Открыть'),
          DarwinNotificationAction.plain('dismiss', 'Отклонить'),
        ],
      ),
      DarwinNotificationCategory(
        'totp',
        actions: [
          DarwinNotificationAction.plain('copy_code', 'Копировать код'),
          DarwinNotificationAction.plain('open', 'Открыть'),
        ],
      ),
    ];
  }

  /// Создание каналов уведомлений для Android
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation == null) return;

    // Основной канал
    await androidImplementation.createNotificationChannel(
      const AndroidNotificationChannel(
        _defaultChannelId,
        _defaultChannelName,
        description: _defaultChannelDescription,
        importance: Importance.defaultImportance,
        enableVibration: true,
        playSound: true,
      ),
    );

    // Канал важных уведомлений
    await androidImplementation.createNotificationChannel(
      const AndroidNotificationChannel(
        _importantChannelId,
        _importantChannelName,
        description: _importantChannelDescription,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
        enableLights: true,
        ledColor: Color(0xFFFF0000),
      ),
    );

    // Канал TOTP уведомлений
    await androidImplementation.createNotificationChannel(
      const AndroidNotificationChannel(
        _totpChannelId,
        _totpChannelName,
        description: _totpChannelDescription,
        importance: Importance.defaultImportance,
        enableVibration: false,
        playSound: false,
      ),
    );

    logInfo('Каналы уведомлений созданы', tag: 'NotificationService');
  }

  /// Построение настроек уведомления
  NotificationDetails _buildNotificationDetails(
    NotificationChannel channel,
    NotificationImportance importance,
  ) {
    final String channelId = _getChannelId(channel);
    final Importance androidImportance = _getAndroidImportance(importance);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          _getChannelName(channel),
          channelDescription: _getChannelDescription(channel),
          importance: androidImportance,
          priority: _getAndroidPriority(importance),
          enableVibration: importance != NotificationImportance.low,
          playSound: importance != NotificationImportance.low,
          icon: '@mipmap/ic_launcher',
        );

    final DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: channel.name,
      presentAlert: true,
      presentBadge: true,
      presentSound: importance != NotificationImportance.low,
    );

    final LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
      icon: AssetsLinuxIcon('icons/app_icon.png'),
      urgency: _getLinuxUrgency(importance),
    );

    final WindowsNotificationDetails windowsDetails =
        WindowsNotificationDetails();

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
      windows: windowsDetails,
    );
  }

  /// Построение настроек уведомления с действиями
  NotificationDetails _buildNotificationDetailsWithActions(
    NotificationChannel channel,
    NotificationImportance importance,
    List<NotificationAction> actions,
  ) {
    final String channelId = _getChannelId(channel);
    final Importance androidImportance = _getAndroidImportance(importance);

    final List<AndroidNotificationAction> androidActions = actions
        .map(
          (action) => AndroidNotificationAction(
            action.id,
            action.title,
            showsUserInterface: action.showsUserInterface,
          ),
        )
        .toList();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelId,
          _getChannelName(channel),
          channelDescription: _getChannelDescription(channel),
          importance: androidImportance,
          priority: _getAndroidPriority(importance),
          enableVibration: importance != NotificationImportance.low,
          playSound: importance != NotificationImportance.low,
          icon: '@mipmap/ic_launcher',
          actions: androidActions,
        );

    final DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: channel.name,
      presentAlert: true,
      presentBadge: true,
      presentSound: importance != NotificationImportance.low,
    );

    final List<LinuxNotificationAction> linuxActions = actions
        .map(
          (action) =>
              LinuxNotificationAction(key: action.id, label: action.title),
        )
        .toList();

    final LinuxNotificationDetails linuxDetails = LinuxNotificationDetails(
      icon: AssetsLinuxIcon('icons/app_icon.png'),
      urgency: _getLinuxUrgency(importance),
      actions: linuxActions,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );
  }

  /// Получение ID канала
  String _getChannelId(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.general:
        return _defaultChannelId;
      case NotificationChannel.security:
        return _importantChannelId;
      case NotificationChannel.totp:
        return _totpChannelId;
    }
  }

  /// Получение названия канала
  String _getChannelName(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.general:
        return _defaultChannelName;
      case NotificationChannel.security:
        return _importantChannelName;
      case NotificationChannel.totp:
        return _totpChannelName;
    }
  }

  /// Получение описания канала
  String _getChannelDescription(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.general:
        return _defaultChannelDescription;
      case NotificationChannel.security:
        return _importantChannelDescription;
      case NotificationChannel.totp:
        return _totpChannelDescription;
    }
  }

  /// Преобразование важности в Android Importance
  Importance _getAndroidImportance(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.normal:
        return Importance.defaultImportance;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.urgent:
        return Importance.max;
    }
  }

  /// Преобразование важности в Android Priority
  Priority _getAndroidPriority(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.low:
        return Priority.low;
      case NotificationImportance.normal:
        return Priority.defaultPriority;
      case NotificationImportance.high:
        return Priority.high;
      case NotificationImportance.urgent:
        return Priority.max;
    }
  }

  /// Преобразование важности в Linux Urgency
  LinuxNotificationUrgency _getLinuxUrgency(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.low:
        return LinuxNotificationUrgency.low;
      case NotificationImportance.normal:
        return LinuxNotificationUrgency.normal;
      case NotificationImportance.high:
        return LinuxNotificationUrgency.critical;
      case NotificationImportance.urgent:
        return LinuxNotificationUrgency.critical;
    }
  }

  /// Получение следующего ID уведомления
  int _getNextNotificationId() {
    return ++_notificationId;
  }

  /// Обработчик нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    logInfo(
      'Нажатие на уведомление: ${response.id}',
      tag: 'NotificationService',
      data: {
        'id': response.id,
        'actionId': response.actionId,
        'payload': response.payload,
      },
    );
    // TODO: Здесь можно добавить навигацию или другие действия
  }

  /// Обработчик фонового нажатия на уведомление
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Примечание: это статический метод для фонового выполнения
    // Здесь доступны только базовые операции
  }
}

/// Каналы уведомлений
enum NotificationChannel { general, security, totp }

/// Важность уведомления
enum NotificationImportance { low, normal, high, urgent }

/// Действие уведомления
class NotificationAction {
  final String id;
  final String title;
  final bool showsUserInterface;

  const NotificationAction({
    required this.id,
    required this.title,
    this.showsUserInterface = false,
  });
}
