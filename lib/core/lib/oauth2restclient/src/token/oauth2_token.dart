import 'dart:convert';

abstract interface class OAuth2Token {
  String get accessToken;
  String get refreshToken;
  String get userName;
  String get iss;
  bool get timeToRefresh;
  bool get canRefresh;
  bool get timeToLogin;
  String toJsonString();
  OAuth2Token mergeToken(OAuth2Token newToken);
}

class OAuth2TokenF implements OAuth2Token {
  final Map<String, dynamic> json;
  Map<String, dynamic>? _idToken;

  Map<String, dynamic>? get idToken {
    return _idToken ??= _tryDecodeIdToken(json["id_token"]);
  }

  OAuth2TokenF(this.json) {
    _parseToken(json);
  }

  void _parseToken(Map<String, dynamic> json) {
    if (!json.containsKey("expiry")) {
      if (json.containsKey("expires_in")) {
        json["expiry"] = DateTime.now()
            .toUtc()
            .add(Duration(seconds: json["expires_in"]))
            .subtract(Duration(minutes: 5))
            .toIso8601String();
      } else {
        json["expiry"] = "9999-12-31T23:59:59.999Z";
      }
    }

    if (!json.containsKey("refresh_token_expiry")) {
      if (json.containsKey("refresh_token_expires_in")) {
        json["refresh_token_expiry"] = DateTime.now()
            .toUtc()
            .add(Duration(seconds: json["refresh_token_expires_in"]))
            .subtract(Duration(minutes: 5))
            .toIso8601String();
      } else {
        json["refresh_token_expiry"] = "9999-12-31T23:59:59.999Z";
      }
    }
  }

  Map<String, dynamic> _tryDecodeIdToken(String? idToken) {
    if (idToken?.isEmpty ?? true) return {};

    final parts = idToken!.split('.');
    if (parts.length != 3) {
      throw Exception("🚨 ID Token 형식 오류");
    }
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    return jsonDecode(payload);
  }

  DateTime? _expiry;
  DateTime get expiry {
    return _expiry ??= DateTime.parse(json["expiry"]);
  }

  DateTime? _refreshTokenExpiry;
  DateTime get refreshTokenExpiry {
    return _refreshTokenExpiry ??= DateTime.parse(json["refresh_token_expiry"]);
  }

  @override
  bool get timeToRefresh {
    var now = DateTime.now().toUtc();
    return now.isAfter(expiry);
  }

  @override
  bool get canRefresh {
    if (refreshToken.isEmpty) return false;
    var now = DateTime.now().toUtc();
    return now.isBefore(refreshTokenExpiry.subtract(Duration(minutes: 5)));
  }

  @override
  bool get timeToLogin {
    return timeToRefresh && canRefresh;
  }

  factory OAuth2TokenF.fromJsonString(String jsonResponse) {
    final jsonMap = jsonDecode(jsonResponse);
    return OAuth2TokenF(jsonMap);
  }

  @override
  String toJsonString() {
    return jsonEncode(json);
  }

  @override
  String get accessToken => json["access_token"] ?? "";

  @override
  String get refreshToken => json["refresh_token"] ?? "";

  @override
  String get iss => json["iss"] ?? idToken?["iss"] ?? "";

  @override
  String get userName =>
      json["user_name"] ??
      idToken?["email"] ??
      idToken?["sub"] ??
      json["uid"] ?? // Yandex использует uid
      json["account_id"] ?? // Dropbox использует account_id
      "";

  @override
  OAuth2Token mergeToken(OAuth2Token newToken) {
    var jsonString = newToken.toJsonString();
    var newJson = jsonDecode(jsonString);
    Map<String, dynamic> mergedToken = {
      ...json, // 기존 값 유지
      ...newJson, // 새로운 값 덮어쓰기
    };

    // Гарантируем, что iss и userName ВСЕГДА присутствуют
    final currentIss = json['iss'] ?? iss;
    final currentUserName = json['user_name'] ?? userName;

    if (currentIss.isNotEmpty) {
      mergedToken['iss'] = currentIss;
    }
    if (currentUserName.isNotEmpty) {
      mergedToken['user_name'] = currentUserName;
    }

    return OAuth2TokenF(mergedToken);
  }
}
