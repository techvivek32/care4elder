import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/consultation/screens/consultation_screen.dart';

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  testWidgets('ConsultationScreen renders correctly', (
    WidgetTester tester,
  ) async {
    // Set screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ConsultationScreen()));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Find a Doctor'), findsOneWidget);

    // Verify Search Bar
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search doctors, specialization'), findsOneWidget);

    // Verify Categories
    expect(find.text('All'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);
    expect(find.text('Cardiology'), findsOneWidget);
    expect(find.text('Dermatology'), findsOneWidget);
    expect(find.text('Neurology'), findsOneWidget);

    // Verify Doctor List (initial state: All)
    expect(find.text('Dr. Priya Sharma'), findsOneWidget);
    expect(find.text('Dr. Kevin Chen'), findsOneWidget);

    // Scroll to see bottom items
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Emily Watson'), findsOneWidget);
    expect(find.text('Dr. Omar Hassan'), findsOneWidget);
  });

  testWidgets('ConsultationScreen filters by category', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ConsultationScreen()));
    await tester.pumpAndSettle();

    // Tap on 'Cardiology'
    await tester.tap(find.text('Cardiology'));
    await tester.pumpAndSettle();

    // Verify Cardiology doctors are shown
    expect(find.text('Dr. Kevin Chen'), findsOneWidget);

    // Verify others are hidden
    expect(find.text('Dr. Priya Sharma'), findsNothing);
  });

  testWidgets('ConsultationScreen filters by search text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ConsultationScreen()));
    await tester.pumpAndSettle();

    // Enter search text
    await tester.enterText(find.byType(TextField), 'Emily');
    await tester.pumpAndSettle();

    // Verify filtered result
    expect(find.text('Dr. Emily Watson'), findsOneWidget);

    // Verify others are hidden
    expect(find.text('Dr. Priya Sharma'), findsNothing);
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // throw UnimplementedError(); // Don't throw for other methods
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  bool autoUncompress = true;
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // throw UnimplementedError();
  }

  @override
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // throw UnimplementedError();
  }
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // throw UnimplementedError();
  }

  @override
  int get statusCode => 200;

  @override
  int get contentLength => 0;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    // Return a transparent 1x1 pixel PNG
    final List<int> transparentPixel = [
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
    ];
    return Stream<List<int>>.fromIterable([transparentPixel]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
