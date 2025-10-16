/// Конфигурация OAuth2 провайдеров
/// Содержит списки scopes для различных облачных сервисов

class OAuth2ProviderConfig {
  OAuth2ProviderConfig._();

  /// Scopes для Dropbox API
  static const List<String> dropboxScopes = <String>[
    'account_info.read',
    'files.content.read',
    'files.content.write',
    'files.metadata.write',
    'files.metadata.read',
  ];

  /// Scopes для Yandex Disk API
  static const List<String> yandexScopes = <String>[
    'login:email',
    'login:info',
    'login:avatar',
    'cloud_api:disk.read',
    'cloud_api:disk.write',
    'cloud_api:disk.app_folder',
    'cloud_api:disk.info',
  ];

  /// Scopes для Google Drive API
  static const List<String> googleScopes = <String>[
    'https://www.googleapis.com/auth/drive.appdata',
    'https://www.googleapis.com/auth/drive.appfolder',
    'https://www.googleapis.com/auth/drive.install',
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.apps.readonly',
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/drive.readonly',
    'https://www.googleapis.com/auth/drive.activity',
    'https://www.googleapis.com/auth/drive.activity.readonly',
    'https://www.googleapis.com/auth/drive.meet.readonly',
    'https://www.googleapis.com/auth/drive.metadata',
    'https://www.googleapis.com/auth/drive.metadata.readonly',
    'https://www.googleapis.com/auth/drive.scripts',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  /// Scopes для Microsoft OneDrive API
  static const List<String> microsoftScopes = <String>[
    'User.Read',
    'User.ReadBasic.All',
    'email',
    'openid',
    'profile',
    'Files.Read',
    'Files.Read.All',
    'Files.ReadWrite',
    'Files.ReadWrite.All',
    'Files.ReadWrite.AppFolder',
    'Files.SelectedOperations.Selected',
    'offline_access',
  ];
}
