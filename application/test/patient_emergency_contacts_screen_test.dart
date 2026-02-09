import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/patient/screens/patient_emergency_contacts_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'PatientEmergencyContactsScreen renders and handles contact addition',
    (WidgetTester tester) async {
      // Set screen size to ensure scrolling works
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: PatientEmergencyContactsScreen()),
      );
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Emergency Relative'), findsOneWidget);

      // Verify Initial Contact Form (1 instance)
      // "Relative Name" text appears once per form header
      expect(find.text('Relative Name'), findsOneWidget);
      expect(find.text('Relation'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);

      // Verify Add Button exists
      final addButton = find.text('Add Another Relative');
      expect(addButton, findsOneWidget);

      // Tap Add Button
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Verify 2 Contact Forms
      expect(find.text('Relative Name'), findsNWidgets(2));
      expect(find.text('Relative 2'), findsOneWidget); // Header for 2nd contact

      // Verify Delete Button exists for 2nd contact
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Tap Delete Button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Verify back to 1 Contact Form (wait for animation)
      // Note: The animation might take time. pumpAndSettle should handle it.
      // If we used a Future.delayed for dispose, that's fine, it doesn't affect UI count immediately if removed from list.
      expect(find.text('Relative Name'), findsOneWidget);
    },
  );

  testWidgets('PatientEmergencyContactsScreen validation works', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: PatientEmergencyContactsScreen()),
    );
    await tester.pumpAndSettle();

    // Tap Save without entering data
    await tester.tap(find.text('Save & Verify'));
    await tester.pumpAndSettle();

    // Verify Error Snackbar
    expect(find.text('Please fix the errors above'), findsOneWidget);

    // Verify Field Errors
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Phone number is required'), findsOneWidget);
  });

  testWidgets('PatientEmergencyContactsScreen successfully saves data', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: PatientEmergencyContactsScreen()),
    );
    await tester.pumpAndSettle();

    // Enter Name
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter full name'),
      'John Doe',
    );

    // Select Relation
    final relationLabel = find.text('Relation');
    await tester.ensureVisible(relationLabel);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Father').last); // Select from dropdown
    await tester.pumpAndSettle();

    // Enter Phone
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter phone number'),
      '1234567890',
    );

    // Tap Save
    await tester.tap(find.text('Save & Verify'));
    await tester.pumpAndSettle();

    // Handle Terms Dialog
    expect(find.text('Terms & Conditions'), findsOneWidget);
    await tester.tap(find.text('Accept & Proceed'));
    await tester.pumpAndSettle();

    // Verify Success Snackbar
    expect(find.text('Relatives saved. Sending OTP...'), findsOneWidget);

    // Verify persistence
    final prefs = await SharedPreferences.getInstance();
    final savedString = prefs.getString('emergency_relatives');
    expect(savedString, isNotNull);
    expect(savedString, contains('John Doe'));
    expect(savedString, contains('1234567890'));
    expect(savedString, contains('Father'));
  });
}
