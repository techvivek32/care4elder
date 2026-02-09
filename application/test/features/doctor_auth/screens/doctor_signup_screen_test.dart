import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/doctor_auth/screens/doctor_signup_screen.dart';

void main() {
  testWidgets('DoctorSignupScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DoctorSignupScreen()));

    expect(find.text('Doctor Registration'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Verify Contact Details'), findsOneWidget);
  });
}
