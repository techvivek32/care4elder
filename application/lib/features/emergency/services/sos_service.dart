import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/profile_service.dart';

class SOSService {
  static const String _isSosActiveKey = 'is_sos_active';
  static const String _activeSosIdKey = 'active_sos_id';
  static const String _sosStartTimeKey = 'sos_start_time';

  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();

  Future<bool> isSosActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSosActiveKey) ?? false;
  }

  Future<String?> getActiveSosId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeSosIdKey);
  }

  Future<DateTime?> getSosStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_sosStartTimeKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> startSOS() async {
    try {
      // 1. Get Location
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 2. Get User ID
      if (_profileService.currentUser == null) {
        await _profileService.fetchProfile();
      }
      final patientId = _profileService.currentUser?.id;

      if (patientId == null) throw Exception('User not logged in');

      // 3. Call API
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/sos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patientId': patientId,
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
          }
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final sosId = data['_id'];

        // 4. Save State Locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isSosActiveKey, true);
        await prefs.setString(_activeSosIdKey, sosId);
        await prefs.setInt(_sosStartTimeKey, DateTime.now().millisecondsSinceEpoch);
      } else {
        throw Exception('Failed to create SOS alert: ${response.body}');
      }
    } catch (e) {
      print('SOS Start Error: $e');
      rethrow;
    }
  }

  Future<void> stopSOS() async {
    try {
      final sosId = await getActiveSosId();
      if (sosId != null) {
        final token = await _authService.getToken();
        await http.patch(
          Uri.parse('${ApiConstants.baseUrl}/sos'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'id': sosId,
            'status': 'resolved',
          }),
        );
      }
      
      // Clear Local State
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isSosActiveKey);
      await prefs.remove(_activeSosIdKey);
      await prefs.remove(_sosStartTimeKey);
    } catch (e) {
      print('SOS Stop Error: $e');
      // Even if API fails, we should probably clear local state or retry
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isSosActiveKey);
      await prefs.remove(_activeSosIdKey);
      await prefs.remove(_sosStartTimeKey);
    }
  }
}
