import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Service to handle Authentication logic.
class AuthService {
  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  
  // Use localhost for web/iOS simulator, 10.0.2.2 for Android emulator
  // For this environment, we will assume localhost is accessible
  static const String _baseUrl = 'http://localhost:3000/api'; 

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '374189587484-63hansfrfo6jpa5aoc3ea7fft7tv73rh.apps.googleusercontent.com',
    scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly'],
  );

  static const String _userKey = 'user_session';

  // OTP Storage: phone -> {code, expiresAt, attempts}
  final Map<String, Map<String, dynamic>> _otpStore = {};
  // Rate Limiting: phone -> {timestamp}
  final Map<String, List<DateTime>> _otpRateLimit = {};

  bool enableDevOtpBypass = true;

  /// Register Patient
  Future<Map<String, dynamic>> registerPatient({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? dob,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/patient/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          // 'dob': dob // Backend doesn't seem to take DOB yet, but we can send it if updated
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return data;
      } else if (response.statusCode == 409) {
        throw Exception(data['error'] ?? 'User already exists');
      } else {
        throw Exception(data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      if (kDebugMode) print('Registration Error: $e');
      rethrow;
    }
  }

  /// Verify Patient Email OTP
  Future<Map<String, dynamic>> verifyPatientEmail(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/patient/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens
        if (data['token'] != null) {
          await _storage.write(key: 'auth_token', value: data['token']);
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Verification failed');
      }
    } catch (e) {
      if (kDebugMode) print('Verification Error: $e');
      rethrow;
    }
  }

  /// Update Patient Relatives
  Future<Map<String, dynamic>> updateRelatives(List<Map<String, String>> relatives) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/patient/update-relatives'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'relatives': relatives,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to save relatives');
      }
    } catch (e) {
      if (kDebugMode) print('Update Relatives Error: $e');
      rethrow;
    }
  }

  /// Verify Relative OTP
  Future<Map<String, dynamic>> verifyRelativeOtp(String otp) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Not authenticated');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/patient/verify-relative'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Verification failed');
      }
    } catch (e) {
      if (kDebugMode) print('Relative Verification Error: $e');
      rethrow;
    }
  }

  /// Send Login OTP
  Future<Map<String, dynamic>> sendLoginOtp(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/patient/login-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      if (kDebugMode) print('Login OTP Error: $e');
      rethrow;
    }
  }

  /// Verify Login OTP
  Future<Map<String, dynamic>> verifyLoginOtp(String phone, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/patient/verify-login-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens
        if (data['token'] != null) {
          await _storage.write(key: 'auth_token', value: data['token']);
        }
        // Save user info
        if (data['user'] != null) {
            await _storage.write(key: _userKey, value: jsonEncode(data['user']));
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Verification failed');
      }
    } catch (e) {
      if (kDebugMode) print('Login Verification Error: $e');
      rethrow;
    }
  }

  /// Resend OTP (Real)
  Future<bool> resendOtp({required String email, String role = 'Patient'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'role': role,
          'intent': 'register' // or 'login' depending on context, but 'register' handles unverified users
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to resend OTP');
      }
    } catch (e) {
      if (kDebugMode) print('Resend OTP Error: $e');
      rethrow;
    }
  }

  /// Send OTP to phone number (Legacy/Mock - Deprecated for Registration)
  Future<bool> sendOtp(String phone) async {
    try {
      // 1. Rate Limiting Check (Max 3 per hour)
      final now = DateTime.now();
      if (_otpRateLimit.containsKey(phone)) {
        final attempts = _otpRateLimit[phone]!;
        // Remove attempts older than 1 hour
        attempts.removeWhere((t) => now.difference(t).inHours >= 1);
        if (attempts.length >= 3) {
          throw Exception('Too many OTP attempts. Please try again later.');
        }
        attempts.add(now);
      } else {
        _otpRateLimit[phone] = [now];
      }

      // 2. Generate OTP (6 digits)
      // Using a fixed random seed for predictability in tests could be an option,
      // but for now we use random.
      // For testing/demo purposes, we can log it.
      String otp;
      if (enableDevOtpBypass) {
        otp = '000000';
      } else {
        otp = (100000 + DateTime.now().microsecond % 900000).toString();
      }

      // 3. Store OTP (Expires in 5 mins)
      _otpStore[phone] = {
        'code': otp,
        'expiresAt': now.add(const Duration(minutes: 5)),
        'verified': false,
      };

      // 4. Log Action
      if (kDebugMode) {
        print('SECURITY LOG: OTP Generated for $phone: $otp');
      }

      // 5. Mock Send SMS with Fallback
      try {
        await _sendSmsPrimary(phone, otp);
      } catch (e) {
        if (kDebugMode) {
          print('Primary SMS Gateway failed: $e. Switching to fallback...');
        }
        await _sendSmsFallback(phone, otp);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('OTP Send Error: $e');
      }
      rethrow;
    }
  }

  Future<void> _sendSmsPrimary(String phone, String otp) async {
    // Simulate primary gateway
    await Future.delayed(const Duration(seconds: 1));
    // Randomly fail to test fallback (10% chance)
    if (DateTime.now().millisecond % 10 == 0) {
      throw Exception('Gateway timeout');
    }
    // In real app: await http.post('https://primary-sms.com/api', ...);
  }

  Future<void> _sendSmsFallback(String phone, String otp) async {
    // Simulate fallback gateway
    await Future.delayed(const Duration(seconds: 1));
    // In real app: await http.post('https://fallback-sms.com/api', ...);
  }

  /// Verify OTP
  Future<bool> verifyOtp(String phone, String code) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // SECURITY: Development Bypass Check
    if (enableDevOtpBypass) {
      // Logic: Accept any 6-digit code or specific '111111'.
      // Requirement: "accepts any 6-digit OTP code (e.g., 111111) as valid"
      // We will allow ANY 6-digit code to pass if this flag is enabled.
      if (code.length == 6) {
        if (kDebugMode) {
          print('SECURITY WARNING: OTP Bypass used for $phone with code $code');
        }
        return true;
      }
    }

    if (!_otpStore.containsKey(phone)) {
      throw Exception(
        'No OTP found for this number. Please request a new one.',
      );
    }

    final data = _otpStore[phone]!;
    final expiresAt = data['expiresAt'] as DateTime;

    if (DateTime.now().isAfter(expiresAt)) {
      _otpStore.remove(phone);
      throw Exception('OTP expired. Please request a new one.');
    }

    if (data['code'] == code) {
      _otpStore[phone]!['verified'] = true;
      // Clear OTP after successful verification to prevent reuse
      _otpStore.remove(phone);
      return true;
    } else {
      throw Exception('Invalid OTP.');
    }
  }

  /// Login with Email and Password
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/patient/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens
        if (data['token'] != null) {
          await _storage.write(key: 'auth_token', value: data['token']);
        }
        // Save user info
        if (data['user'] != null) {
            await _storage.write(key: _userKey, value: jsonEncode(data['user']));
        }
        return data;
      } else {
        throw Exception(data['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (kDebugMode) print('Email Login Error: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Create a new credential (if using Firebase)
      // For pure Google Sign-In, we use the accessToken/idToken
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (kDebugMode) {
        print('Access Token: $accessToken');
        print('ID Token: $idToken');
      }

      // 4. Send to backend for verification and account creation
      // This is where we would use the "Backend API"
      final userProfile = await _authenticateWithBackend(
        idToken: idToken,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );

      // 5. Save session locally
      await _saveSession(userProfile);

      return userProfile;
    } catch (error) {
      if (kDebugMode) {
        print('Google Sign-In Error: $error');
      }
      // Re-throw or handle specific errors
      throw Exception('Sign in failed: $error');
    }
  }

  /// Mock Backend Authentication
  /// In a real app, this would be an HTTP POST to your server
  Future<Map<String, dynamic>> _authenticateWithBackend({
    String? idToken,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate backend response
    return {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'email': email,
      'name': displayName ?? 'User',
      'photo_url': photoUrl,
      'token': 'mock_jwt_token_from_backend',
    };
  }

  /// Sign up with Email and Password
  Future<Map<String, dynamic>> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String dob,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate backend response
    final userProfile = {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'email': email,
      'name': name,
      'phone': phone,
      'dob': dob,
      'token': 'mock_jwt_token_from_backend',
    };

    // Save session locally
    await _saveSession(userProfile);

    return userProfile;
  }

  /// Save session to Secure Storage
  Future<void> _saveSession(Map<String, dynamic> userProfile) async {
    await _storage.write(key: _userKey, value: jsonEncode(userProfile));
  }

  /// Get current user session
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final String? userData = await _storage.read(key: _userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  /// Check if user is signed in
  Future<bool> isSignedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: _userKey);
  }
}
