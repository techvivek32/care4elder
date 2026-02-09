import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/main.dart';
import 'package:caresafe/features/splash/screens/splash_screen.dart';
import 'package:caresafe/features/selection/screens/user_selection_screen.dart';
import 'package:caresafe/features/patient/screens/patient_login_screen.dart';
import 'package:caresafe/router.dart';

void main() {
  setUp(() {
    router.go('/'); // Reset navigation before each test
  });

  testWidgets('App starts at Splash Screen and navigates to Selection', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump(); // Initial frame

    // Verify Splash Screen is displayed
    expect(find.byType(SplashScreen), findsOneWidget);
    // expect(find.text('Care4Elder'), findsOneWidget); // Text is now part of the logo image
    expect(find.text('Healthcare & SOS Assistance'), findsOneWidget);

    // Wait for the 3-second delay and animation
    await tester.pump(const Duration(seconds: 3));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byType(UserSelectionScreen).evaluate().isNotEmpty) {
        break;
      }
    }

    // Verify we are now on User Selection Screen
    expect(find.byType(UserSelectionScreen), findsOneWidget);
    expect(find.text('Welcome to Care4Elder'), findsOneWidget);
  });

  testWidgets('Navigation to Patient Login Screen works from Selection', (
    WidgetTester tester,
  ) async {
    // Manually navigate to selection to skip splash wait in this test
    router.go('/selection');
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap on Patient card
    await tester.tap(find.text('Patient'));
    await tester.pumpAndSettle();

    // Verify Patient Login Screen is displayed
    expect(find.byType(PatientLoginScreen), findsOneWidget);
  });
}
