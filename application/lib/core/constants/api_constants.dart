import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }
    return 'https://care4elder.cloud/api';
  }

  static String get sendOtp => '$baseUrl/auth/send-otp';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get upload => '$baseUrl/upload';
  static String get doctorRegister => '$baseUrl/auth/doctor/register';
}
