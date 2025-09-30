import 'package:flutter/material.dart';

/// Эффект shimmer для загрузки
class ShimmerEffect extends StatefulWidget {
  /// Ребенок виджет
  final Widget child;

  /// Базовый цвет
  final Color baseColor;

  /// Цвет подсветки
  final Color highlightColor;

  /// Включен ли эффект
  final bool enabled;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.enabled = true,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.enabled) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value * 3.14159),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Виджет для загрузочного состояния списка тегов
class TagListShimmer extends StatelessWidget {
  /// Количество элементов для отображения
  final int itemCount;

  const TagListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ShimmerEffect(
            baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            highlightColor: theme.colorScheme.surface,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Цветовой индикатор
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Текст тега
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Чекбокс
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Виджет для загрузочного состояния списка категорий
class CategoryListShimmer extends StatelessWidget {
  /// Количество элементов для отображения
  final int itemCount;

  const CategoryListShimmer({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ShimmerEffect(
            baseColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            highlightColor: theme.colorScheme.surface,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Цветовой индикатор
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Название и описание
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Тип категории
                  Container(
                    width: 50,
                    height: 20,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Чекбокс
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
