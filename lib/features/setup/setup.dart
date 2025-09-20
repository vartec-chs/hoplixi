import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/colors.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/features/setup/providers/setup_provider.dart';
import 'package:hoplixi/features/setup/widgets/welcome_screen.dart';
import 'package:hoplixi/features/setup/widgets/theme_selection_screen.dart';
import 'package:hoplixi/features/setup/widgets/permissions_screen.dart';

/// Главный экран setup процесса с навигацией между подэкранами
class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
    final pageController = ref.watch(pageControllerProvider);

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
            _buildNavigationButtons(context, ref, setupState),
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
      padding: const EdgeInsets.all(20),
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

          const SizedBox(height: 8),

          // Текстовый индикатор
          Text(
            '${setupState.currentIndex + 1} из ${setupState.screens.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onBackground.withOpacity(0.7),
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
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
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

          if (setupState.canGoPrevious && setupState.canGoNext)
            const SizedBox(width: 16),

          // Кнопка "Далее" или "Завершить"
          Expanded(
            child: SmoothButton(
              onPressed: () {
                if (setupState.canGoNext) {
                  ref.read(setupProvider.notifier).nextScreen();
                } else {
                  _completeSetup(context, ref);
                }
              },
              label: setupState.canGoNext ? 'Далее' : 'Завершить',
              type: SmoothButtonType.filled,
            ),
          ),
        ],
      ),
    );
  }

  /// Завершение процесса setup
  void _completeSetup(BuildContext context, WidgetRef ref) {
    logDebug('Завершение setup процесса');

    // Отметить текущий экран как завершенный
    final setupState = ref.read(setupProvider);
    ref
        .read(setupProvider.notifier)
        .markScreenCompleted(setupState.currentScreen);

    // Здесь можно добавить логику перехода к основному экрану приложения
    // Например, навигация с помощью GoRouter
    Navigator.of(context).pushReplacementNamed('/main');
  }
}
