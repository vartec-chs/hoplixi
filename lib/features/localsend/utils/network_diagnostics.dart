import 'dart:io';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/features/localsend/utils/ip_utils.dart';

/// Утилита для диагностики сетевых проблем LocalSend
class NetworkDiagnostics {
  static const String _logTag = 'NetworkDiagnostics';

  /// Выполняет полную диагностику сети для LocalSend
  static Future<NetworkDiagnosticResult> performFullDiagnostic() async {
    final result = NetworkDiagnosticResult();

    logInfo('Начинаем полную диагностику сети', tag: _logTag);

    // 1. Проверяем сетевые интерфейсы
    result.interfaces = await _checkNetworkInterfaces();

    // 2. Проверяем локальный IP
    result.localIp = await _getPreferredLocalIp();

    // 3. Проверяем доступность портов
    result.portAvailability = await _checkPortAvailability([8080, 8081, 8082]);

    // 4. Анализируем результаты
    result.issues = _analyzeResults(result);
    result.recommendations = _generateRecommendations(result);

    logInfo(
      'Диагностика завершена',
      tag: _logTag,
      data: {
        'interfaceCount': result.interfaces.length,
        'localIp': result.localIp,
        'issueCount': result.issues.length,
      },
    );

    return result;
  }

  /// Проверяет сетевые интерфейсы
  static Future<List<NetworkInterfaceInfo>> _checkNetworkInterfaces() async {
    final interfaces = <NetworkInterfaceInfo>[];

    try {
      final networkInterfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in networkInterfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            final info = NetworkInterfaceInfo(
              name: interface.name,
              ip: address.address,
              isPrivateRange: IpUtils.isValidForLocalConnection(
                address.address,
              ),
              isActive: !address.isLoopback,
            );
            interfaces.add(info);

            logDebug(
              'Найден сетевой интерфейс',
              tag: _logTag,
              data: {
                'name': interface.name,
                'ip': address.address,
                'isPrivate': info.isPrivateRange,
                'isActive': info.isActive,
              },
            );
          }
        }
      }
    } catch (e) {
      logError(
        'Ошибка при проверке сетевых интерфейсов',
        error: e,
        tag: _logTag,
      );
    }

    return interfaces;
  }

  /// Получает предпочтительный локальный IP
  static Future<String?> _getPreferredLocalIp() async {
    try {
      return await IpUtils.getBestLocalIpAddress();
    } catch (e) {
      logError('Ошибка получения предпочтительного IP', error: e, tag: _logTag);
      return null;
    }
  }

  /// Проверяет доступность портов
  static Future<Map<int, bool>> _checkPortAvailability(List<int> ports) async {
    final availability = <int, bool>{};

    for (final port in ports) {
      try {
        final serverSocket = await ServerSocket.bind(
          InternetAddress.anyIPv4,
          port,
        );
        await serverSocket.close();
        availability[port] = true;

        logDebug('Порт $port доступен', tag: _logTag);
      } catch (e) {
        availability[port] = false;
        logWarning('Порт $port занят', tag: _logTag);
      }
    }

    return availability;
  }

  /// Анализирует результаты диагностики
  static List<NetworkIssue> _analyzeResults(NetworkDiagnosticResult result) {
    final issues = <NetworkIssue>[];

    // Проверяем количество интерфейсов
    if (result.interfaces.isEmpty) {
      issues.add(
        NetworkIssue(
          severity: IssueSeverity.critical,
          title: 'Нет активных сетевых интерфейсов',
          description: 'Не найдены сетевые интерфейсы для LocalSend',
        ),
      );
    }

    // Проверяем наличие приватных IP
    final privateInterfaces = result.interfaces
        .where((i) => i.isPrivateRange)
        .toList();
    if (privateInterfaces.isEmpty && result.interfaces.isNotEmpty) {
      issues.add(
        NetworkIssue(
          severity: IssueSeverity.warning,
          title: 'Нет приватных IP адресов',
          description:
              'Все IP адреса являются публичными, что может препятствовать локальному подключению',
        ),
      );
    }

    // Проверяем доступность портов
    final unavailablePorts = result.portAvailability.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toList();

    if (unavailablePorts.isNotEmpty) {
      issues.add(
        NetworkIssue(
          severity: IssueSeverity.info,
          title: 'Некоторые порты заняты',
          description:
              'Порты $unavailablePorts недоступны, будут использованы альтернативные',
        ),
      );
    }

    // Проверяем подозрительные IP
    for (final interface in result.interfaces) {
      if (!interface.isPrivateRange && !interface.ip.startsWith('127.')) {
        issues.add(
          NetworkIssue(
            severity: IssueSeverity.warning,
            title: 'Публичный IP адрес: ${interface.ip}',
            description:
                'Этот адрес может быть недоступен для других устройств в локальной сети',
          ),
        );
      }
    }

    return issues;
  }

  /// Генерирует рекомендации
  static List<String> _generateRecommendations(NetworkDiagnosticResult result) {
    final recommendations = <String>[];

    if (result.interfaces.isEmpty) {
      recommendations.add('Проверьте подключение к сети Wi-Fi или Ethernet');
    }

    final privateInterfaces = result.interfaces
        .where((i) => i.isPrivateRange)
        .toList();
    if (privateInterfaces.length > 1) {
      recommendations.add(
        'Найдено несколько сетевых интерфейсов, выберите тот же, что использует целевое устройство',
      );
    }

    if (result.localIp == null) {
      recommendations.add(
        'Не удалось определить предпочтительный IP адрес, проверьте сетевые настройки',
      );
    } else if (result.localIp!.startsWith('169.254.')) {
      recommendations.add(
        'Обнаружен link-local адрес, это может указывать на проблемы с DHCP',
      );
    }

    final criticalIssues = result.issues.where(
      (i) => i.severity == IssueSeverity.critical,
    );
    if (criticalIssues.isEmpty) {
      recommendations.add('Сеть настроена корректно для LocalSend');
    }

    return recommendations;
  }
}

/// Результат диагностики сети
class NetworkDiagnosticResult {
  List<NetworkInterfaceInfo> interfaces = [];
  String? localIp;
  Map<int, bool> portAvailability = {};
  List<NetworkIssue> issues = [];
  List<String> recommendations = [];
}

/// Информация о сетевом интерфейсе
class NetworkInterfaceInfo {
  final String name;
  final String ip;
  final bool isPrivateRange;
  final bool isActive;

  NetworkInterfaceInfo({
    required this.name,
    required this.ip,
    required this.isPrivateRange,
    required this.isActive,
  });
}

/// Проблема сети
class NetworkIssue {
  final IssueSeverity severity;
  final String title;
  final String description;

  NetworkIssue({
    required this.severity,
    required this.title,
    required this.description,
  });
}

/// Уровень серьезности проблемы
enum IssueSeverity { info, warning, critical }
