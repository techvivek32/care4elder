import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../features/doctor_auth/services/doctor_auth_service.dart';
import './profile_service.dart'; // Reuse UserProfile model

class DoctorPatientService {
  static final DoctorPatientService _instance = DoctorPatientService._internal();
  factory DoctorPatientService() => _instance;
  DoctorPatientService._internal();

  Future<UserProfile?> fetchPatientById(String patientId) async {
    try {
      final token = await DoctorAuthService().getDoctorToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/patients/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching patient: $e');
      return null;
    }
  }
}
