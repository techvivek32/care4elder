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

    // Get the base URL and remove trailing slash if any
    String base = baseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }

    // Determine the root domain (without /api)
    String rootBase = base;
    if (base.endsWith('/api')) {
      rootBase = base.substring(0, base.length - 4);
    }

    // Remove leading slash from the provided url
    String cleanUrl = url;
    if (cleanUrl.startsWith('/')) {
      cleanUrl = cleanUrl.substring(1);
    }

    // If the URL already starts with 'uploads/', just prepend rootBase
    if (cleanUrl.startsWith('uploads/')) {
      return '$rootBase/$cleanUrl';
    }

    // Otherwise, prepend rootBase/uploads/
    return '$rootBase/uploads/$cleanUrl';
  }

  static String get sendOtp => '$baseUrl/auth/send-otp';
  static String get verifyOtp => '$baseUrl/auth/verify-otp';
  static String get upload => '$baseUrl/upload';
  static String get doctorRegister => '$baseUrl/auth/doctor/register';
  static String get heroSections => '$baseUrl/hero-sections';
  static String get healthTips => '$baseUrl/health-tips';
}
