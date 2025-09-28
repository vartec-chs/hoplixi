import 'dart:io';
import 'package:hoplixi/core/logger/app_logger.dart';

/// Утилита для тестирования DNS резолюции .local адресов
class DNSTestUtil {
  static const String _logTag = 'DNSTest';

  /// Тестирует резолюцию .local адреса
  static Future<void> testLocalResolution(String hostname) async {
    try {
      logInfo(
        'Тестируем DNS резолюцию',
        tag: _logTag,
        data: {'hostname': hostname},
      );

      if (RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(hostname)) {
        logInfo('Адрес уже является IP', tag: _logTag);
        return;
      }

      if (hostname.endsWith('.local')) {
        logInfo('Резолюция .local адреса...', tag: _logTag);

        final addresses = await InternetAddress.lookup(
          hostname,
        ).timeout(const Duration(seconds: 5));

        if (addresses.isEmpty) {
          logWarning('Не найдено адресов', tag: _logTag);
          return;
        }

        logInfo(
          'Найденные адреса:',
          tag: _logTag,
          data: {
            'count': addresses.length,
            'addresses': addresses
                .map((a) => '${a.address} (${a.type})')
                .toList(),
          },
        );

        for (final address in addresses) {
          if (address.type == InternetAddressType.IPv4) {
            logInfo('IPv4 адрес:', tag: _logTag, data: {'ip': address.address});
          }
        }
      }
    } catch (e) {
      logError('Ошибка DNS резолюции', error: e, tag: _logTag);
    }
  }

  /// Тестирует доступность IP адреса по HTTP
  static Future<void> testHttpConnectivity(String ipAddress, int port) async {
    try {
      logInfo(
        'Тестируем HTTP подключение',
        tag: _logTag,
        data: {'ip': ipAddress, 'port': port},
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      // Сначала тестируем health endpoint
      try {
        final request = await client.getUrl(
          Uri.parse('http://$ipAddress:$port/health'),
        );
        final response = await request.close();

        logInfo(
          'HTTP health check успешен',
          tag: _logTag,
          data: {
            'statusCode': response.statusCode,
            'contentLength': response.contentLength,
          },
        );

        client.close();
        return;
      } catch (e) {
        logWarning(
          'Health endpoint недоступен, пробуем основной',
          tag: _logTag,
        );
      }

      // Если health не работает, пробуем основной endpoint
      final request = await client.getUrl(
        Uri.parse('http://$ipAddress:$port/'),
      );
      final response = await request.close();

      logInfo(
        'HTTP основной endpoint ответил',
        tag: _logTag,
        data: {
          'statusCode': response.statusCode,
          'contentLength': response.contentLength,
        },
      );

      client.close();
    } catch (e) {
      String errorType = 'Unknown error';
      String suggestion = 'Check network connectivity';

      if (e is SocketException) {
        if (e.message.contains('timed out')) {
          errorType = 'Connection timeout';
          suggestion = 'Device unreachable or no signaling server';
        } else if (e.message.contains('refused')) {
          errorType = 'Connection refused';
          suggestion = 'Signaling server not running on target';
        } else if (e.message.contains('No route')) {
          errorType = 'No route to host';
          suggestion = 'Devices on different networks';
        }
      }

      logError(
        'Ошибка HTTP подключения: $errorType',
        error: e,
        tag: _logTag,
        data: {
          'ip': ipAddress,
          'port': port,
          'errorType': errorType,
          'suggestion': suggestion,
        },
      );
    }
  }

  /// Показывает все сетевые интерфейсы
  static Future<void> showNetworkInterfaces() async {
    try {
      logInfo('Сетевые интерфейсы:', tag: _logTag);

      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );

      for (final interface in interfaces) {
        logInfo(
          'Интерфейс: ${interface.name}',
          tag: _logTag,
          data: {
            'addresses': interface.addresses.map((a) => a.address).toList(),
          },
        );
      }
    } catch (e) {
      logError('Ошибка получения сетевых интерфейсов', error: e, tag: _logTag);
    }
  }
}
