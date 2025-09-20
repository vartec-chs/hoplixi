import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/colors.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/features/setup/providers/setup_provider.dart';

/// Модель разрешения
class PermissionItem {
  final Permission permission;
  final String title;
  final String description;
  final IconData icon;
  final bool isRequired;

  const PermissionItem({
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    this.isRequired = true,
  });
}

/// Провайдер для управления состоянием разрешений
final permissionsProvider =
    NotifierProvider<PermissionsNotifier, Map<Permission, PermissionStatus>>(
      () {
        return PermissionsNotifier();
      },
    );

class PermissionsNotifier extends Notifier<Map<Permission, PermissionStatus>> {
  @override
  Map<Permission, PermissionStatus> build() {
    return {};
  }

  /// Проверить статус всех разрешений
  Future<void> checkPermissions(List<Permission> permissions) async {
    final Map<Permission, PermissionStatus> statuses = {};

    for (final permission in permissions) {
      statuses[permission] = await permission.status;
    }

    state = statuses;
  }

  /// Запросить конкретное разрешение
  Future<void> requestPermission(Permission permission) async {
    final status = await permission.request();
    state = {...state, permission: status};
  }

  /// Запросить все разрешения
  Future<void> requestAllPermissions(List<Permission> permissions) async {
    for (final permission in permissions) {
      await requestPermission(permission);
    }
  }
}

/// Экран запроса разрешений
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Список требуемых разрешений
  static const List<PermissionItem> _permissions = [
    PermissionItem(
      permission: Permission.storage,
      title: 'Доступ к файлам',
      description: 'Для сохранения и импорта/экспорта данных паролей',
      icon: Icons.folder_rounded,
      isRequired: true,
    ),
    PermissionItem(
      permission: Permission.photos,
      title: 'Доступ к фотографиям',
      description: 'Для сохранения и загрузки изображений профилей и аватаров',
      icon: Icons.photo_library_rounded,
      isRequired: false,
    ),
    PermissionItem(
      permission: Permission.camera,
      title: 'Доступ к камере',
      description: 'Для сканирования QR-кодов и съёмки фотографий профилей',
      icon: Icons.camera_alt_rounded,
      isRequired: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _checkInitialPermissions();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
  }

  void _startAnimations() async {
    logDebug('Запуск анимаций экрана разрешений');

    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    _fadeController.forward();
  }

  void _checkInitialPermissions() async {
    final permissions = _permissions.map((p) => p.permission).toList();
    await ref.read(permissionsProvider.notifier).checkPermissions(permissions);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permissionStates = ref.watch(permissionsProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightColors.primary.withOpacity(0.05),
              AppColors.lightColors.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Заголовок
                    _buildHeader(),

                    const SizedBox(height: 40),

                    // Список разрешений
                    Expanded(
                      child: ListView.separated(
                        itemCount: _permissions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final permissionItem = _permissions[index];
                          final status =
                              permissionStates[permissionItem.permission];

                          return _buildPermissionCard(
                            permissionItem: permissionItem,
                            status: status,
                            delay: index * 100,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Кнопки действий
                    _buildActionButtons(permissionStates),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.lightColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppColors.lightColors.primary.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.security_rounded,
            size: 40,
            color: AppColors.lightColors.primary,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Разрешения',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Для корректной работы приложения необходимо предоставить следующие разрешения',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPermissionCard({
    required PermissionItem permissionItem,
    required PermissionStatus? status,
    required int delay,
  }) {
    final isGranted = status == PermissionStatus.granted;
    final isPermanentlyDenied = status == PermissionStatus.permanentlyDenied;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isGranted
                      ? Colors.green.withOpacity(0.3)
                      : Theme.of(context).dividerColor.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Иконка разрешения
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isGranted
                          ? Colors.green.withOpacity(0.1)
                          : AppColors.lightColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      permissionItem.icon,
                      size: 24,
                      color: isGranted
                          ? Colors.green
                          : AppColors.lightColors.primary,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Контент
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                permissionItem.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                              ),
                            ),
                            if (permissionItem.isRequired)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Требуется',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          permissionItem.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Статус и кнопка
                  if (isGranted)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Colors.green,
                      ),
                    )
                  else
                    SmoothButton(
                      onPressed: () =>
                          _requestPermission(permissionItem.permission),
                      label: isPermanentlyDenied ? 'Настройки' : 'Разрешить',
                      type: SmoothButtonType.outlined,
                      size: SmoothButtonSize.small,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    Map<Permission, PermissionStatus> permissionStates,
  ) {
    final requiredPermissions = _permissions
        .where((p) => p.isRequired)
        .toList();
    final hasAllRequired = requiredPermissions.every(
      (p) => permissionStates[p.permission] == PermissionStatus.granted,
    );

    return Column(
      children: [
        // Кнопка "Запросить все"
        SmoothButton(
          onPressed: _requestAllPermissions,
          label: 'Запросить все разрешения',
          type: SmoothButtonType.filled,
          isFullWidth: true,
        ),

        const SizedBox(height: 12),

        // Кнопка "Продолжить"
        SmoothButton(
          onPressed: hasAllRequired ? _completePermissions : null,
          label: hasAllRequired
              ? 'Продолжить'
              : 'Требуются обязательные разрешения',
          type: hasAllRequired
              ? SmoothButtonType.tonal
              : SmoothButtonType.outlined,
          isFullWidth: true,
        ),
      ],
    );
  }

  void _requestPermission(Permission permission) async {
    logDebug('Запрос разрешения: $permission');

    final status = await permission.status;

    if (status.isPermanentlyDenied) {
      // Показать диалог для перехода в настройки
      _showSettingsDialog();
    } else {
      await ref
          .read(permissionsProvider.notifier)
          .requestPermission(permission);

      final newStatus = await permission.status;
      if (newStatus.isGranted) {
        ToastHelper.success(title: 'Разрешение предоставлено');
      } else if (newStatus.isDenied) {
        ToastHelper.warning(title: 'Разрешение отклонено');
      }
    }
  }

  void _requestAllPermissions() async {
    logDebug('Запрос всех разрешений');

    final permissions = _permissions.map((p) => p.permission).toList();
    await ref
        .read(permissionsProvider.notifier)
        .requestAllPermissions(permissions);

    ToastHelper.info(title: 'Проверка разрешений завершена');
  }

  void _completePermissions() {
    logDebug('Завершение настройки разрешений');

    ref
        .read(setupProvider.notifier)
        .markScreenCompleted(SetupScreenType.permissions);
    ToastHelper.success(title: 'Настройка разрешений завершена');
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Требуется разрешение'),
        content: const Text(
          'Разрешение было отклонено навсегда. Пожалуйста, предоставьте его в настройках приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Настройки'),
          ),
        ],
      ),
    );
  }
}
