import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/theme_old/colors/colors_dark.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:hoplixi/common/button.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/constants/responsive_constants.dart';
import 'package:hoplixi/core/theme/component_themes.dart';
import 'package:hoplixi/core/theme/constants.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:hoplixi/core/theme/theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

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
                    ActionButton(
                      onPressed: () {},
                      isWidthFull: true,
                      height: 60,
                      child: const Text('Открыть хранилище'),
                      icon: const Icon(Icons.file_open_sharp, size: 32),
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    ActionButton(
                      onPressed: () {},
                      isWidthFull: true,
                      height: 60,
                      child: const Text('Создать хранилище'),
                      icon: const Icon(Icons.add_box, size: 32),
                      backgroundColor: Colors.pinkAccent,
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
    this.width = 150,

    this.height = 150,
    this.borderRadius = 12,
    this.isWidthFull = false,
    Key? key,
  }) : super(key: key);

  final VoidCallback onPressed;
  final Widget child;

  final double borderRadius;
  final Widget? icon;
  final Color? backgroundColor;
  final double width;
  final double height;
  final bool isWidthFull;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isWidthFull ? double.infinity : width,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero, // убирает лишние отступы
          backgroundColor: backgroundColor,
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
