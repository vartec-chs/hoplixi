import 'package:hoplixi/core/index.dart';
import 'package:hoplixi/core/lib/oauth2restclient/oauth2restclient.dart';

class DropboxService {
  static const String _tag = 'DropboxService';
  
  static const String _rootPath = '/${MainConstants.appFolderName}';
  static const String _storages = '$_rootPath/storages';

  final OAuth2RestClient? _client;

  DropboxService(this._client);
}
