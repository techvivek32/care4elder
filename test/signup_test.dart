import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/patient/screens/patient_signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Patient Signup Screen renders all fields', (
    WidgetTester tester,
  ) async {
    // Set screen size to avoid overflow
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(home: PatientSignupScreen()));

    // Verify all fields are present
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsWidgets); // Title and Button

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('Patient Signup Screen validation works', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(const MaterialApp(home: PatientSignupScreen()));

    // Tap create account without entering anything
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pump();

    // Check for validation errors
    expect(find.text('Please enter your name'), findsOneWidget);
    expect(find.text('Please enter email'), findsOneWidget);
    expect(find.text('Please enter phone number'), findsOneWidget);
    expect(find.text('Please select date of birth'), findsOneWidget);
    expect(find.text('Please enter password'), findsOneWidget);

    // Test invalid email
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enter your email'),
      'invalid-email',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);

    // Test weak password
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Create a password'),
      'weak',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pump();
    expect(find.text('Minimum 8 characters required'), findsOneWidget);

    // Test password mismatch
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Create a password'),
      'StrongP@ss1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm your password'),
      'Mismatch',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Account'));
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
