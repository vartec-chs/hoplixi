import 'dart:io';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Утилиты для работы с IP адресами и сетевыми соединениями
class IpUtils {
  static const String _logTag = 'IpUtils';

  /// Проверяет, является ли IP адрес приватным (локальным)
  static bool isPrivateIp(String ip) {
    try {
      final address = InternetAddress(ip);
      if (address.type != InternetAddressType.IPv4) return false;

      final parts = ip.split('.').map(int.tryParse).toList();
      if (parts.length != 4 || parts.contains(null)) return false;

      final a = parts[0]!;
      final b = parts[1]!;

      // 10.0.0.0/8
      if (a == 10) return true;

      // 172.16.0.0/12
      if (a == 172 && b >= 16 && b <= 31) return true;

      // 192.168.0.0/16
      if (a == 192 && b == 168) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Проверяет, является ли IP адрес локальным (loopback или link-local)
  static bool isLocalIp(String ip) {
    try {
      final address = InternetAddress(ip);
      if (address.isLoopback) return true;

      // Link-local (169.254.0.0/16)
      if (ip.startsWith('169.254.')) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Проверяет, является ли IP адрес валидным для локального соединения
  static bool isValidForLocalConnection(String ip) {
    return isPrivateIp(ip) || isLocalIp(ip);
  }

  /// Получает приоритет IP адреса для локальных соединений
  /// Более высокий приоритет = лучший адрес
  static int getIpPriority(String ip) {
    if (!isValidForLocalConnection(ip)) return 0;

    // 192.168.x.x - наивысший приоритет (домашние сети)
    if (ip.startsWith('192.168.')) return 100;

    // 10.x.x.x - корпоративные сети
    if (ip.startsWith('10.')) return 80;

    // 172.16-31.x.x - корпоративные сети
    if (ip.startsWith('172.')) {
      final parts = ip.split('.');
      if (parts.length >= 2) {
        final second = int.tryParse(parts[1]);
        if (second != null && second >= 16 && second <= 31) {
          return 75;
        }
      }
    }

    // 127.x.x.x - loopback
    if (ip.startsWith('127.')) return 50;

    // 169.254.x.x - link-local (APIPA)
    if (ip.startsWith('169.254.')) return 30;

    return 10; // Другие приватные
  }

  /// Сортирует список IP адресов по приоритету для локальных соединений
  static List<String> sortByPriority(List<String> ips) {
    final sorted = List<String>.from(ips);
    sorted.sort((a, b) => getIpPriority(b).compareTo(getIpPriority(a)));
    return sorted;
  }

  /// Фильтрует и сортирует IP адреса, оставляя только подходящие для локального соединения
  static List<String> filterAndSortForLocalConnection(List<String> ips) {
    final validIps = ips.where(isValidForLocalConnection).toList();
    return sortByPriority(validIps);
  }

  /// Получает лучший IP адрес из списка для локального соединения
  static String? getBestLocalIp(List<String> ips) {
    final sorted = filterAndSortForLocalConnection(ips);
    return sorted.isEmpty ? null : sorted.first;
  }

  /// Проверяет доступность порта на указанном IP
  static Future<bool> isPortReachable(
    String ip,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: timeout);
      await socket.close();
      return true;
    } catch (e) {
      logDebug(
        'Порт $ip:$port недоступен',
        tag: _logTag,
        data: {'error': e.toString()},
      );
      return false;
    }
  }

  /// Получает список всех локальных IP адресов устройства
  static Future<List<String>> getLocalIpAddresses() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      final ips = <String>[];
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4) {
            ips.add(address.address);
          }
        }
      }

      return ips;
    } catch (e) {
      logError('Ошибка получения локальных IP адресов', error: e, tag: _logTag);
      return [];
    }
  }

  /// Получает лучший локальный IP адрес для исходящих соединений
  static Future<String?> getBestLocalIpAddress() async {
    final ips = await getLocalIpAddresses();
    return getBestLocalIp(ips);
  }

  /// Проверяет, находятся ли два IP в одной подсети
  static bool areInSameSubnet(String ip1, String ip2, String subnetMask) {
    try {
      final addr1 = InternetAddress(ip1);
      final addr2 = InternetAddress(ip2);
      final mask = InternetAddress(subnetMask);

      if (addr1.type != InternetAddressType.IPv4 ||
          addr2.type != InternetAddressType.IPv4 ||
          mask.type != InternetAddressType.IPv4) {
        return false;
      }

      final parts1 = ip1.split('.').map(int.parse).toList();
      final parts2 = ip2.split('.').map(int.parse).toList();
      final maskParts = subnetMask.split('.').map(int.parse).toList();

      for (int i = 0; i < 4; i++) {
        if ((parts1[i] & maskParts[i]) != (parts2[i] & maskParts[i])) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Проверяет, находятся ли два IP в типичных домашних подсетях
  static bool areInSameTypicalSubnet(String ip1, String ip2) {
    // Проверяем типичные маски подсетей
    const commonMasks = [
      '255.255.255.0', // /24
      '255.255.0.0', // /16
      '255.0.0.0', // /8
    ];

    for (final mask in commonMasks) {
      if (areInSameSubnet(ip1, ip2, mask)) {
        return true;
      }
    }

    return false;
  }

  /// Диагностирует проблемы с IP адресом
  static IpDiagnostic diagnoseIp(String ip) {
    final issues = <String>[];
    final recommendations = <String>[];

    if (!isValidForLocalConnection(ip)) {
      issues.add('IP адрес не подходит для локального соединения');
      recommendations.add(
        'Убедитесь, что устройства подключены к одной локальной сети',
      );
    }

    if (ip.startsWith('169.254.')) {
      issues.add('Используется APIPA адрес (link-local)');
      recommendations.add('Проверьте настройки DHCP сервера в вашей сети');
    }

    if (ip.startsWith('127.')) {
      issues.add('Используется loopback адрес');
      recommendations.add(
        'Этот адрес работает только локально на том же устройстве',
      );
    }

    final priority = getIpPriority(ip);
    if (priority < 50) {
      recommendations.add(
        'Рассмотрите возможность использования другого сетевого интерфейса',
      );
    }

    return IpDiagnostic(
      ip: ip,
      isValid: isValidForLocalConnection(ip),
      priority: priority,
      issues: issues,
      recommendations: recommendations,
    );
  }

  /// Генерирует отчет о сетевых адресах для диагностики
  static Future<NetworkAddressReport> generateNetworkReport() async {
    final localIps = await getLocalIpAddresses();
    final diagnostics = localIps.map(diagnoseIp).toList();
    final bestIp = getBestLocalIp(localIps);

    return NetworkAddressReport(
      localIps: localIps,
      bestIp: bestIp,
      diagnostics: diagnostics,
    );
  }
}

/// Результат диагностики IP адреса
class IpDiagnostic {
  final String ip;
  final bool isValid;
  final int priority;
  final List<String> issues;
  final List<String> recommendations;

  const IpDiagnostic({
    required this.ip,
    required this.isValid,
    required this.priority,
    required this.issues,
    required this.recommendations,
  });
}

/// Отчет о сетевых адресах
class NetworkAddressReport {
  final List<String> localIps;
  final String? bestIp;
  final List<IpDiagnostic> diagnostics;

  const NetworkAddressReport({
    required this.localIps,
    required this.bestIp,
    required this.diagnostics,
  });
}
