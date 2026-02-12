import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import './settings_service.dart';
import '../../features/auth/services/auth_service.dart';

class Doctor {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String specialization;
  final String licenseNumber;
  final int experienceYears;
  final String hospitalAffiliation;
  final String qualifications;
  final String about;
  final String profileImage;
  final double consultationFee;
  final double emergencyFee;
  final bool isAvailable;
  final double rating;
  final int reviews;
  final String status;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialization,
    required this.licenseNumber,
    this.experienceYears = 0,
    this.hospitalAffiliation = '',
    this.qualifications = '',
    this.about = '',
    this.profileImage = '',
    this.consultationFee = 0.0,
    this.emergencyFee = 0.0,
    this.isAvailable = true,
    this.rating = 0.0,
    this.reviews = 0,
    this.status = 'offline',
  });

  // Calculate total fee with commission
  double get totalConsultationFee {
    final commission = SettingsService().standardCommission;
    return consultationFee * (1 + (commission / 100));
  }

  double get totalEmergencyFee {
    final commission = SettingsService().emergencyCommission;
    return emergencyFee * (1 + (commission / 100));
  }

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      specialization: json['specialization'] ?? '',
      licenseNumber: json['licenseNumber'] ?? '',
      experienceYears: json['experienceYears'] ?? 0,
      hospitalAffiliation: json['hospitalAffiliation'] ?? '',
      qualifications: json['qualifications'] ?? '',
      about: json['about'] ?? '',
      profileImage: ApiConstants.resolveImageUrl(json['profileImage'] as String?),
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      emergencyFee: (json['consultationFees'] != null && json['consultationFees']['emergency'] != null)
          ? (json['consultationFees']['emergency'] as num).toDouble()
          : (json['consultationFee'] ?? 0).toDouble() * 1.5,
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'offline',
    );
  }
}

class DoctorService extends ChangeNotifier {
  static final DoctorService _instance = DoctorService._internal();
  factory DoctorService() => _instance;
  DoctorService._internal();

  static String get _baseUrl => ApiConstants.baseUrl;

  List<Doctor> _doctors = [];
  bool _isLoading = false;
  String? _error;

  List<Doctor> get doctors => _doctors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDoctors({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      // The list endpoint is public
      final response = await http.get(Uri.parse('$_baseUrl/doctors'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _doctors = data
            .map((json) => Doctor.fromJson(json))
            .where((doc) => doc.id != '1' && doc.id.isNotEmpty) // Filter out mock/invalid IDs
            .toList();
        if (kDebugMode) {
           print('Fetched ${_doctors.length} doctors');
           for (var doc in _doctors) {
             print('Doctor: ${doc.name}, ID: ${doc.id}');
           }
        }
      } else {
        _error = 'Failed to fetch doctors: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error fetching doctors: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Doctor?> fetchDoctorById(String id) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/doctors/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Doctor.fromJson(jsonDecode(response.body));
      } else {
        if (kDebugMode) {
          print('Failed to fetch doctor details: ${response.statusCode} ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching doctor details: $e');
      }
      return null;
    }
  }
}
