import 'package:flutter/foundation.dart';

class ApiConstants {
  // Use localhost for Web
  // Use 10.0.2.2 for Android Emulator
  // NOTE: If testing on a physical device, replace '10.0.2.2' with your PC's LAN IP address (e.g., 192.168.1.x)
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // Default to Android Emulator IP for mobile
    return 'http://10.0.2.2:3000/api';
  }

  static String get sendOtp => '$baseUrl/auth/send-otp';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get upload => '$baseUrl/upload';
  static String get doctorRegister => '$baseUrl/auth/doctor/register';
}
