enum ProviderType { dropbox, google, microsoft, yandex, unknown }

extension ProviderTypeX on ProviderType {
  String get name {
    switch (this) {
      case ProviderType.dropbox:
        return 'Dropbox';
      case ProviderType.google:
        return 'Google';
      case ProviderType.microsoft:
        return 'Microsoft';
      case ProviderType.yandex:
        return 'Yandex';

      case ProviderType.unknown:
        return 'unknown';
    }
  }

  static ProviderType fromName(String name) {
    switch (name.toLowerCase()) {
      case 'dropbox':
        return ProviderType.dropbox;
      case 'google':
        return ProviderType.google;
      case 'microsoft':
        return ProviderType.microsoft;
      case 'yandex':
        return ProviderType.yandex;
      default:
        throw ArgumentError('Unknown provider name: $name');
    }
  }

  static ProviderType fromKey(String key) {
    if (key.toLowerCase().contains(ProviderType.dropbox.name.toLowerCase())) {
      return ProviderType.dropbox;
    } else if (key.toLowerCase().contains(
      ProviderType.google.name.toLowerCase(),
    )) {
      return ProviderType.google;
    } else if (key.toLowerCase().contains(
      ProviderType.microsoft.name.toLowerCase(),
    )) {
      return ProviderType.microsoft;
    } else if (key.toLowerCase().contains(
      ProviderType.yandex.name.toLowerCase(),
    )) {
      return ProviderType.yandex;
    } else {
      return ProviderType.unknown;
    }
  }
}
