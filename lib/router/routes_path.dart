class AppRoutes {
  static const String splash = '/splash';
  static const String logs = '/logs';
  static const String setup = '/setup';
  static const String home = '/';
  static const String createStore = '/create-store';
  static const String openStore = '/open-store';
  static const String testDemo = '/test-demo';
  static const String dashboard = '/dashboard';
  static const String passwordManager = '/password-manager';
  static const String baseSettings = '/base-settings';
  static const String categoryManager = '/category-manager';
  static const String categoryCreate = '/category-manager/create';
  static const String iconManager = '/icon-manager';
  static const String iconCreate = '/icon-manager/create';
  static const String tagsManager = '/tags-manager';
  static const String tagCreate = '/tags-manager/create';
  static const String passwordForm = '/password-form';
  static const String passwordHistory = '/password-history';
  static const String universalFilterDemo = '/universal-filter-demo';
  static const String localSend = '/localsend';
  static const String localSendTransfer = '/localsend/transfer';
  static const String qrScanner = '/qr-scanner';
  static const String qrTest = '/qr-test';
  static const String otpForm = '/otp-form';
  static const String demoNotification = '/demo-notification';
  static const String notesForm = '/notes-form';
}

class ProtectedRoutes {
  static const List<String> routes = [
    AppRoutes.dashboard,
    AppRoutes.categoryManager,
    AppRoutes.tagsManager,
    AppRoutes.passwordForm,
    AppRoutes.passwordHistory,
    AppRoutes.universalFilterDemo,
    AppRoutes.notesForm,
    AppRoutes.otpForm,
    // Добавьте другие защищённые маршруты сюда
  ];
}
