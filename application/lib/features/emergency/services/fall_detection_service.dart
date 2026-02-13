import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FallDetectionService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  // Threshold for fall detection (approx 2.5g = 2.5 * 9.8 = 24.5 m/s^2)
  final double _fallThreshold = 24.5;
  DateTime? _lastTriggerTime;
  final Duration _cooldown = const Duration(seconds: 10);
  bool _isMonitoring = false;

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
    // accelerometerEventStream includes gravity, which is suitable for detecting impact force
    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      
      if (magnitude > _fallThreshold) {
        final now = DateTime.now();
        if (_lastTriggerTime == null || now.difference(_lastTriggerTime!) > _cooldown) {
          _lastTriggerTime = now;
          debugPrint('Fall Detected! Magnitude: $magnitude');
          onFallDetected();
        }
      }
    }, onError: (e) {
      debugPrint('Error in fall detection: $e');
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
    _isMonitoring = false;
  }
}
