import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend_prototype/widgets/active_transfers_view.dart';

/// Вкладка с активными передачами файлов
class TransfersTab extends ConsumerWidget {
  const TransfersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: ActiveTransfersView(),
    );
  }
}
