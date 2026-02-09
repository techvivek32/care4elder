import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:caresafe/features/doctor_dashboard/screens/doctor_home_screen.dart';
import 'package:caresafe/core/services/notification_service.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return '';
  }

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final ByteData? data = const StandardMessageCodec().encodeMessage(
        <String, dynamic>{},
      );
      return data ?? ByteData(0);
    }
    if (key == 'AssetManifest.json') {
      return ByteData.view(Uint8List.fromList('{}'.codeUnits).buffer);
    }
    if (key.endsWith('png')) {
      final Uint8List transparentImage = Uint8List.fromList(<int>[
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);
      return ByteData.view(transparentImage.buffer);
    }
    throw FlutterError('Asset not found: $key');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/doctor/home',
      routes: [
        GoRoute(
          path: '/doctor/home',
          builder: (context, state) => const DoctorHomeScreen(),
        ),
        GoRoute(
          path: '/doctor/requests',
          builder: (context, state) =>
              const Scaffold(body: Text('Requests Screen')),
        ),
        GoRoute(
          path: '/doctor/history',
          builder: (context, state) =>
              const Scaffold(body: Text('History Screen')),
        ),
        GoRoute(
          path: '/doctor/earnings',
          builder: (context, state) =>
              const Scaffold(body: Text('Earnings Screen')),
        ),
        GoRoute(
          path: '/doctor/notifications',
          builder: (context, state) =>
              const Scaffold(body: Text('Notifications Screen')),
        ),
      ],
    );
  }

  testWidgets('DoctorHomeScreen navigates to requests from View All', (
    WidgetTester tester,
  ) async {
    NotificationService().unreadCountNotifier.value = 2;
    final router = buildRouter();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();

    expect(find.text('Requests Screen'), findsOneWidget);
  });

  testWidgets('DoctorHomeScreen navigates to history from quick action', (
    WidgetTester tester,
  ) async {
    final router = buildRouter();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('History'));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('History Screen'), findsOneWidget);
  });

  testWidgets('DoctorHomeScreen navigates to earnings from quick action', (
    WidgetTester tester,
  ) async {
    final router = buildRouter();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Earnings'));
    await tester.tap(find.text('Earnings'));
    await tester.pumpAndSettle();

    expect(find.text('Earnings Screen'), findsOneWidget);
  });

  testWidgets('DoctorHomeScreen opens notifications from bell icon', (
    WidgetTester tester,
  ) async {
    final router = buildRouter();

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.notifications_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Notifications Screen'), findsOneWidget);
  });
}
