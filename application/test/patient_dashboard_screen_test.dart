import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/patient/screens/patient_dashboard_screen.dart';

void main() {
  testWidgets('PatientDashboardScreen renders correctly', (
    WidgetTester tester,
  ) async {
    // Set screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PatientDashboardScreen()));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);

    // Verify Carousel (instead of SOS)
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Stay Safe'), findsOneWidget); // First slide
    expect(
      find.text('Always keep your emergency contacts updated.'),
      findsOneWidget,
    );

    // Verify Quick Actions
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Consult a\nDoctor'), findsOneWidget);
    expect(find.text('Medical\nRecords'), findsOneWidget);
    expect(find.text('Emergency\nContacts'), findsOneWidget);
  });

  testWidgets('Carousel auto-scrolls', (WidgetTester tester) async {
    // Set screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PatientDashboardScreen()));
    await tester.pumpAndSettle();

    // Initial state: Page 0
    expect(find.text('Stay Safe'), findsOneWidget);

    // Wait for auto-scroll (5 seconds)
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle(); // Animation

    // Should be Page 1
    expect(find.text('Healthy Living'), findsOneWidget);
  });
}
