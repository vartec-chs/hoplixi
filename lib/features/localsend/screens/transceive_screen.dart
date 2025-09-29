import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoplixi/features/localsend/models/connection_mode.dart';

class TransceiveScreen extends ConsumerStatefulWidget {
  const TransceiveScreen({super.key, this.mode, this.remoteUrl});

  final ConnectionMode? mode;
  final String? remoteUrl;

  @override
  ConsumerState<TransceiveScreen> createState() => _TransceiveScreenState();
}

class _TransceiveScreenState extends ConsumerState<TransceiveScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transceive')),
      body: Center(child: Text('Transceive Screen')),
    );
  }
}
