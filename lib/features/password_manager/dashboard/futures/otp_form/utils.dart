import 'dart:convert';

class OtpUri {
  final String type; // totp или hotp
  final String issuer;
  final String account;
  final String secret; // оригинальный секрет
  final String decodedSecret; // декодированный секрет, если был в Base64
  final bool isBase64; // был ли секрет в Base64
  final String algorithm;
  final String digits;
  final String period;
  final String counter;
  final String secretBase64; // секрет в Base64

  OtpUri({
    required this.type,
    required this.issuer,
    required this.account,
    required this.secret,
    required this.decodedSecret,
    required this.isBase64,
    required this.algorithm,
    required this.digits,
    required this.period,
    required this.counter,
    this.secretBase64 = '',
  });

  @override
  String toString() {
    return 'OtpUri(type: $type, issuer: $issuer, account: $account, secret: $secret, decodedSecret: $decodedSecret, isBase64: $isBase64, algorithm: $algorithm, digits: $digits, period: $period, counter: $counter, secretBase64: $secretBase64)';
  }
}

OtpUri parseOtpUri(String uri) {
  final RegExp regex = RegExp(
    r'^otpauth://(?<type>totp|hotp)/(?<label>[^?]+)\??(?<query>.*)$',
    caseSensitive: false,
  );

  final match = regex.firstMatch(uri);
  if (match == null) {
    return OtpUri(
      type: '',
      issuer: '',
      account: '',
      secret: '',
      decodedSecret: '',
      isBase64: false,
      algorithm: '',
      digits: '',
      period: '',
      counter: '',
    );
  }

  final type = match.namedGroup('type') ?? '';
  final label = match.namedGroup('label') ?? '';
  final query = match.namedGroup('query') ?? '';

  // Разделяем label на issuer и account, если есть ":"
  String issuer = '';
  String account = label;
  if (label.contains(':')) {
    final parts = label.split(':');
    issuer = parts[0];
    account = parts.sublist(1).join(':');
  }

  // Парсим query параметры
  final Map<String, String> params = {};
  for (final param in query.split('&')) {
    final kv = param.split('=');
    if (kv.length == 2) {
      params[kv[0]] = Uri.decodeComponent(kv[1]);
    }
  }

  // issuer из query, если есть
  if (params.containsKey('issuer')) {
    issuer = params['issuer']!;
  }

  // Проверка Base64 и декодирование
  String secret = params['secret'] ?? '';
  String decodedSecret = secret;
  bool isBase64 = false;

  try {
    final bytes = base64.decode(secret);
    decodedSecret = utf8.decode(bytes);
    isBase64 = true;
  } catch (e) {
    // Не Base64, оставляем как есть
  }

  return OtpUri(
    type: type,
    issuer: issuer,
    account: account,
    secret: secret, // оригинальный
    decodedSecret: decodedSecret, // декодированный, если Base64
    isBase64: isBase64,
    algorithm: params['algorithm'] ?? '',
    digits: params['digits'] ?? '',
    period: params['period'] ?? '',
    counter: params['counter'] ?? '',
    secretBase64: base64.encode(utf8.encode(secret)),
  );
}
