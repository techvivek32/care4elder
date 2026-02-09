import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:caresafe/main.dart';
import 'package:caresafe/features/patient/screens/patient_shell.dart';
import 'package:caresafe/features/doctor_dashboard/screens/doctor_shell.dart';
import 'package:caresafe/features/emergency/services/fall_detection_service.dart';

class _FakeFallDetectionService extends FallDetectionService {
  @override
  void startMonitoring(VoidCallback onFallDetected) {}

  @override
  void stopMonitoring() {}
}

void main() {
  testWidgets('Patient back from profile navigates to dashboard', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/patient/profile',
      routes: [
        ShellRoute(
          builder: (context, state, child) => PatientShell(
            fallDetectionService: _FakeFallDetectionService(),
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/patient/dashboard',
              builder: (context, state) => const Scaffold(
                body: Text('Dashboard', key: Key('dashboard-body')),
              ),
            ),
            GoRoute(
              path: '/patient/profile',
              builder: (context, state) => const Scaffold(
                body: Text('Profile', key: Key('profile-body')),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-body')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-body')), findsOneWidget);
  });

  testWidgets('Patient back on dashboard shows exit dialog', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/patient/dashboard',
      routes: [
        ShellRoute(
          builder: (context, state, child) => PatientShell(
            fallDetectionService: _FakeFallDetectionService(),
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/patient/dashboard',
              builder: (context, state) => const Scaffold(
                body: Text('Dashboard', key: Key('dashboard-body')),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Exit App'), findsOneWidget);
  });

  testWidgets('Doctor back from history navigates to home', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/doctor/history',
      routes: [
        ShellRoute(
          builder: (context, state, child) => DoctorShell(child: child),
          routes: [
            GoRoute(
              path: '/doctor/home',
              builder: (context, state) => const Scaffold(
                body: Text('Doctor Home', key: Key('doctor-home-body')),
              ),
            ),
            GoRoute(
              path: '/doctor/history',
              builder: (context, state) => const Scaffold(
                body: Text('Doctor History', key: Key('doctor-history-body')),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('doctor-history-body')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('doctor-home-body')), findsOneWidget);
  });

  testWidgets('Back handler pops route stack before exit dialog', (
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/screen1',
      routes: [
        GoRoute(
          path: '/screen1',
          builder: (context, state) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/screen2'),
                  child: const Text('Go Next'),
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/screen2',
          builder: (context, state) => const Scaffold(body: Text('Screen 2')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) =>
            BackNavigationHandler(child: child ?? const SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go Next'));
    await tester.pumpAndSettle();

    expect(find.text('Screen 2'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Screen 2'), findsNothing);
    expect(find.text('Exit App'), findsNothing);
  });
}
