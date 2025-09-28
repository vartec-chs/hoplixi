import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';
import 'package:hoplixi/features/localsend/models/device_info.dart';

/// Экран для передачи и приема данных
///

class TransceiveScreen extends StatefulWidget {
  const TransceiveScreen({super.key, this.deviceInfo, this.connectionMode});

  final LocalSendDeviceInfo? deviceInfo;
  final ConnectionMode? connectionMode;

  @override
  State<TransceiveScreen> createState() => _TransceiveScreenState();
}

class _TransceiveScreenState extends State<TransceiveScreen> {
  LocalSendDeviceInfo? get deviceInfo => widget.deviceInfo;
  ConnectionMode? get connectionMode => widget.connectionMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transceive'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: deviceInfo != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Device: ${deviceInfo!.name}'),
                  Text('IP: ${deviceInfo!.ipAddress}:${deviceInfo!.port}'),
                  Text('Type: ${deviceInfo!.type.name}'),
                  const SizedBox(height: 20),
                  Text('Connection Mode: ${connectionMode!.name}'),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
