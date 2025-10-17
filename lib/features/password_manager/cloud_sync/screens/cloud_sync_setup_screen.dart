import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/app/router/routes_path.dart';

class CloudSyncSetupScreen extends ConsumerStatefulWidget {
  const CloudSyncSetupScreen({super.key});

  @override
  ConsumerState<CloudSyncSetupScreen> createState() =>
      _CloudSyncSetupScreenState();
}

class _CloudSyncSetupScreenState extends ConsumerState<CloudSyncSetupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройка облачной синхронизации'),
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: const Center(
            child: Text('Экран настройки облачной синхронизации'),
          ),
        ),
      ),
    );
  }
}
