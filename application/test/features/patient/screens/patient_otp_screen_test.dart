import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/patient/screens/patient_otp_screen.dart';

void main() {
  testWidgets('PatientOtpScreen renders OTP UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PatientOtpScreen(phoneNumber: '1234567890')),
    );

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(6));
    expect(find.text('Verify'), findsOneWidget);
  });
}
