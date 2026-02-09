import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/core/widgets/patient_navigation.dart';

void main() {
  testWidgets('PatientBottomNavBar renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PatientBottomNavBar(
            currentIndex: 0,
            onTap: (index) {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Consult'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Records'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify icons
    expect(find.byIcon(Icons.home_rounded), findsOneWidget); // Active Home
    expect(
      find.byIcon(Icons.monitor_heart_outlined),
      findsOneWidget,
    ); // Inactive Consult
  });

  testWidgets('PatientBottomNavBar highlights active item', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PatientBottomNavBar(
            currentIndex: 1, // Consult selected
            onTap: (index) {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.home_outlined), findsOneWidget); // Inactive Home
    expect(find.byIcon(Icons.monitor_heart), findsOneWidget); // Active Consult
  });

  testWidgets('PatientBottomNavBar calls onTap', (WidgetTester tester) async {
    int? tappedIndex;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PatientBottomNavBar(
            currentIndex: 0,
            onTap: (index) {
              tappedIndex = index;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Consult'));
    expect(tappedIndex, 1);
  });

  testWidgets('PatientBottomNavBar SOS item triggers navigation only', (
    WidgetTester tester,
  ) async {
    int? tappedIndex;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: PatientBottomNavBar(
            currentIndex: 0,
            onTap: (index) {
              tappedIndex = index;
            },
          ),
        ),
      ),
    );

    // Tap SOS tab and verify index = 2 (navigation only, no activation)
    await tester.tap(find.text('SOS'));
    expect(tappedIndex, 2);
  });
}
