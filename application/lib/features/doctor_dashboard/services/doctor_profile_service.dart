import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../doctor_auth/services/doctor_auth_service.dart';

String? _resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  }
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  final baseUrl = ApiConstants.baseUrl;
  final baseHost = baseUrl.endsWith('/api')
      ? baseUrl.substring(0, baseUrl.length - 4)
      : baseUrl;
  if (url.startsWith('/')) {
    return '$baseHost$url';
  }
  return '$baseHost/$url';
}

class DoctorProfileData {
  String id;
  String name;
  String specialty;
  String email;
  String phone;
  String qualifications;
  String experience;
  String about;
  String hospitalAffiliation;
  String? profileImage;
  Map<String, dynamic>? consultationFees;
  Map<String, dynamic>? bankDetails;

  DoctorProfileData({
    required this.id,
    required this.name,
    required this.specialty,
    required this.email,
    required this.phone,
    required this.qualifications,
    required this.experience,
    required this.about,
    this.hospitalAffiliation = '',
    this.profileImage,
    this.consultationFees,
    this.bankDetails,
  });

  factory DoctorProfileData.fromJson(Map<String, dynamic> json) {
    final rawImage = json['profileImage'] as String?;
    return DoctorProfileData(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialization'] ?? json['specialty'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      qualifications: json['qualifications'] ?? '',
      experience:
          json['experience']?.toString() ??
          json['experienceYears']?.toString() ??
          '',
      about: json['about'] ?? '',
      hospitalAffiliation: json['hospitalAffiliation'] ?? '',
      profileImage: _resolveImageUrl(rawImage),
      consultationFees: json['consultationFees'],
      bankDetails: json['bankDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'specialty': specialty,
      'email': email,
      'phone': phone,
      'qualifications': qualifications,
      'experience': experience,
      'about': about,
      'hospitalAffiliation': hospitalAffiliation,
      'profileImage': profileImage,
      'consultationFees': consultationFees,
      'bankDetails': bankDetails,
    };
  }

  DoctorProfileData copyWith({
    String? id,
    String? name,
    String? specialty,
    String? email,
    String? phone,
    String? qualifications,
    String? experience,
    String? about,
    String? hospitalAffiliation,
    String? profileImage,
    Map<String, dynamic>? consultationFees,
    Map<String, dynamic>? bankDetails,
  }) {
    return DoctorProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      specialty: specialty ?? this.specialty,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      qualifications: qualifications ?? this.qualifications,
      experience: experience ?? this.experience,
      about: about ?? this.about,
      hospitalAffiliation: hospitalAffiliation ?? this.hospitalAffiliation,
      profileImage: profileImage ?? this.profileImage,
      consultationFees: consultationFees ?? this.consultationFees,
      bankDetails: bankDetails ?? this.bankDetails,
    );
  }
}

class DoctorProfileService extends ChangeNotifier {
  static final DoctorProfileService _instance =
      DoctorProfileService._internal();
  factory DoctorProfileService() => _instance;
  DoctorProfileService._internal();

  DoctorProfileData _currentProfile = DoctorProfileData(
    id: '',
    name: '',
    specialty: '',
    email: '',
    phone: '',
    qualifications: '',
    experience: '',
    about: '',
    profileImage: null,
  );
  bool _isLoaded = false;

  DoctorProfileData get currentProfile => _currentProfile;

  Future<DoctorProfileData> getProfile() async {
    if (_isLoaded && _currentProfile.id.isNotEmpty) {
      return _currentProfile;
    }
    return _fetchProfile();
  }

  Future<DoctorProfileData> _fetchProfile() async {
    final token = await DoctorAuthService().getDoctorToken();
    final doctorId = await DoctorAuthService().getDoctorId();
    if (token == null || doctorId == null) {
      throw Exception('Session not found');
    }

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/doctors/$doctorId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _currentProfile = DoctorProfileData.fromJson(data);
      _isLoaded = true;
      notifyListeners();
      return _currentProfile;
    }

    throw Exception(
      jsonDecode(response.body)['error'] ?? 'Failed to load profile',
    );
  }

  Future<bool> updateProfile(DoctorProfileData updatedData) async {
    final token = await DoctorAuthService().getDoctorToken();
    final doctorId = await DoctorAuthService().getDoctorId();
    if (token == null || doctorId == null) {
      throw Exception('Session not found');
    }

    if (updatedData.name.trim().isEmpty) {
      throw Exception('Name cannot be empty');
    }

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/doctors/$doctorId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': updatedData.name,
        'phone': updatedData.phone,
        'specialization': updatedData.specialty,
        'qualifications': updatedData.qualifications,
        'experience': updatedData.experience,
        'about': updatedData.about,
        'hospitalAffiliation': updatedData.hospitalAffiliation,
        'profileImage': updatedData.profileImage,
        'consultationFees': updatedData.consultationFees,
        'bankDetails': updatedData.bankDetails,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _currentProfile = DoctorProfileData.fromJson(data);
      _isLoaded = true;
      notifyListeners();
      return true;
    }

    throw Exception(
      jsonDecode(response.body)['error'] ?? 'Failed to update profile',
    );
  }

  Future<String?> uploadProfileImage(PlatformFile file) async {
    final uploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.upload),
    );

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

    final response = await uploadRequest.send();
    final responseBody = await _readStreamedBody(response);
    if (response.statusCode == 200) {
      final respJson = jsonDecode(responseBody);
      if (respJson is Map && respJson['urls'] != null) {
        final urls = List<String>.from(respJson['urls']);
        return urls.isNotEmpty ? _resolveImageUrl(urls.first) : null;
      }
    }
    throw Exception('Failed to upload image');
  }

  Future<String> _readStreamedBody(http.StreamedResponse response) async {
    final bytes = await response.stream.toBytes();
    if (bytes.isEmpty) {
      return '';
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

}
