import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoplixi/features/password_manager/dashboard/dashboard.dart';

void main() {
  group('EntityTypeDropdown', () {
    testWidgets('should display current entity type', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: EntityTypeDropdown())),
        ),
      );

      // Проверяем, что виджет отображается
      expect(find.byType(EntityTypeDropdown), findsOneWidget);
      expect(find.text('Пароли'), findsOneWidget); // По умолчанию password
    });

    testWidgets('should change entity type when selected', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EntityTypeDropdown(
                onEntityTypeChanged: (type) {
                  expect(type, EntityType.note);
                },
              ),
            ),
          ),
        ),
      );

      // Открываем dropdown
      await tester.tap(find.byType(DropdownButtonFormField<EntityType>));
      await tester.pumpAndSettle();

      // Выбираем "Заметки"
      await tester.tap(find.text('Заметки'));
      await tester.pumpAndSettle();
    });
  });

  group('EntityTypeCompactDropdown', () {
    testWidgets('should display compact selector', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: EntityTypeCompactDropdown())),
        ),
      );

      expect(find.byType(EntityTypeCompactDropdown), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget); // Иконка для password
    });
  });

  group('EntityTypeChips', () {
    testWidgets('should display chips for all entity types', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: EntityTypeChips())),
        ),
      );

      expect(find.byType(EntityTypeChips), findsOneWidget);
      expect(find.text('Пароли'), findsOneWidget);
      expect(find.text('Заметки'), findsOneWidget);
      expect(find.text('OTP/2FA'), findsOneWidget);
    });

    testWidgets('should select chip when tapped', (tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: EntityTypeChips(
                onEntityTypeChanged: (type) {
                  callbackCalled = true;
                  expect(type, EntityType.note);
                },
              ),
            ),
          ),
        ),
      );

      // Нажимаем на чип "Заметки"
      await tester.tap(find.text('Заметки'));
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue);
    });
  });
}
