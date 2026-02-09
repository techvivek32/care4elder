import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/patient/screens/patient_relative_otp_screen.dart';

void main() {
  testWidgets('PatientRelativeOtpScreen renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientRelativeOtpScreen(phoneNumber: '9876543210'),
      ),
    );

    // Verify Title
    expect(find.text('Verify Relative'), findsOneWidget);

    // Verify Subtitle contains formatted phone
    expect(find.textContaining('98765 43210'), findsOneWidget);

    // Verify 6 OTP boxes
    expect(find.byType(TextFormField), findsNWidgets(6));

    // Verify Verify Button
    expect(find.text('Verify'), findsOneWidget);
  });

  testWidgets('OTP Verification requires 6 digits', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientRelativeOtpScreen(phoneNumber: '9876543210'),
      ),
    );

    // Enter partial OTP
    await tester.enterText(find.byType(TextFormField).first, '1');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle();

    // Expect Error Snackbar
    expect(find.text('Please enter valid 6-digit OTP'), findsOneWidget);
  });
}
