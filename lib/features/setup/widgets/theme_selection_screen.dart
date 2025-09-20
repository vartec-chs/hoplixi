import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/core/logger/app_logger.dart';
import 'package:hoplixi/core/theme/colors.dart';
import 'package:hoplixi/core/theme/theme_provider.dart';
import 'package:hoplixi/features/setup/providers/setup_provider.dart';

/// Экран выбора темы приложения
class ThemeSelectionScreen extends ConsumerStatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  ConsumerState<ThemeSelectionScreen> createState() =>
      _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends ConsumerState<ThemeSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
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
    logDebug('Запуск анимаций экрана выбора темы');

    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(themeProvider);

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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Заголовок
                      _buildHeader(),

                      const SizedBox(height: 60),

                      // Карточки выбора темы
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: themeAsync.when(
                          data: (currentTheme) => [
                            _buildThemeCard(
                              title: 'Светлая тема',
                              description:
                                  'Классический светлый интерфейс для комфортной работы днём',
                              icon: Icons.light_mode_rounded,
                              themeMode: ThemeMode.light,
                              currentTheme: currentTheme,
                              delay: 0,
                            ),

                            const SizedBox(height: 24),

                            _buildThemeCard(
                              title: 'Тёмная тема',
                              description:
                                  'Современный тёмный интерфейс для работы в условиях слабого освещения',
                              icon: Icons.dark_mode_rounded,
                              themeMode: ThemeMode.dark,
                              currentTheme: currentTheme,
                              delay: 200,
                            ),

                            const SizedBox(height: 24),

                            _buildThemeCard(
                              title: 'Системная тема',
                              description:
                                  'Автоматическое переключение в зависимости от настроек устройства',
                              icon: Icons.auto_mode_rounded,
                              themeMode: ThemeMode.system,
                              currentTheme: currentTheme,
                              delay: 400,
                            ),

                            // Дополнительное пространство в конце для лучшей прокрутки
                            const SizedBox(height: 40),
                          ],
                          loading: () => [
                            const Center(child: CircularProgressIndicator()),
                          ],
                          error: (error, stack) => [
                            Text('Ошибка загрузки темы: $error'),
                          ],
                        ),
                      ),
                    ],
                  ),
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
            Icons.palette_rounded,
            size: 40,
            color: AppColors.lightColors.primary,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Выберите тему',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Настройте внешний вид приложения под свои предпочтения',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String description,
    required IconData icon,
    required ThemeMode themeMode,
    required ThemeMode currentTheme,
    required int delay,
  }) {
    final isSelected = currentTheme == themeMode;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () => _selectTheme(themeMode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.lightColors.primary.withOpacity(0.1)
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.lightColors.primary
                        : Theme.of(context).dividerColor.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? AppColors.lightColors.primary.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: isSelected ? 15 : 8,
                      spreadRadius: isSelected ? 3 : 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Иконка темы
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.lightColors.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Контент
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.lightColors.primary
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
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

                    // Индикатор выбора
                    if (isSelected)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.lightColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectTheme(ThemeMode themeMode) async {
    logDebug('Выбрана тема: $themeMode');

    final themeNotifier = ref.read(themeProvider.notifier);

    switch (themeMode) {
      case ThemeMode.light:
        await themeNotifier.setLightTheme();
        break;
      case ThemeMode.dark:
        await themeNotifier.setDarkTheme();
        break;
      case ThemeMode.system:
        await themeNotifier.setSystemTheme();
        break;
    }

    // Отметить экран как завершенный
    ref
        .read(setupProvider.notifier)
        .markScreenCompleted(SetupScreenType.themeSelection);
  }
}
