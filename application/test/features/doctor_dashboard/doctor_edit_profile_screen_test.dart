import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:caresafe/features/doctor_dashboard/screens/doctor_edit_profile_screen.dart';
import 'package:caresafe/features/doctor_dashboard/services/doctor_profile_service.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return "";
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
      // Return a valid 1x1 transparent png
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

  const MethodChannel channel = MethodChannel(
    'miguelpruivo/flutter_file_picker',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('DoctorEditProfileScreen shows validation errors', (
    WidgetTester tester,
  ) async {
    // Reset service data
    final service = DoctorProfileService();
    await tester.runAsync(() async {
      await service.updateProfile(
        service.currentProfile.copyWith(name: 'Test Doctor'),
      );
    });

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp(home: const DoctorEditProfileScreen()),
      ),
    );

    // Pump to load data (FutureBuilder/initState async)
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait for mock delay
    await tester.pump(const Duration(milliseconds: 300));

    // Verify initial data loaded
    expect(find.text('Test Doctor'), findsOneWidget);

    // Clear name
    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), '');
    await tester.pump();

    // Scroll to button
    final buttonFinder = find.text('Save Changes');
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap save
    await tester.tap(buttonFinder);
    await tester.pump();

    // Verify error
    expect(find.text('Name is required'), findsOneWidget);
  });

  testWidgets('DoctorEditProfileScreen updates profile on success', (
    WidgetTester tester,
  ) async {
    // Setup GoRouter to handle context.pop()
    final router = GoRouter(
      initialLocation: '/edit',
      routes: [
        GoRoute(
          path: '/edit',
          builder: (context, state) => const DoctorEditProfileScreen(),
        ),
        GoRoute(
          path: '/doctor/profile',
          builder: (context, state) =>
              const Scaffold(body: Text('Profile Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Pump to load data
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));

    // Change name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full Name'),
      'New Name',
    );
    await tester.pump();

    // Scroll to button
    final buttonFinder = find.text('Save Changes');
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap save
    await tester.tap(buttonFinder);
    await tester.pump();

    // Wait for save delay (2 seconds)
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify success snackbar
    expect(find.text('Profile updated successfully'), findsOneWidget);

    // Verify updated service data
    expect(DoctorProfileService().currentProfile.name, 'New Name');
  });
}
