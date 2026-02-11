import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    // Try to get from .env file first
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Fallback to --dart-define
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }
    
    // Default fallback
    return 'https://care4elder.cloud/api';
  }

  static String resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    final base = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;

    // Remove leading slash if present in the URL
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;

    // Ensure 'uploads/' is part of the path if it's a relative path from the server
    if (!cleanUrl.startsWith('uploads/')) {
      return '$base/uploads/$cleanUrl';
    }

    return '$base/$cleanUrl';
  }

  static String get sendOtp => '$baseUrl/auth/send-otp';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get upload => '$baseUrl/upload';
  static String get doctorRegister => '$baseUrl/auth/doctor/register';
}
