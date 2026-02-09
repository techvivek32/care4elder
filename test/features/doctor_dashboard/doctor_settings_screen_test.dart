import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:caresafe/features/doctor_dashboard/screens/doctor_settings_screen.dart';
import 'package:caresafe/features/doctor_dashboard/screens/doctor_consultation_fee_screen.dart';
import 'package:caresafe/features/doctor_dashboard/screens/doctor_change_password_screen.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/doctor/settings',
      routes: [
        GoRoute(
          path: '/doctor/settings',
          builder: (context, state) => const DoctorSettingsScreen(),
          routes: [
            GoRoute(
              path: 'consultation-fee',
              builder: (context, state) => const DoctorConsultationFeeScreen(),
            ),
            GoRoute(
              path: 'change-password',
              builder: (context, state) => const DoctorChangePasswordScreen(),
            ),
          ],
        ),
      ],
    );
  }

  testWidgets('Doctor settings removes dark mode, language, and privacy', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('Dark Mode'), findsNothing);
    expect(find.text('Language'), findsNothing);
    expect(find.text('Privacy Settings'), findsNothing);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Consultation Fee'), findsOneWidget);
  });

  testWidgets('Consultation fee item navigates to fee page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Consultation Fee'));
    await tester.pumpAndSettle();

    expect(find.text('PRICING DETAILS'), findsOneWidget);
  });

  testWidgets('Change password item navigates to change password page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.text('Update Password'), findsWidgets);
  });
}
