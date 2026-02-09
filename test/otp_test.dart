import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/patient/screens/patient_otp_screen.dart';

void main() {
  testWidgets('Patient OTP Screen renders correctly', (
    WidgetTester tester,
  ) async {
    // Set screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(home: PatientOtpScreen(phoneNumber: '9876543210')),
    );

    // Verify Title and Subtitle
    expect(find.text('Enter OTP'), findsOneWidget);
    // Formatting adds spaces: +91 98765 43210
    expect(find.textContaining('98765 43210'), findsOneWidget);

    // Verify 6 OTP boxes
    expect(find.byType(TextFormField), findsNWidgets(6));

    // Verify Timer
    expect(find.textContaining('60s', findRichText: true), findsOneWidget);

    // Verify Button
    expect(find.text('Verify'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('OTP Timer counts down', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PatientOtpScreen(phoneNumber: '1234567890')),
    );

    expect(find.textContaining('60s', findRichText: true), findsOneWidget);

    // Fast forward 1 second
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('59s', findRichText: true), findsOneWidget);
  });
}
