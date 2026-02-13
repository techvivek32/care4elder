import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      if (kDebugMode) print('SOS_LOG: startSOS requested');
      // 1. Check/Request Permissions
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      // 2. Get Location
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } on TimeoutException catch (e) {
        if (kDebugMode) print('SOS_ERROR: Location timeout: $e');
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          position = lastKnown;
        } else {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
        }
      } catch (e) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          position = lastKnown;
        } else {
          rethrow;
        }
      }
      
      // 3. Get User ID
      if (_profileService.currentUser == null) {
        if (kDebugMode) print('Background: Profile not found, attempting fetch...');
        try {
          await _profileService.fetchProfile();
        } catch (e) {
          if (kDebugMode) print('Background fetchProfile failed: $e');
        }
      }
      
      final patientId = _profileService.currentUser?.id;
      if (kDebugMode) print('Background SOS Trigger - Patient ID: $patientId');

      if (patientId == null) {
        // Last ditch effort: try to get it directly from storage
        if (kDebugMode) print('Background: Patient ID null, trying direct storage read...');
        final directId = await _authService.getPatientId();
        if (directId == null) throw Exception('User not logged in (Patient ID missing)');
        // If we found it directly, we can continue even if profile object is null
      }
      
      final finalPatientId = patientId ?? (await _authService.getPatientId());
      if (finalPatientId == null) throw Exception('User not logged in');

      // 3. Call API
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/sos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patientId': finalPatientId,
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
          }
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final sosId = data['_id'];
        if (kDebugMode) print('SOS_LOG: SOS created successfully, ID: $sosId');

        // 4. Save State Locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isSosActiveKey, true);
        await prefs.setString(_activeSosIdKey, sosId);
        await prefs.setInt(_sosStartTimeKey, DateTime.now().millisecondsSinceEpoch);
      } else {
        if (kDebugMode) print('SOS_ERROR: Failed to create SOS alert: ${response.statusCode} ${response.body}');
        throw Exception('Failed to create SOS alert: ${response.body}');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('SOS_ERROR: $e');
        print('SOS_STACK: $stack');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSOSStatus(String sosId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/sos/$sosId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      if (kDebugMode) print('SOS_ERROR: getSOSStatus failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e, stack) {
      if (kDebugMode) {
        print('SOS_ERROR: getSOSStatus Error: $e');
        print('SOS_STACK: $stack');
      }
      return null;
    }
  }

  Future<void> stopSOS({String? cancellationReason, String? cancellationComments}) async {
    try {
      final sosId = await getActiveSosId();
      if (sosId != null) {
        final token = await _authService.getToken();
        final requestBody = <String, dynamic>{
          'id': sosId,
          'status': 'resolved',
          if (cancellationReason != null) 'cancellationReason': cancellationReason,
          if (cancellationReason != null) 'reason': cancellationReason,
          if (cancellationComments != null) 'cancellationComments': cancellationComments,
          if (cancellationComments != null) 'comments': cancellationComments,
        };
        print('SOS Stop payload: ${jsonEncode(requestBody)}');
        final response = await http.patch(
          Uri.parse('${ApiConstants.baseUrl}/sos'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode != 200) {
          print('SOS Stop failed: ${response.statusCode} ${response.body}');
          throw Exception('Failed to update SOS status: ${response.body}');
        }

        print('SOS Stop success: ${response.statusCode} ${response.body}');
      } else {
        throw Exception('No active SOS found');
      }
      
      // Clear Local State
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isSosActiveKey);
      await prefs.remove(_activeSosIdKey);
      await prefs.remove(_sosStartTimeKey);
    } catch (e) {
      print('SOS Stop Error: $e');
      rethrow;
    }
  }
}
