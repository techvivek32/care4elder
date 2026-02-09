import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/doctor_dashboard/screens/doctor_requests_screen.dart';

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

  Future<void> pumpRequestsScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: const MaterialApp(home: DoctorRequestsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Accept and reject update counts and lists', (
    WidgetTester tester,
  ) async {
    await pumpRequestsScreen(tester);

    expect(find.text('Pending (3)'), findsOneWidget);
    expect(find.text('Accepted (0)'), findsOneWidget);
    expect(find.text('Rejected (0)'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Accept').first);
    await tester.pumpAndSettle();

    expect(find.text('Pending (2)'), findsOneWidget);
    expect(find.text('Accepted (1)'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reject').first);
    await tester.pumpAndSettle();

    expect(find.text('Pending (1)'), findsOneWidget);
    expect(find.text('Rejected (1)'), findsOneWidget);

    await tester.tap(find.text('Accepted (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Sarah Johnson'), findsOneWidget);

    await tester.tap(find.text('Rejected (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Mike Chen'), findsOneWidget);
  });

  testWidgets('Tab capsule renders on compact and wide layouts', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await pumpRequestsScreen(tester);
    expect(find.byType(TabBar), findsOneWidget);

    await tester.binding.setSurfaceSize(const Size(800, 900));
    await pumpRequestsScreen(tester);
    expect(find.byType(TabBar), findsOneWidget);
  });
}
