import 'package:freezed_annotation/freezed_annotation.dart';

part 'credential_app.freezed.dart';
part 'credential_app.g.dart';

enum CredentialOAuthType { google, onedrive, dropbox, yandex, icloud, other }

extension CredentialOAuthTypeX on CredentialOAuthType {
  String get name {
    switch (this) {
      case CredentialOAuthType.google:
        return 'Google';
      case CredentialOAuthType.onedrive:
        return 'OneDrive';
      case CredentialOAuthType.dropbox:
        return 'Dropbox';
      case CredentialOAuthType.icloud:
        return 'iCloud';
      case CredentialOAuthType.yandex:
        return 'Yandex';
      case CredentialOAuthType.other:
        return 'Other';
    }
  }

  String get identifier {
    switch (this) {
      case CredentialOAuthType.google:
        return 'google';
      case CredentialOAuthType.onedrive:
        return 'onedrive';
      case CredentialOAuthType.dropbox:
        return 'dropbox';
      case CredentialOAuthType.icloud:
        return 'icloud';
      case CredentialOAuthType.yandex:
        return 'yandex';
      case CredentialOAuthType.other:
        return 'other';
    }
  }

  static CredentialOAuthType fromIdentifier(String identifier) {
    switch (identifier) {
      case 'google':
        return CredentialOAuthType.google;
      case 'onedrive':
        return CredentialOAuthType.onedrive;
      case 'dropbox':
        return CredentialOAuthType.dropbox;
      case 'icloud':
        return CredentialOAuthType.icloud;
      case 'yandex':
        return CredentialOAuthType.yandex;
      default:
        return CredentialOAuthType.other;
    }
  }

  // is active
  bool get isActive {
    switch (this) {
      case CredentialOAuthType.google:
        return false;
      case CredentialOAuthType.onedrive:
        return false;
      case CredentialOAuthType.dropbox:
        return true;
      case CredentialOAuthType.icloud:
        return false;
      case CredentialOAuthType.yandex:
        return true;
      case CredentialOAuthType.other:
        return false;
    }
  }
}

@freezed
abstract class CredentialApp with _$CredentialApp {
  const factory CredentialApp({
    required String id,
    required String name,
    required CredentialOAuthType type,
    required String clientId,
    required String clientSecret,
  }) = _CredentialApp;

  factory CredentialApp.fromJson(Map<String, dynamic> json) =>
      _$CredentialAppFromJson(json);
}
