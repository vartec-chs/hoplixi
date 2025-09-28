import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/localsend_beta/models/connection_mode.dart';
import 'package:hoplixi/features/localsend_beta/models/device_info.dart';
import 'package:hoplixi/features/localsend_beta/widgets/connection_mode_dialog.dart';

void main() {
  group('ConnectionMode', () {
    test('should have correct display names', () {
      expect(ConnectionMode.initiator.displayName, 'Создать подключение');
      expect(ConnectionMode.receiver.displayName, 'Ждать подключения');
    });

    test('should have correct descriptions', () {
      expect(
        ConnectionMode.initiator.description,
        'Ваше устройство инициирует подключение к выбранному устройству',
      );
      expect(
        ConnectionMode.receiver.description,
        'Ваше устройство будет ждать входящее подключение от выбранного устройства',
      );
    });

    test('should have correct icons', () {
      expect(ConnectionMode.initiator.icon, '🚀');
      expect(ConnectionMode.receiver.icon, '📡');
    });
  });

  group('ConnectionModeDialog', () {
    late DeviceInfo testDevice;

    setUp(() {
      testDevice = const DeviceInfo(
        id: 'test-id',
        name: 'Test Device',
        type: DeviceType.mobile,
        ipAddress: '192.168.1.100',
        port: 8080,
        status: DeviceConnectionStatus.discovered,
      );
    });

    testWidgets('should display device info correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ConnectionModeDialog(targetDevice: testDevice)),
        ),
      );

      expect(find.text('Подключение к Test Device'), findsOneWidget);
      expect(find.text('📱'), findsOneWidget); // Device icon
      expect(find.text('Создать подключение'), findsOneWidget);
      expect(find.text('Ждать подключения'), findsOneWidget);
    });

    testWidgets('should return selected mode when option is tapped', (
      WidgetTester tester,
    ) async {
      ConnectionMode? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConnectionModeDialog.show(context, testDevice);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Нажимаем кнопку для показа диалога
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Нажимаем на опцию инициатора
      await tester.tap(find.text('Создать подключение'));
      await tester.pumpAndSettle();

      expect(result, ConnectionMode.initiator);
    });

    testWidgets('should return null when cancelled', (
      WidgetTester tester,
    ) async {
      ConnectionMode? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConnectionModeDialog.show(context, testDevice);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Нажимаем кнопку для показа диалога
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Нажимаем отмена
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
