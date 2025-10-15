import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_client_config.freezed.dart';
part 'auth_client_config.g.dart';

enum AuthClientType { google, onedrive, dropbox, yandex, icloud, other }

extension AuthClientTypeX on AuthClientType {
  String get name {
    switch (this) {
      case AuthClientType.google:
        return 'Google';
      case AuthClientType.onedrive:
        return 'OneDrive';
      case AuthClientType.dropbox:
        return 'Dropbox';
      case AuthClientType.icloud:
        return 'iCloud';
      case AuthClientType.yandex:
        return 'Yandex';
      case AuthClientType.other:
        return 'Other';
    }
  }

  String get identifier {
    switch (this) {
      case AuthClientType.google:
        return 'google';
      case AuthClientType.onedrive:
        return 'onedrive';
      case AuthClientType.dropbox:
        return 'dropbox';
      case AuthClientType.icloud:
        return 'icloud';
      case AuthClientType.yandex:
        return 'yandex';
      case AuthClientType.other:
        return 'other';
    }
  }

  static AuthClientType fromIdentifier(String identifier) {
    switch (identifier) {
      case 'google':
        return AuthClientType.google;
      case 'onedrive':
        return AuthClientType.onedrive;
      case 'dropbox':
        return AuthClientType.dropbox;
      case 'icloud':
        return AuthClientType.icloud;
      case 'yandex':
        return AuthClientType.yandex;
      default:
        return AuthClientType.other;
    }
  }

  // is active
  bool get isActive {
    switch (this) {
      case AuthClientType.google:
        return true;
      case AuthClientType.onedrive:
        return true;
      case AuthClientType.dropbox:
        return true;
      case AuthClientType.icloud:
        return false;
      case AuthClientType.yandex:
        return true;
      case AuthClientType.other:
        return false;
    }
  }
}

@freezed
sealed class AuthClientConfig with _$AuthClientConfig {
  const factory AuthClientConfig({
    required String id,
    required String name,
    required AuthClientType type,
    required String clientId,
    String? clientSecret,
    @Default(false) bool isBuiltin,
  }) = _AuthClientConfig;

  factory AuthClientConfig.fromJson(Map<String, dynamic> json) =>
      _$AuthClientConfigFromJson(json);
}
