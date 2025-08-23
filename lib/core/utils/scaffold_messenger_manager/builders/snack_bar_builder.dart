import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/snack_bar_data.dart';
import '../models/snack_bar_animation_config.dart';
import '../themes/snack_bar_theme_provider.dart';
import '../scaffold_messenger_manager.dart';

abstract class SnackBarBuilder {
  SnackBar build(BuildContext context, SnackBarData data);
}

class ModernSnackBarBuilder implements SnackBarBuilder {
  final SnackBarThemeProvider themeProvider;
  final SnackBarAnimationConfig defaultAnimationConfig;

  const ModernSnackBarBuilder({
    required this.themeProvider,
    this.defaultAnimationConfig = const SnackBarAnimationConfig(),
  });

  @override
  SnackBar build(BuildContext context, SnackBarData data) {
    final originalDuration =
        data.duration ?? themeProvider.getDefaultDuration(data.type);
    final animationConfig = data.animationConfig ?? defaultAnimationConfig;

    // Используем очень большую длительность для SnackBar,
    // а реальный таймер контролируем через наш виджет
    final snackBarDuration = data.showProgressBar
        ? const Duration(days: 1) // Практически бесконечная длительность
        : originalDuration;

    return SnackBar(
      content: _ThemeAwareSnackBarContent(
        data: data,
        themeProvider: themeProvider,
        animationConfig: animationConfig,
        buildContent: _buildContent,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: snackBarDuration, // Используем контролируемую длительность
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      action: null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: BorderSide.none,
      ),
      clipBehavior: Clip.none,
    );
  }

  Widget _buildContent(
    BuildContext context,
    SnackBarData data,
    IconData icon,
    Color textColor,
    Color iconColor,
  ) {
    final actions = _buildActions(context, data, textColor);
    final originalDuration =
        data.duration ?? themeProvider.getDefaultDuration(data.type);

    // Если полоска прогресса включена, используем интегрированный hover контейнер
    if (data.showProgressBar) {
      return _IntegratedHoverSnackBar(
        duration: originalDuration, // Передаем оригинальную длительность
        textColor: textColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Простая иконка без анимации
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 16),

                  // Простой контент
                  Expanded(
                    child: Text(
                      data.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  if (actions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions
                          .map(
                            (action) => Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: action,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Без полоски прогресса - простой контейнер с анимацией
    return _SimpleAnimatedSnackBar(
      duration: originalDuration,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Простая иконка без анимации
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),

            // Простой контент
            Expanded(
              child: Text(
                data.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (actions.isNotEmpty) ...[
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions
                    .map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: action,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    SnackBarData data,
    Color textColor,
  ) {
    final actions = <Widget>[];

    // Добавляем кастомное действие если есть
    if (data.actionLabel != null && data.onActionPressed != null) {
      actions.add(
        _buildActionButton(
          onPressed: data.onActionPressed!,
          icon: Icons.touch_app_rounded,
          color: textColor,
          tooltip: data.actionLabel!,
          label: data.actionLabel!,
        ),
      );
    }

    if (data.showCopyButton) {
      actions.add(
        _buildActionButton(
          onPressed: data.onCopyPressed ?? () => _copyToClipboard(data.message),
          icon: Icons.copy_rounded,
          color: textColor,
          tooltip: 'Копировать',
        ),
      );
    }

    if (data.showCloseButton) {
      actions.add(
        _buildActionButton(
          onPressed: () {
            ScaffoldMessengerManager.instance.hideCurrentSnackBar();
          },
          icon: Icons.close_rounded,
          color: textColor,
          tooltip: 'Закрыть',
        ),
      );
    }

    return actions;
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required String tooltip,
    String? label,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 18),
                if (label != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }
}

/// Интегрированный контейнер для SnackBar с полоской прогресса и поддержкой hover
class _IntegratedHoverSnackBar extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color textColor;

  const _IntegratedHoverSnackBar({
    required this.child,
    required this.duration,
    required this.textColor,
  });

  @override
  State<_IntegratedHoverSnackBar> createState() =>
      _IntegratedHoverSnackBarState();
}

class _IntegratedHoverSnackBarState extends State<_IntegratedHoverSnackBar>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _appearanceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;
  bool _isDisappearing = false;

  @override
  void initState() {
    super.initState();

    // Контроллер для прогресс-бара
    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Контроллер для анимации появления/исчезновения
    _appearanceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Анимация масштабирования (появление)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _appearanceController, curve: Curves.elasticOut),
    );

    // Анимация прозрачности
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearanceController, curve: Curves.easeOut),
    );

    // Анимация скольжения снизу
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _appearanceController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Запускаем анимацию появления
    _appearanceController.forward();

    // Запускаем прогресс-бар с небольшой задержкой
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _progressController.forward();
      }
    });

