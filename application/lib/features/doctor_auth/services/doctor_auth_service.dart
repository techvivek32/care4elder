import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/api_constants.dart';

class DoctorRegistrationData {
  String? phoneNumber;
  String? email;
  String? password;
  String? fullName;
  String? medicalRegistrationNumber;
  String? specialization;
  String? experienceYears;
  String? hospitalAffiliation;
  String? idNumber;
  String? consultationFee;
  List<String> documentPaths;
  List<PlatformFile> documents; // Added for Web/Mobile file handling

  DoctorRegistrationData({
    this.phoneNumber,
    this.email,
    this.password,
    this.fullName,
    this.medicalRegistrationNumber,
    this.specialization,
    this.experienceYears,
    this.hospitalAffiliation,
    this.idNumber,
    this.consultationFee,
    List<String>? documentPaths,
    List<PlatformFile>? documents,
  }) : documentPaths = documentPaths ?? [],
       documents = documents ?? [];

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'email': email,
      'password': password,
      'fullName': fullName,
      'medicalRegistrationNumber': medicalRegistrationNumber,
      'specialization': specialization,
      'experienceYears': experienceYears,
      'hospitalAffiliation': hospitalAffiliation,
      'idNumber': idNumber,
      'consultationFee': consultationFee,
      'documentPaths': documentPaths,
    };
  }
}

class DoctorAuthService extends ChangeNotifier {
  static final DoctorAuthService _instance = DoctorAuthService._internal();
  factory DoctorAuthService() => _instance;
  DoctorAuthService._internal();

  final _storage = const FlutterSecureStorage();
  static const _doctorTokenKey = 'doctor_token';
  static const _doctorRefreshTokenKey = 'doctor_refresh_token';
  static const _doctorIdKey = 'doctor_id';
  final DoctorRegistrationData _registrationData = DoctorRegistrationData();
  DoctorRegistrationData get registrationData => _registrationData;
  String? _mockPhoneOtp;

