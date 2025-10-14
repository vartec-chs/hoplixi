import 'package:flutter/material.dart';
import 'package:hoplixi/global_key.dart';
import 'package:riverpod/riverpod.dart';

final askExportStoreProvider = AsyncNotifierProvider<AskExportStore, bool>(
  AskExportStore.new,
);

class AskExportStore extends AsyncNotifier<bool> {
  @override
  bool build() => false;

  Future<bool> askExport() async {
    final result = await showDialog<bool>(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Экспорт данных'),
        content: const Text('Вы хотите экспортировать данные?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
