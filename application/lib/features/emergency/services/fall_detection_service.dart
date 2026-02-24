import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FallDetectionService {
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  // Two-stage detection: impact + post-impact inactivity
  final double _impactThreshold = 18.0; // m/s^2, user acceleration (no gravity)
  final double _inactivityThreshold = 1.5; // m/s^2, low motion threshold
  final Duration _inactivityWindow = const Duration(seconds: 2);
  DateTime? _lastTriggerTime;
  final Duration _cooldown = const Duration(seconds: 10);
  bool _isMonitoring = false;

  // Verification state after impact
  bool _verifying = false;
  int _verifySamples = 0;
  int _lowMotionSamples = 0;
  Timer? _verifyTimer;

  void startMonitoring(VoidCallback onFallDetected) async {
    if (_isMonitoring) return;

    // Check if user is logged in as Patient. Doctors do not need fall detection.
    try {
      const storage = FlutterSecureStorage();
      final doctorToken = await storage.read(key: 'doctor_token');
      final patientToken = await storage.read(key: 'auth_token');
      
      if (doctorToken != null || patientToken == null) {
        if (kDebugMode) print('FallDetectionService: Not a logged-in Patient, skipping monitoring.');
        return;
      }
    } catch (e) {
      if (kDebugMode) print('FallDetectionService: Error checking session: $e');
    }
    
    _isMonitoring = true;
    // Use user accelerometer (gravity removed) to reduce false positives
    _subscription = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // If we are verifying post-impact inactivity, collect samples
      if (_verifying) {
        _verifySamples++;
        if (magnitude < _inactivityThreshold) {
          _lowMotionSamples++;
        }
        return; // wait for timer to finish
      }

      // Detect impact
      if (magnitude > _impactThreshold) {
        final now = DateTime.now();
        if (_lastTriggerTime == null || now.difference(_lastTriggerTime!) > _cooldown) {
          _verifying = true;
          _verifySamples = 0;
          _lowMotionSamples = 0;

          _verifyTimer?.cancel();
          _verifyTimer = Timer(_inactivityWindow, () {
            final int total = _verifySamples == 0 ? 1 : _verifySamples;
            final double lowRatio = _lowMotionSamples / total;
            _verifying = false;

            // Require majority of samples to be low motion after impact
            if (lowRatio >= 0.6) {
              _lastTriggerTime = DateTime.now();
              debugPrint('Fall Detected (impact + inactivity). Impact mag: $magnitude, lowRatio: $lowRatio');
              onFallDetected();
            }
          });
        }
      }
    }, onError: (e) {
      debugPrint('Error in fall detection: $e');
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _verifyTimer?.cancel();
    _verifyTimer = null;
    _verifying = false;
    _isMonitoring = false;
  }
}
