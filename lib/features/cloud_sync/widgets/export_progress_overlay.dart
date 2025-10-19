import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/cloud_sync/models/cloud_export_state.dart';
import 'package:hoplixi/features/cloud_sync/providers/cloud_export_provider.dart';
import 'package:hoplixi/features/cloud_sync/widgets/export_progress_dialog.dart';

/// Overlay виджет для автоматического отображения диалога экспорта
class ExportProgressOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const ExportProgressOverlay({super.key, required this.child});

  @override
  ConsumerState<ExportProgressOverlay> createState() =>
      _ExportProgressOverlayState();
}

class _ExportProgressOverlayState extends ConsumerState<ExportProgressOverlay> {
  bool _isDialogShown = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<ExportState>>(cloudExportProvider, (previous, next) {
      next.whenData((state) {
        final shouldShow =
            state is ExportStateExporting ||
            state is ExportStateFileProgress ||
            state is ExportStateChecking;

        final isSuccess = state is ExportStateSuccess;

        // Показываем диалог при начале экспорта
        if (shouldShow && !_isDialogShown) {
          _isDialogShown = true;
          _showDialog();
        }

        // Закрываем диалог только при успехе (автоматически через 2 сек)
        // При ошибке диалог остается открытым для ручного закрытия
        if (isSuccess && _isDialogShown) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _isDialogShown) {
              Navigator.of(context, rootNavigator: true).pop();
              _isDialogShown = false;
            }
          });
        }
      });
    });

    return widget.child;
  }

  void _showDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => PopScope(
        canPop: false,
        child: ExportProgressDialog(
          onClose: () {
            if (_isDialogShown) {
              Navigator.of(context, rootNavigator: true).pop();
              _isDialogShown = false;
            }
          },
        ),
      ),
    );
  }
}
