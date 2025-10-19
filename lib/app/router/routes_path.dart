class AppRoutes {
  static const String splash = '/splash';
  static const String logs = '/logs';
  static const String setup = '/setup';
  static const String home = '/';
  static const String createStore = '/create-store';
  static const String openStore = '/open-store';
  static const String lockedDb = '/locked-db';
  static const String testDemo = '/test-demo';
  static const String dashboard = '/dashboard';
  static const String baseSettings = '/base-settings';

  // Dashboard nested routes (relative paths)
  static const String categoryManagerPath = 'category-manager';
  static const String categoryCreate = 'category-manager/create';
  static const String iconManagerPath = 'icon-manager';
  static const String iconCreate = 'icon-manager/create';
  static const String tagsManagerPath = 'tags-manager';
  static const String tagCreate = 'tags-manager/create';
  static const String passwordFormPath = 'password-form';
  static const String cloudSyncSetupPath = 'cloud-sync-setup';
  static const String passwordHistoryPath = 'password-history';
  static const String otpFormPath = 'otp-form';
  static const String notesFormPath = 'notes-form';
  static const String importOtpCodesPath = 'import-otp-codes';
  static const String passwordMigrationPath = 'password-migration';

  // Full paths for backward compatibility
  static const String categoryManager = '/dashboard/category-manager';
  static const String iconManager = '/dashboard/icon-manager';
  static const String tagsManager = '/dashboard/tags-manager';
  static const String passwordForm = '/dashboard/password-form';
  static const String cloudSyncSetup = '/dashboard/cloud-sync-setup';
  static const String passwordHistory = '/dashboard/password-history';
  static const String otpForm = '/dashboard/otp-form';
  static const String notesForm = '/dashboard/notes-form';
  static const String importOtpCodes = '/dashboard/import-otp-codes';
  static const String passwordMigration = '/dashboard/password-migration';

  static const String universalFilterDemo = '/universal-filter-demo';
  static const String localSend = '/localsend';
  static const String localSendTransfer = '/localsend/transfer';
  static const String qrScanner = '/qr-scanner';
  static const String qrTest = '/qr-test';
  static const String demoNotification = '/demo-notification';
  static const String settings = '/settings';
  static const String imageCrop = '/image-crop';
  static const String exportStorage = '/export-storage';
  static const String exportConfirm = '/export-storage/confirm';
  static const String importStorage = '/import-storage';
  static const String processImportedStore = '/process-imported-store';
  static const String manageCredential = '/manage-credential';
  static const String authManager = '/auth-manager';
  static const String authorizationProgress = '/authorization-progress';
}
