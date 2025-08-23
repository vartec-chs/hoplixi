import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/router/routes_path.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              if (UniversalPlatform.isMobile)
                const SliverAppBar(
                  pinned: true,
                  centerTitle: true,
                  title: Text(
                    MainConstants.appName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 2,

                  children: [
                    SmoothButton(
                      onPressed: () {
                        context.go(AppRoutes.openStore);
                      },
                      isFullWidth: true,

                      label: 'Открыть хранилище',
                      icon: const Icon(Icons.file_open_sharp, size: 32),
                    ),

                    const SizedBox(height: 16),

                    SmoothButton(
                      onPressed: () {
                        context.go(AppRoutes.createStore);
                      },
                      isFullWidth: true,
                      type: SmoothButtonType.outlined,
                      label: 'Создать хранилище',
                      icon: const Icon(Icons.add_box, size: 32),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
              SliverToBoxAdapter(child: const Divider(height: 2)),
              SliverToBoxAdapter(child: const SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAppBar() {
    return SliverAppBar(pinned: true, title: const Text(MainConstants.appName));
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.onPressed,
    required this.child,
    this.icon,
    this.backgroundColor,
    this.borderColor,
    this.width = 150,

    this.height = 150,
    this.borderRadius = 12,
    this.isWidthFull = false,
    super.key,
  });

  final VoidCallback onPressed;
  final Widget child;

  final double borderRadius;
  final Widget? icon;
  final Color? backgroundColor;
  final double width;
  final double height;
  final bool isWidthFull;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWidthFull ? double.infinity : width,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero, // убирает лишние отступы
          backgroundColor: backgroundColor ?? Colors.transparent,
          textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: BorderSide(color: borderColor ?? Colors.transparent),
          ),
        ),
        child: Center(
          child: icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [icon!, const SizedBox(width: 8), child],
                )
              : child,
        ), // текст/иконка по центру
      ),
    );
  }
}