    // Слушаем завершение прогресс-бара для автоматического закрытия
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_isDisappearing) {
        _startDisappearAnimation();
      }
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _appearanceController.dispose();
    super.dispose();
  }

  void _startDisappearAnimation() async {
    if (_isDisappearing) return;

    setState(() {
      _isDisappearing = true;
    });

    // Закрываем SnackBar сразу без анимации исчезновения
    if (mounted) {
      ScaffoldMessengerManager.instance.hideCurrentSnackBar();
    }
  }

  void _onHover(bool isHovered) {
    if (!mounted || _isDisappearing) return;

    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      // Останавливаем прогресс-бар при наведении
      _progressController.stop();
    } else {
      // Возобновляем прогресс-бар при убирании курсора
      if (!_progressController.isCompleted) {
        _progressController.forward();
      }
    }
  }

  // Публичный метод для принудительного закрытия с анимацией
  void forceClose() {
    _startDisappearAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.child,
                  // Полоска времени интегрирована сюда
                  Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 8,
                    ),
                    child: AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, child) {
                        // Получаем актуальный цвет текста из темы
                        final currentTextColor = widget.textColor;

                        return LinearProgressIndicator(
                          value:
                              1.0 -
                              _progressController
                                  .value, // Обратное значение для обратного отсчета
                          backgroundColor: currentTextColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            currentTextColor.withOpacity(
                              _isHovered ? 0.8 : 0.6,
                            ), // Ярче при наведении
                          ),
                          borderRadius: BorderRadius.circular(2),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Простая анимация для SnackBar без полоски прогресса
class _SimpleAnimatedSnackBar extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const _SimpleAnimatedSnackBar({required this.child, required this.duration});

  @override
  State<_SimpleAnimatedSnackBar> createState() =>
      _SimpleAnimatedSnackBarState();
}

class _SimpleAnimatedSnackBarState extends State<_SimpleAnimatedSnackBar>
    with TickerProviderStateMixin {
  late AnimationController _appearanceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Контроллер для анимации появления/исчезновения
    _appearanceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Анимация масштабирования (появление)
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _appearanceController, curve: Curves.elasticOut),
    );

    // Анимация прозрачности
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearanceController, curve: Curves.easeOut),
    );

    // Анимация скольжения снизу
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _appearanceController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Запускаем анимацию появления
    _appearanceController.forward();
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}

// Сохраняем старый билдер для обратной совместимости
class DefaultSnackBarBuilder extends ModernSnackBarBuilder {
  const DefaultSnackBarBuilder({
    required super.themeProvider,
    super.defaultAnimationConfig,
  });
}

/// Виджет, который слушает изменения темы и обновляет SnackBar
class _ThemeAwareSnackBarContent extends StatelessWidget {
  final SnackBarData data;
  final SnackBarThemeProvider themeProvider;
  final SnackBarAnimationConfig animationConfig;
  final Widget Function(
    BuildContext context,
    SnackBarData data,
    IconData icon,
    Color textColor,
    Color iconColor,
  )
  buildContent;

  const _ThemeAwareSnackBarContent({
    required this.data,
    required this.themeProvider,
    required this.animationConfig,
    required this.buildContent,
  });

  @override
  Widget build(BuildContext context) {
    // Автоматически перестраивается при изменении темы
    final backgroundColor = themeProvider.getBackgroundColor(
      context,
      data.type,
    );
    final textColor = themeProvider.getTextColor(context, data.type);
    final iconColor = themeProvider.getIconColor(context, data.type);
    final icon = themeProvider.getIcon(data.type);

    final content = buildContent(context, data, icon, textColor, iconColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            data.borderRadius ?? const BorderRadius.all(Radius.circular(12)),
        boxShadow: const [], // Без тени
      ),
      margin: data.margin ?? const EdgeInsets.all(16),
      child: content,
    );
  }
}
