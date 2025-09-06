import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hoplixi/common/slider_button.dart';

void main() {
  group('SliderButton Tests', () {
    testWidgets('SliderButton renders correctly', (WidgetTester tester) async {
      bool wasCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SliderButton(
              type: SliderButtonType.confirm,
              text: 'Test Button',
              onSlideComplete: () {
                wasCompleted = true;
              },
            ),
          ),
        ),
      );

      // Проверяем, что текст отображается
      expect(find.text('Test Button'), findsOneWidget);

      // Проверяем, что есть иконка
      expect(find.byType(Icon), findsOneWidget);

      // Проверяем, что callback еще не вызван
      expect(wasCompleted, false);
    });

    testWidgets('SliderButton with custom theme', (WidgetTester tester) async {
      final customTheme = SliderButtonThemeData(
        backgroundColor: Colors.red,
        fillColor: Colors.green,
        thumbColor: Colors.blue,
        iconColor: Colors.white,
        textColor: Colors.black,
        height: 60.0,
        borderRadius: 30.0,
        textStyle: const TextStyle(),
        thumbSize: 48.0,
        animationDuration: const Duration(milliseconds: 300),
        icon: Icons.star,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SliderButtonTheme(
              data: customTheme,
              child: SliderButton(
                type: SliderButtonType.confirm,
                text: 'Custom Theme Test',
                onSlideComplete: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Custom Theme Test'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('Disabled SliderButton does not respond', (
      WidgetTester tester,
    ) async {
      bool wasCompleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SliderButton(
              type: SliderButtonType.confirm,
              text: 'Disabled Button',
              enabled: false,
              onSlideComplete: () {
                wasCompleted = true;
              },
            ),
          ),
        ),
      );

      // Найдем ползунок и попробуем его перетащить
      final thumb = find.byType(GestureDetector);
      expect(thumb, findsOneWidget);

      // Попытка перетащить (не должна сработать на отключенной кнопке)
      await tester.drag(thumb, const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(wasCompleted, false);
    });

    test('SliderButtonThemeData copyWith works correctly', () {
      const originalTheme = SliderButtonThemeData(
        backgroundColor: Colors.red,
        fillColor: Colors.green,
        thumbColor: Colors.blue,
        iconColor: Colors.white,
        textColor: Colors.black,
        height: 60.0,
        borderRadius: 30.0,
        textStyle: TextStyle(),
        thumbSize: 48.0,
        animationDuration: Duration(milliseconds: 300),
        icon: Icons.star,
      );

      final newTheme = originalTheme.copyWith(
        backgroundColor: Colors.yellow,
        height: 80.0,
      );

      expect(newTheme.backgroundColor, Colors.yellow);
      expect(newTheme.height, 80.0);
      expect(newTheme.fillColor, Colors.green); // Не изменилось
      expect(newTheme.thumbColor, Colors.blue); // Не изменилось
    });
  });
}
