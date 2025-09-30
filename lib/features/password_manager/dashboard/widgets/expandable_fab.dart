import 'package:flutter/material.dart';

@immutable
class ExpandableFAB extends StatefulWidget {
  const ExpandableFAB({
    super.key,
    this.initialOpen,
    this.distance = 112,
    this.iconData,

    required this.onCreateEntity,
    required this.entityName,

    required this.onCreateCategory,
    required this.onCreateTag,
    required this.onIconCreate,
  });

  final bool? initialOpen;
  final double distance;
  final String entityName;
  final IconData? iconData;
  final VoidCallback onCreateEntity;
  final VoidCallback onCreateCategory;
  final VoidCallback onCreateTag;
  final VoidCallback onIconCreate;

  @override
  State<ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<ExpandableFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _executeAction(VoidCallback action) {
    _toggle(); // Закрываем FAB
    action(); // Выполняем действие
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 56,
      height: 56,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          color: Theme.of(context).colorScheme.surface,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final actions = [
      ActionButton(
        onPressed: () => _executeAction(widget.onCreateTag),
        icon: const Icon(Icons.local_offer),
        label: 'Создать тег',
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
      ActionButton(
        onPressed: () => _executeAction(widget.onCreateCategory),
        icon: const Icon(Icons.folder),
        label: 'Создать категорию',
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      ActionButton(
        onPressed: () => _executeAction(widget.onIconCreate),
        icon: const Icon(Icons.folder),
        label: 'Создать иконку',
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      ActionButton(
        onPressed: () => _executeAction(widget.onCreateEntity),
        icon: widget.iconData != null
            ? Icon(widget.iconData)
            : const Icon(Icons.key),
        label: 'Создать ${widget.entityName}',
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ];

    final children = <Widget>[];

    // Располагаем кнопки в столбик вертикально вверх от FAB
    for (var i = 0; i < actions.length; i++) {
      children.add(
        _ExpandingActionButtonVertical(
          index: i,
          spacing: 60, // Расстояние между кнопками
          progress: _expandAnimation,
          child: actions[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButtonVertical extends StatelessWidget {
  const _ExpandingActionButtonVertical({
    required this.index,
    required this.spacing,
    required this.progress,
    required this.child,
  });

  final int index;
  final double spacing;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        // Вычисляем позицию каждой кнопки вертикально вверх
        final verticalOffset = progress.value * spacing * (index + 1);

        return Positioned(
          right: 4.0, // Выравниваем по правому краю относительно FAB
          bottom:
              10.0 +
              verticalOffset, // 56 - высота FAB, плюс вертикальное смещение
          child: Transform.scale(
            scale: progress.value, // Плавное появление с масштабированием
            child: child!,
          ),
        );
      },
      child: FadeTransition(opacity: progress, child: child),
    );
  }
}

@immutable
@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme(
                data: IconThemeData(color: foregroundColor, size: 20),
                child: icon,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
