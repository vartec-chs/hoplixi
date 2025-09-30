import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/core/index.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isDialogShown = false;
  bool _isFlashOn = false;
  bool _isPaused = false;
  bool _isPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  void _checkPermissions() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ToastHelper.error(
            title:
                'Для сканирования QR-кодов требуется разрешение на использование камеры.',
            description:
                'Пожалуйста, предоставьте разрешение в настройках приложения.',
          );
          context.pop();
        }
      } else {
        setState(() {
          _isPermissionGranted = true;
        });
      }
    } else {
      setState(() {
        _isPermissionGranted = true;
      });
    }
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea =
        (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Theme.of(context).colorScheme.primary,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    if (!p) {
      ToastHelper.error(
        title:
            'Для сканирования QR-кодов требуется разрешение на использование камеры.',
        description:
            'Пожалуйста, предоставьте разрешение в настройках приложения.',
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              flex: 5,
              child: _isPermissionGranted
                  ? _buildQrView(context)
                  : const Center(
                      child: Text(
                        'Camera permission is required to scan QR codes.',
                      ),
                    ),
            ),
            const Expanded(flex: 1, child: Center(child: Text('Scan a code'))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.flip_camera_android),
                  onPressed: _flipCamera,
                ),
                IconButton(
                  icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
                  onPressed: _toggleFlash,
                ),
                IconButton(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: _togglePause,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.getFlashStatus().then((status) {
      if (mounted) {
        setState(() {
          _isFlashOn = status ?? false;
        });
      }
    });
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null &&
          scanData.code!.isNotEmpty &&
          !_isDialogShown) {
        setState(() {
          _isDialogShown = true;
        });
        _showConfirmationDialog(scanData.code!);
      }
    });
  }

  void _flipCamera() async {
    await controller?.flipCamera();
  }

  void _toggleFlash() async {
    await controller?.toggleFlash();
    final status = await controller?.getFlashStatus();
    if (mounted) {
      setState(() {
        _isFlashOn = status ?? false;
      });
    }
  }

  void _togglePause() async {
    if (_isPaused) {
      await controller?.resumeCamera();
    } else {
      await controller?.pauseCamera();
    }
    if (mounted) {
      setState(() {
        _isPaused = !_isPaused;
      });
    }
  }

  void _showConfirmationDialog(String code) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.all(8),
          title: const Text('QR Code Scanned'),
          content: Text(
            'Сканированные данные: $code\n\nВы хотите вставить эти данные?',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              child: const Text('Нет'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                setState(() {
                  _isDialogShown = false;
                });
              },
            ),
            FilledButton(
              child: const Text('Да'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                context.pop(code);
              },
            ),
          ],
        );
      },
    );
  }
}
