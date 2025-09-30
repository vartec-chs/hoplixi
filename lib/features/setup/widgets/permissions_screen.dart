import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/colors.dart';
import 'package:hoplixi/core/utils/toastification.dart';
import 'package:hoplixi/features/global/widgets/button.dart';

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
    try {
      final status = await permission.request();
      state = {...state, permission: status};
    } catch (e) {
      // В случае ошибки (например, отмена пользователем) сохраняем текущий статус
      final errorMessage = e.toString();
      logDebug('Ошибка при запросе разрешения $permission: $errorMessage');

      // Дополнительное логирование для специфичных случаев
      if (errorMessage.contains('PHASE_CLIENT_ALREADY_HIDDEN')) {
        logDebug(
          'Обнаружена отмена на этапе PHASE_CLIENT_ALREADY_HIDDEN для $permission',
        );
      } else if (errorMessage.contains('onCancelled')) {
        logDebug('Обнаружена отмена пользователем для $permission');
      }

      final currentStatus = await permission.status;
      state = {...state, permission: currentStatus};
      rethrow; // Перебрасываем исключение для обработки в UI
    }
  }

  /// Запросить все разрешения
  Future<void> requestAllPermissions(List<Permission> permissions) async {
    for (final permission in permissions) {
      try {
        await requestPermission(permission);
      } catch (e) {
        // Продолжаем запрашивать остальные разрешения даже если одно было отменено
        final errorMessage = e.toString();
        logDebug(
          'Пропускаем разрешение $permission из-за ошибки: $errorMessage',
        );

        if (errorMessage.contains('PHASE_CLIENT_ALREADY_HIDDEN')) {
          logDebug(
            'Разрешение $permission отменено на этапе PHASE_CLIENT_ALREADY_HIDDEN',
          );
        } else if (errorMessage.contains('onCancelled')) {
          logDebug('Разрешение $permission отменено пользователем');
        }

        continue;
      }
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
      permission: Permission.manageExternalStorage,
      title: 'Доступ к файлам',
      description: 'Для сохранения и импорта/экспорта данных паролей',
      icon: Icons.folder_rounded,
      isRequired: true,
    ),
    PermissionItem(
      permission: Permission.audio,
      title: 'Аудио',
      description: 'Для воспроизведения аудио в приложении',
      icon: Icons.audio_file,
      isRequired: false,
    ),
    PermissionItem(
      permission: Permission.bluetooth,
      title: 'Bluetooth',
      description: 'Для подключения к устройствам Bluetooth',
      icon: Icons.bluetooth,
      isRequired: false,
    ),
    PermissionItem(
      permission: Permission.photos,
      title: 'Доступ к фотографиям',
      description: 'Для назначения иконок из галереи',
      icon: Icons.photo_library_rounded,
      isRequired: false,
    ),
    PermissionItem(
      permission: Permission.camera,
      title: 'Доступ к камере',
      description: 'Для сканирования QR-кодов',
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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

                    const SizedBox(height: 10),

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
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        // Кнопка "Запросить все"
        SmoothButton(
          onPressed: _requestAllPermissions,
          label: 'Запросить все',
          type: SmoothButtonType.filled,
          isFullWidth: true,
        ),

        // Информационное сообщение о статусе разрешений
        if (!hasAllRequired)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Для завершения настройки требуются обязательные разрешения',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Все обязательные разрешения предоставлены',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
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
      try {
        await ref
            .read(permissionsProvider.notifier)
            .requestPermission(permission);

        final newStatus = await permission.status;
        if (newStatus.isGranted) {
          ToastHelper.success(title: 'Разрешение предоставлено');
        } else if (newStatus.isDenied) {
          ToastHelper.warning(title: 'Разрешение отклонено');
        } else if (newStatus == PermissionStatus.restricted) {
          ToastHelper.error(title: 'Разрешение ограничено системой');
        } else if (newStatus.isPermanentlyDenied) {
          ToastHelper.error(
            title: 'Разрешение отклонено навсегда',
            description:
                'Пожалуйста, предоставьте его в настройках приложения.',
          );
        } else if (newStatus.isLimited) {
          ToastHelper.info(title: 'Разрешение предоставлено частично');
        } else if (newStatus == PermissionStatus.denied) {
          ToastHelper.warning(title: 'Разрешение отклонено');
        } else {
          ToastHelper.info(title: 'Статус разрешения изменен');
        }
      } catch (e) {
        // Обработка случая отмены пользователем (PHASE_CLIENT_ALREADY_HIDDEN)
        final errorMessage = e.toString();
        logDebug('Ошибка при запросе разрешения $permission: $errorMessage');

        if (errorMessage.contains('PHASE_CLIENT_ALREADY_HIDDEN')) {
          // Пользователь отменил запрос после скрытия диалога
          logDebug(
            'Пользователь отменил запрос разрешения $permission на этапе PHASE_CLIENT_ALREADY_HIDDEN',
          );
          ToastHelper.info(title: 'Запрос разрешения отменен пользователем');
        } else if (errorMessage.contains('onCancelled')) {
          // Общая отмена пользователем
          logDebug('Пользователь отменил запрос разрешения $permission');
          ToastHelper.info(title: 'Запрос разрешения отменен');
        } else if (errorMessage.contains('Permission denied')) {
          // Разрешение отклонено системой
          logDebug('Разрешение $permission отклонено системой');
          ToastHelper.warning(title: 'Разрешение отклонено системой');
        } else {
          // Неизвестная ошибка
          logDebug(
            'Неизвестная ошибка при запросе разрешения $permission: $errorMessage',
          );
          ToastHelper.error(title: 'Ошибка при запросе разрешения');
        }
      }
    }
  }

  void _requestAllPermissions() async {
    logDebug('Запрос всех разрешений');

    final permissions = _permissions.map((p) => p.permission).toList();

    try {
      await ref
          .read(permissionsProvider.notifier)
          .requestAllPermissions(permissions);

      ToastHelper.info(title: 'Проверка разрешений завершена');
    } catch (e) {
      final errorMessage = e.toString();
      logDebug('Ошибка при запросе всех разрешений: $errorMessage');

      if (errorMessage.contains('PHASE_CLIENT_ALREADY_HIDDEN')) {
        logDebug(
          'Пользователь отменил запрос разрешений на этапе PHASE_CLIENT_ALREADY_HIDDEN',
        );
        ToastHelper.info(title: 'Запрос разрешений отменен пользователем');
      } else if (errorMessage.contains('onCancelled')) {
        logDebug('Пользователь отменил запрос разрешений');
        ToastHelper.info(title: 'Запрос разрешений отменен');
      } else {
        logDebug('Неизвестная ошибка при запросе разрешений: $errorMessage');
        ToastHelper.warning(title: 'Не все разрешения были обработаны');
      }
    }
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
