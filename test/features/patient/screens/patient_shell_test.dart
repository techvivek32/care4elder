import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:caresafe/features/patient/screens/patient_shell.dart';
import 'package:caresafe/features/emergency/services/fall_detection_service.dart';

class MockFallDetectionService extends FallDetectionService {
  VoidCallback? callback;
  bool isMonitoring = false;

  @override
  void startMonitoring(VoidCallback onFallDetected) {
    callback = onFallDetected;
    isMonitoring = true;
  }

  @override
  void stopMonitoring() {
    isMonitoring = false;
    callback = null;
  }

  void simulateFall() {
    callback?.call();
  }
}

void main() {
  testWidgets('PatientShell integrates FallDetectionService', (
    WidgetTester tester,
  ) async {
    final mockService = MockFallDetectionService();
    
    // Create a GoRouter to test navigation
    final router = GoRouter(
      initialLocation: '/patient/dashboard',
      routes: [
        ShellRoute(
          builder: (context, state, child) {
            return PatientShell(
              fallDetectionService: mockService,
              child: child,
            );
          },
          routes: [
            GoRoute(
              path: '/patient/dashboard',
              builder: (context, state) => const Scaffold(body: Text('Dashboard')),
            ),
            GoRoute(
              path: '/patient/sos',
              builder: (context, state) {
                final autoStart = state.uri.queryParameters['autoStart'] == 'true';
                return Scaffold(body: Text('SOS: autoStart=$autoStart'));
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    // Verify service started
    expect(mockService.isMonitoring, isTrue);
    expect(find.text('Dashboard'), findsOneWidget);

    // Simulate fall
    mockService.simulateFall();
    await tester.pumpAndSettle();

    // Verify navigation to SOS with autoStart
    expect(find.text('SOS: autoStart=true'), findsOneWidget);
  });
}
