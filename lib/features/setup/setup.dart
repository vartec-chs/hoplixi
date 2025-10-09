import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/app_preferences/index.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/colors.dart';
import 'package:hoplixi/features/global/widgets/button.dart';
import 'package:hoplixi/features/setup/providers/setup_provider.dart';
import 'package:hoplixi/features/setup/widgets/welcome_screen.dart';
import 'package:hoplixi/features/setup/widgets/theme_selection_screen.dart';
import 'package:hoplixi/features/setup/widgets/permissions_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'dart:async';

/// Главный экран setup процесса с навигацией между подэкранами
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int frameTime = 1000 ~/ 24;
  int total = 15 * 1000 ~/ (1000 ~/ 24);
  int progress = 0;

  ConfettiController? controller1;
  ConfettiController? controller2;
  bool isDone = false;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setupState = ref.watch(setupProvider);
    final pageController = ref.watch(pageControllerProvider);
    final permissionStates = ref.watch(permissionsProvider);

    logDebug(
      'Построение SetupScreen, текущий индекс: ${setupState.currentIndex}',
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Индикатор прогресса
            _buildProgressIndicator(context, ref, setupState, pageController),

            // Основной контент с PageView
            Expanded(
              child: PageView(
                
                controller: pageController,
                onPageChanged: (index) {
                  ref.read(setupProvider.notifier).goToScreen(index);
                },
                children: _buildPages(setupState.screens),
              ),
            ),

            // Навигационные кнопки
            _buildNavigationButtons(context, ref, setupState, permissionStates),
          ],
        ),
      ),
    );
  }

  /// Построение индикатора прогресса
  Widget _buildProgressIndicator(
    BuildContext context,
    WidgetRef ref,
    SetupState setupState,
    PageController pageController,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // Заголовок
          // Text(
          //   'Настройка приложения',
          //   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          //     fontWeight: FontWeight.bold,
          //     color: Theme.of(context).colorScheme.onBackground,
          //   ),
          // ),
          // const SizedBox(height: 16),

          // Индикатор страниц
          SmoothPageIndicator(
            controller: pageController,
            count: setupState.screens.length,
            effect: WormEffect(
              dotHeight: 12,
              dotWidth: 12,
              spacing: 16,
              activeDotColor: AppColors.lightColors.primary,
              dotColor: AppColors.lightColors.primary.withOpacity(0.3),
              paintStyle: PaintingStyle.fill,
            ),
            onDotClicked: (index) {
              ref.read(setupProvider.notifier).goToScreen(index);
            },
          ),

          const SizedBox(height: 4),

          // Текстовый индикатор
          Text(
            '${setupState.currentIndex + 1} из ${setupState.screens.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Построение списка страниц
  List<Widget> _buildPages(List<SetupScreenType> screens) {
    return screens.map((screenType) {
      switch (screenType) {
        case SetupScreenType.welcome:
          return const WelcomeScreen();
        case SetupScreenType.themeSelection:
          return const ThemeSelectionScreen();
        case SetupScreenType.permissions:
          return const PermissionsScreen();
      }
    }).toList();
  }

  /// Построение навигационных кнопок
  Widget _buildNavigationButtons(
    BuildContext context,
    WidgetRef ref,
    SetupState setupState,
    Map<Permission, PermissionStatus> permissionStates,
  ) {
    // Проверяем, все ли обязательные разрешения предоставлены
    final bool hasAllRequiredPermissions = _checkRequiredPermissions(
      permissionStates,
    );

    // На экране разрешений блокируем кнопку "Завершить", если не все обязательные разрешения даны
    final bool isPermissionsScreen =
        setupState.currentScreen == SetupScreenType.permissions;
    final bool canComplete = !isPermissionsScreen || hasAllRequiredPermissions;

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(4),
      child: Row(
        spacing: setupState.canGoPrevious ? 8 : 0,
        children: [
          // Кнопка "Назад"
          if (setupState.canGoPrevious)
            Expanded(
              child: SmoothButton(
                onPressed: () {
                  ref.read(setupProvider.notifier).previousScreen();
                },
                label: 'Назад',
                type: SmoothButtonType.outlined,
              ),
            ),

          // Кнопка "Далее" или "Завершить"
          Expanded(
            child: SmoothButton(
              onPressed: (setupState.canGoNext || canComplete)
                  ? () async {
                      if (setupState.canGoNext) {
                        ref.read(setupProvider.notifier).nextScreen();
                      } else {
                        await Prefs.set<bool>(Keys.isFirstRun, false);
                        _completeSetup(context, ref);
                      }
                    }
                  : null,
              label: setupState.canGoNext
                  ? 'Далее'
                  : (canComplete
                        ? 'Завершить'
                        : 'Требуются обязательные разрешения'),
              type: SmoothButtonType.filled,
              icon: setupState.canGoNext
                  ? Icon(Icons.arrow_forward)
                  : (canComplete ? Icon(Icons.check) : null),
              iconPosition: (canComplete
                  ? SmoothButtonIconPosition.start
                  : SmoothButtonIconPosition.end),
            ),
          ),
        ],
      ),
    );
  }

  /// Проверка обязательных разрешений
  bool _checkRequiredPermissions(
    Map<Permission, PermissionStatus> permissionStates,
  ) {
    // Список обязательных разрешений (должен соответствовать списку в PermissionsScreen)
    const requiredPermissions = [Permission.manageExternalStorage];

    return requiredPermissions.every(
      (permission) => permissionStates[permission] == PermissionStatus.granted,
    );
  }

  /// Завершение процесса setup
  void _completeSetup(BuildContext context, WidgetRef ref) {
    logDebug('Завершение setup процесса');

    // Запустить конфетти
    _startConfetti(context);

    // Отметить текущий экран как завершенный
    final setupState = ref.read(setupProvider);
    ref
        .read(setupProvider.notifier)
        .markScreenCompleted(setupState.currentScreen);

    // Показать диалог выбора действия с базой данных
    showDialog(
      context: context,
      barrierDismissible: false, // Не позволять закрыть диалог тапом вне

      builder: (BuildContext dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(16),
          title: const Text('Выбор базы данных'),
          content: const Text(
            'Хотите создать новую базу данных или открыть существующую?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            SmoothButton(
              isFullWidth: true,
              icon: Icon(Icons.add),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Prefs.set<bool>(Keys.isFirstRun, false);
                context.go(AppRoutes.createStore);
              },
              label: 'Создать',
              type: SmoothButtonType.filled,
            ),
            const SizedBox(height: 8),
            SmoothButton(
              isFullWidth: true,
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Prefs.set<bool>(Keys.isFirstRun, false);
                context.go(AppRoutes.openStore);
              },
              label: 'Открыть существующую',
              icon: Icon(Icons.folder_open),
              type: SmoothButtonType.outlined,
            ),
          ],
        );
      },
    );
  }

  /// Запуск конфетти анимации
  void _startConfetti(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.brightness == Brightness.light
        ? AppColors.darkColors.secondary
        : AppColors.lightColors.secondary;
    final colors = [theme.colorScheme.primary, secondary];
    progress = 0;
    isDone = false;

    timer = Timer.periodic(Duration(milliseconds: frameTime), (t) {
      progress++;

      if (progress >= total) {
        t.cancel();
        isDone = true;
        return;
      }
      if (controller1 == null) {
        controller1 = Confetti.launch(
          context,
          options: ConfettiOptions(
            particleCount: 2,
            angle: 60,
            spread: 55,
            x: 0,
            colors: colors,
          ),
          onFinished: (overlayEntry) {
            if (isDone) {
              overlayEntry.remove();
            }
          },
        );
      } else {
        controller1!.launch();
      }

      if (controller2 == null) {
        controller2 = Confetti.launch(
          context,
          options: ConfettiOptions(
            particleCount: 2,
            angle: 120,
            spread: 55,
            x: 1,
            colors: colors,
          ),
          onFinished: (overlayEntry) {
            if (isDone) {
              overlayEntry.remove();
            }
          },
        );
      } else {
        controller2!.launch();
      }
    });
  }
}