  // Send OTP
  Future<bool> sendOtp(
    String identifier, {
    bool isEmail = true,
    String intent = 'register',
  }) async {
    try {
      if (isEmail) {
        _registrationData.email = identifier;
      } else {
        _registrationData.phoneNumber = identifier;
      }

      if (isEmail) {
        debugPrint(
          'Sending OTP to $identifier via ${ApiConstants.sendOtp} (intent: $intent)',
        );
        final response = await http.post(
          Uri.parse(ApiConstants.sendOtp),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': identifier,
            'role': 'Doctor',
            'intent': intent,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('OTP Sent successfully');
          return true;
        } else {
          debugPrint('Failed to send OTP: ${response.body}');
          return false;
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
        _mockPhoneOtp = '123456';
        return true;
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOtp(
    String otp, {
    bool isEmail = true,
  }) async {
    try {
      if (isEmail) {
        final email = _registrationData.email;
        if (email == null) {
          return {'success': false, 'error': 'Email not found'};
        }

        debugPrint(
          'Verifying OTP $otp for $email via ${ApiConstants.verifyOtp}',
        );
        final response = await http.post(
          Uri.parse(ApiConstants.verifyOtp),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'otp': otp, 'role': 'Doctor'}),
        );

        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          debugPrint('OTP Verified successfully');

          if (data['token'] != null || data['user'] != null) {
            await _storeSession(
              token: data['token'],
              refreshToken: data['refreshToken'],
              doctorId:
                  data['user']?['_id']?.toString() ??
                  data['user']?['id']?.toString(),
            );
          }

          return {
            'success': true,
            'token': data['token'],
            'verificationStatus':
                data['user']?['verificationStatus'] ??
                'pending', // Default to pending if not provided
          };
        } else {
          debugPrint('Failed to verify OTP: ${response.body}');
          return {
            'success': false,
            'error': data['error'] ?? 'Verification failed',
          };
        }
      } else {
        if (otp.length != 6) {
          return {'success': false, 'error': 'Invalid OTP'};
        }
        if (_mockPhoneOtp == null) {
          return {'success': false, 'error': 'OTP not found'};
        }
        if (otp != _mockPhoneOtp) {
          return {'success': false, 'error': 'Invalid OTP'};
        }
        return {'success': true, 'verificationStatus': 'pending'};
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Login with Password
  Future<Map<String, dynamic>> loginWithPassword(
    String identifier,
    String password,
  ) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/doctor/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['user'];
        await _storeSession(
          token: data['token'],
          refreshToken: data['refreshToken'],
          doctorId: user?['_id']?.toString() ?? user?['id']?.toString(),
        );
        return {
          'success': true,
          'verificationStatus': user['verificationStatus'],
          'token': data['token'],
        };
      } else if (response.statusCode == 403 &&
          (data['error']?.toString().toLowerCase().contains('rejected') ??
              false)) {
        return {
          'success': false,
          'error': data['error'] ?? 'Account rejected',
          'verificationStatus': 'rejected',
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      return {'success': false, 'error': 'Network error occurred'};
    }
  }

  // Send Login OTP (Phone)
  Future<bool> sendLoginOtp(String phone) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/doctor/login-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Failed to send Login OTP: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending Login OTP: $e');
      return false;
    }
  }

  // Verify Login OTP (Phone)
  Future<Map<String, dynamic>> verifyLoginOtp(String phone, String otp) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/auth/doctor/verify-login-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['user'];
        await _storeSession(
          token: data['token'],
          refreshToken: data['refreshToken'],
          doctorId: user?['_id']?.toString() ?? user?['id']?.toString(),
        );
        return {
          'success': true,
          'verificationStatus': user['verificationStatus'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Verification failed'};
      }
    } catch (e) {
      debugPrint('Error verifying Login OTP: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Submit Registration
  Future<bool> submitRegistration() async {
    try {
      debugPrint('Submitting registration data: ${_registrationData.toJson()}');

      // 1. Upload Documents first
      final uploadedUrls = <String>[];
      if (_registrationData.documents.isNotEmpty) {
        // Use documents (PlatformFile) if available (works for Web & Mobile)
        final uploadRequest = http.MultipartRequest(
          'POST',
          Uri.parse(ApiConstants.upload),
        );

        for (var file in _registrationData.documents) {
          if (kIsWeb) {
            if (file.bytes != null) {
              uploadRequest.files.add(
                http.MultipartFile.fromBytes(
                  'file',
                  file.bytes!,
                  filename: file.name,
                ),
              );
            }
          } else {
            if (file.path != null) {
              uploadRequest.files.add(
                await http.MultipartFile.fromPath(
                  'file',
                  file.path!,
                  filename: file.name,
                ),
              );
            }
          }
        }

        final uploadResponse = await uploadRequest.send();
        final uploadBody = await _readStreamedBody(uploadResponse);
        if (uploadResponse.statusCode == 200) {
          if (uploadBody.isEmpty) {
            debugPrint('Upload response was empty');
            return false;
          }
          try {
            final respJson = jsonDecode(uploadBody);
            if (respJson is Map && respJson['urls'] != null) {
              uploadedUrls.addAll(List<String>.from(respJson['urls']));
            } else {
              debugPrint('Upload response missing urls: $uploadBody');
              return false;
            }
          } catch (e) {
            debugPrint('Invalid upload response: $e');
            return false;
          }
        } else {
          debugPrint(
            'Failed to upload documents: ${uploadResponse.statusCode} $uploadBody',
          );
          return false;
        }
      } else if (_registrationData.documentPaths.isNotEmpty) {
        // Fallback to paths if documents list is empty (Legacy/Mobile specific)
        // But we should try to use documents list primarily.
        // Keeping this for backward compatibility if needed, but the new flow uses documents.
      }

      // 2. Register User with document URLs
      final url = Uri.parse(ApiConstants.doctorRegister);
      // Validate required fields
      if ((_registrationData.fullName?.isEmpty ?? true) ||
          (_registrationData.email?.isEmpty ?? true) ||
          (_registrationData.password?.isEmpty ?? true) ||
          (_registrationData.phoneNumber?.isEmpty ?? true) ||
          (_registrationData.specialization?.isEmpty ?? true) ||
          (_registrationData.medicalRegistrationNumber?.isEmpty ?? true)) {
        debugPrint('Missing required registration fields');
        return false;
      }

      final body = {
        'name': _registrationData.fullName,
        'email': _registrationData.email,
        'password': _registrationData.password,
        'phone': _registrationData.phoneNumber,
        'specialization': _registrationData.specialization,
        'licenseNumber': _registrationData.medicalRegistrationNumber,
        'experienceYears': int.tryParse(
          _registrationData.experienceYears ?? '',
        ),
        'hospitalAffiliation': _registrationData.hospitalAffiliation,
        'idNumber': _registrationData.idNumber,
        'consultationFee':
            int.tryParse(_registrationData.consultationFee ?? '') ?? 0,
        'documents': uploadedUrls, // Send URLs
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('Registration Response: ${response.body}');

      if (response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error submitting registration: $e');
      return false;
    }
  }

  Future<String> _readStreamedBody(http.StreamedResponse response) async {
    try {
      final bytes = await response.stream.toBytes();
      if (bytes.isEmpty) {
        return '';
      }
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      debugPrint('Error reading upload response: $e');
      return '';
    }
  }

  Future<void> _storeSession({
    String? token,
    String? refreshToken,
    String? doctorId,
  }) async {
    if (token != null) {
      await _storage.write(key: _doctorTokenKey, value: token);
    }
    if (refreshToken != null) {
      await _storage.write(key: _doctorRefreshTokenKey, value: refreshToken);
    }
    if (doctorId != null) {
      await _storage.write(key: _doctorIdKey, value: doctorId);
    }
  }

  Future<String?> getDoctorToken() async {
    return _storage.read(key: _doctorTokenKey);
  }

  Future<String?> getDoctorId() async {
    return _storage.read(key: _doctorIdKey);
  }

  Future<void> clearDoctorSession() async {
    await _storage.delete(key: _doctorTokenKey);
    await _storage.delete(key: _doctorRefreshTokenKey);
    await _storage.delete(key: _doctorIdKey);
  }

  // Update Registration Data
  void updateRegistrationData({
    String? phoneNumber,
    String? email,
    String? password,
    String? fullName,
    String? medicalRegistrationNumber,
    String? specialization,
    String? experienceYears,
    String? hospitalAffiliation,
    String? idNumber,
    String? consultationFee,
    List<String>? documentPaths,
    List<PlatformFile>? documents,
  }) {
    if (phoneNumber != null) {
      _registrationData.phoneNumber = phoneNumber;
    }
    if (email != null) {
      _registrationData.email = email;
    }
    if (password != null) {
      _registrationData.password = password;
    }
    if (fullName != null) {
      _registrationData.fullName = fullName;
    }
    if (medicalRegistrationNumber != null) {
      _registrationData.medicalRegistrationNumber = medicalRegistrationNumber;
    }
    if (specialization != null) {
      _registrationData.specialization = specialization;
    }
    if (experienceYears != null) {
      _registrationData.experienceYears = experienceYears;
    }
    if (hospitalAffiliation != null) {
      _registrationData.hospitalAffiliation = hospitalAffiliation;
    }
    if (idNumber != null) {
      _registrationData.idNumber = idNumber;
    }
    if (consultationFee != null) {
      _registrationData.consultationFee = consultationFee;
    }
    if (documentPaths != null) {
      _registrationData.documentPaths = documentPaths;
    }
    if (documents != null) {
      _registrationData.documents = documents;
    }

    notifyListeners();
  }
}
