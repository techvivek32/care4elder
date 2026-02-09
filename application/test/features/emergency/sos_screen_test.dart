import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/emergency/screens/sos_screen.dart';
import 'package:caresafe/features/emergency/widgets/cancellation_dialog.dart';
import 'package:caresafe/features/emergency/services/emergency_audit_service.dart';

void main() {
  testWidgets('SosScreen confirmation delay and activation flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SosScreen()));

    expect(find.text('Activate SOS'), findsOneWidget);

    await tester.tap(find.text('Activate SOS'));
    await tester.pump();

    expect(find.text('Activate SOS?'), findsOneWidget);

    final confirmFinder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(ElevatedButton),
    );
    ElevatedButton confirmButton = tester.widget(confirmFinder);
    expect(confirmButton.onPressed, isNull);

    await tester.pump(const Duration(seconds: 4));
    confirmButton = tester.widget(confirmFinder);
    expect(confirmButton.onPressed, isNotNull);

    await tester.tap(confirmFinder);
    await tester.pump();
    expect(find.text('Activating SOS...'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Help is On The Way'), findsOneWidget);
    expect(find.text('Cancel Emergency Alert'), findsOneWidget);
  });

  testWidgets('SosScreen allows cancel after activation with reason', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SosScreen()));

    // Activate SOS
    await tester.tap(find.text('Activate SOS'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(
      find.descendant(
        of: find.byType(SosConfirmationDialog),
        matching: find.byType(ElevatedButton),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Help is On The Way'), findsOneWidget);

    // Tap Cancel
    await tester.ensureVisible(find.text('Cancel Emergency Alert'));
    await tester.tap(find.text('Cancel Emergency Alert'));
    await tester.pumpAndSettle();

    // Verify CancellationDialog
    expect(find.byType(CancellationDialog), findsOneWidget);
    expect(find.text('Reason (Required)'), findsOneWidget);

    // Try to submit without reason (should be disabled/no-op)
    // Actually the button is disabled.
    // Select Reason
    await tester.tap(find.byType(DropdownButtonFormField<CancellationReason>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('False Alarm').last);
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.text('Submit Cancellation'));
    await tester.pumpAndSettle();

    // Verify Confirmation Dialog
    expect(find.text('Confirm Cancellation'), findsOneWidget);
    expect(find.text('Confirm Cancel'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Confirm Cancel'));
    await tester.pumpAndSettle();

    // Should be back to idle state
    expect(find.text('Activate SOS'), findsOneWidget);
    expect(find.text('Help is On The Way'), findsNothing);
  });
}
