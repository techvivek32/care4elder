import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Controls fall detection via native Android Service.
///
/// Flow:
/// 1. Dart calls startFallService → native BackgroundFallService starts (Kotlin SensorManager)
/// 2. On fall: Kotlin calls back via MethodChannel 'com.care4elder.app/fall_callback'
/// 3. Dart receives 'fall_detected' method call → triggers SOS
///
/// This works in BOTH main isolate and background isolate because we set up
/// the MethodChannel handler on whichever isolate calls startMonitoring().
class FallDetectionService {
  static const MethodChannel _controlChannel =
      MethodChannel('com.care4elder.app/fall_service_control');

  // Kotlin calls THIS channel to notify Dart of a fall
  static const MethodChannel _callbackChannel =
      MethodChannel('com.care4elder.app/fall_callback');

  bool _isMonitoring = false;

  void setFallCallback(VoidCallback callback) {
    // Register handler so Kotlin can call us back
    _callbackChannel.setMethodCallHandler((call) async {
      if (call.method == 'fall_detected') {
        if (kDebugMode) print('FallDetectionService: fall_detected received from Kotlin');
        callback();
      }
    });
  }

  Future<void> startMonitoring([VoidCallback? onFallDetected]) async {
    if (_isMonitoring) return;

    if (onFallDetected != null) {
      setFallCallback(onFallDetected);
    }

    // Only run for logged-in patients
    try {
      const storage = FlutterSecureStorage();
      final doctorToken = await storage.read(key: 'doctor_token');
      final patientToken = await storage.read(key: 'auth_token');

      if (doctorToken != null || patientToken == null) {
        if (kDebugMode) print('FallDetectionService: Not a patient, skipping.');
        return;
      }
    } catch (e) {
      if (kDebugMode) print('FallDetectionService: Session check error: $e');
    }

    _isMonitoring = true;

    try {
      await _controlChannel.invokeMethod('startFallService');
      if (kDebugMode) print('FallDetectionService: Native service started');
    } catch (e) {
      // Not fatal — app may not have MainActivity ready yet (e.g. background isolate)
      if (kDebugMode) print('FallDetectionService: Could not start native service: $e');
    }
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _callbackChannel.setMethodCallHandler(null);
    try {
      _controlChannel.invokeMethod('stopFallService');
    } catch (_) {}
  }
}
