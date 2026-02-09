import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/patient/screens/patient_permissions_screen.dart';

void main() {
  testWidgets(
    'PatientPermissionsScreen renders correctly and handles interaction',
    (WidgetTester tester) async {
      // Set screen size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: PatientPermissionsScreen()),
      );
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Permissions Required'), findsOneWidget);
      expect(
        find.text('Allow access to enable emergency features'),
        findsOneWidget,
      );

      // Verify Permission Cards
      expect(find.text('Location Access'), findsOneWidget);
      expect(find.text('Microphone Access'), findsOneWidget);
      expect(find.text('Motion Sensors'), findsOneWidget);

      // Verify Initial State: All 3 selected (check icons present)
      // We look for Icons.check. Note: Checkbox widget also uses check icon?
      // The Checkbox widget usually draws its own checkmark, but let's be specific.
      // Our custom cards use Icon(Icons.check).
      // The Checkbox is unchecked initially, so it shouldn't show a check mark yet (or might show an empty box).
      // Let's count Icon(Icons.check).
      expect(find.byIcon(Icons.check), findsNWidgets(3));

      // Toggle "Location Access" (Unselect)
      await tester.tap(find.text('Location Access'));
      await tester.pumpAndSettle();

      // Verify 2 check icons (Microphone + Motion)
      expect(find.byIcon(Icons.check), findsNWidgets(2));

      // Toggle "Location Access" (Select)
      await tester.tap(find.text('Location Access'));
      await tester.pumpAndSettle();

      // Verify 3 check icons
      expect(find.byIcon(Icons.check), findsNWidgets(3));

      // Verify Checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      expect(tester.widget<Checkbox>(checkboxFinder).value, false);

      // Verify Continue button by Key
      final buttonFinder = find.byKey(const Key('continue_button'));
      expect(buttonFinder, findsOneWidget);

      // Check disabled state
      final dynamic button = tester.widget(buttonFinder);
      expect(button.onPressed, null);

      // Tap Checkbox
      await tester.ensureVisible(checkboxFinder);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify Checkbox is checked
      expect(tester.widget<Checkbox>(checkboxFinder).value, true);

      // Verify Button is enabled
      final dynamic buttonEnabled = tester.widget(buttonFinder);
      expect(buttonEnabled.onPressed, isNotNull);

      // Tap Checkbox again
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Verify Button is disabled again
      final dynamic buttonDisabled = tester.widget(buttonFinder);
      expect(buttonDisabled.onPressed, null);
    },
  );

  testWidgets('PatientPermissionsScreen renders correctly on small screen', (
    WidgetTester tester,
  ) async {
    // Set screen size (iPhone SE equivalent: 375x667 logical, 750x1334 physical)
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: PatientPermissionsScreen()),
    );
    await tester.pumpAndSettle();

    // Verify Title is present
    expect(find.text('Permissions Required'), findsOneWidget);

    // Verify content is scrollable and button is accessible
    final buttonFinder = find.byKey(const Key('continue_button'));

    // ensureVisible will scroll for us.
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    expect(buttonFinder, findsOneWidget);

    // Verify checkbox is also reachable
    final checkboxFinder = find.byType(Checkbox);
    await tester.ensureVisible(checkboxFinder);
    expect(checkboxFinder, findsOneWidget);
  });
}
