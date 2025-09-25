import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/constants/main_constants.dart';
import 'package:hoplixi/core/theme/index.dart';
import 'package:hoplixi/hoplixi_store/hoplixi_store_providers.dart';
import 'package:hoplixi/router/routes_path.dart';
import 'package:window_manager/window_manager.dart';

class TitleBar extends ConsumerStatefulWidget {
  const TitleBar({super.key});

  @override
  ConsumerState<TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends ConsumerState<TitleBar> {
  final BoxConstraints constraints = const BoxConstraints(
    maxHeight: 40,
    maxWidth: 40,
  );

  @override
  Widget build(BuildContext context) {
    final isDatabaseOpen = ref.watch(isDatabaseOpenProvider);
    final dbNotifier = ref.read(hoplixiStoreProvider.notifier);
    return DragToMoveArea(
      child: Container(
        height: 40,
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                MainConstants.appName,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.normal,
                  letterSpacing: 0.0,
                  decoration: TextDecoration.none,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textDirection: TextDirection.ltr,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,

                spacing: 4,

                children: [
                  Visibility(
                    visible: isDatabaseOpen,
                    child: IconButton(
                      padding: const EdgeInsets.all(6),
                      tooltip: 'Закрыть бызу данных',

                      constraints: constraints,
                      icon: Icon(Icons.lock, size: 20),
                      onPressed: () async => {
                        isDatabaseOpen
                            ? await dbNotifier.closeDatabase().then((_) {
                                context.go(AppRoutes.home);
                              })
                            : null,
                      },
                    ),
                  ),
                  ThemeSwitcher(size: 26),

                  IconButton(
                    padding: const EdgeInsets.all(6),
                    icon: Icon(Icons.remove, size: 20),
                    tooltip: 'Свернуть',
                    constraints: constraints,
                    onPressed: () => windowManager.minimize(),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Развернуть',
                    constraints: constraints,
                    icon: Icon(Icons.minimize, size: 20),
                    onPressed: () => windowManager.maximize(),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Закрыть',
                    hoverColor: Colors.red,
                    constraints: constraints,
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () async => {
                      isDatabaseOpen ? await dbNotifier.closeDatabase() : null,
                      await windowManager.close(),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
