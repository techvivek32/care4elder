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

  /// When [relaxedLocationForBackground] is true (fall/voice from background isolate), never throw
  /// on location off or missing permission — POST SOS with 0,0 if needed. UI path keeps strict checks.
  Future<void> startSOS({bool relaxedLocationForBackground = false}) async {
    try {
      if (kDebugMode) {
        print('SOS_LOG: startSOS requested (relaxedBg=$relaxedLocationForBackground)');
      }

      Position? position;

      if (!relaxedLocationForBackground) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services are disabled.');
        }

        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            throw Exception('Location permissions are denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          throw Exception(
            'Location permissions are permanently denied, we cannot request permissions.',
          );
        }

        final locationFuture = Geolocator.getLastKnownPosition().catchError((_) => null);
        final profileFuture = Future(() async {
          if (_profileService.currentUser == null) {
            try {
              await _profileService.fetchProfile();
            } catch (_) {}
          }
        });
        final results = await Future.wait([locationFuture, profileFuture]);
        position = results[0] as Position?;

        if (position == null) {
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
              timeLimit: const Duration(seconds: 5),
            );
          } catch (_) {}
        }
      } else {
        try {
          if (await Geolocator.isLocationServiceEnabled()) {
            final permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always) {
              position = await Geolocator.getLastKnownPosition().catchError((_) => null);
              position ??= await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.low,
                timeLimit: const Duration(seconds: 4),
              ).catchError((_) => null);
            }
          }
        } catch (_) {}
        if (_profileService.currentUser == null) {
          try {
            await _profileService.fetchProfile();
          } catch (_) {}
        }
      }

      // SOS must go through regardless of location — use 0,0 as fallback
      final lat = position?.latitude ?? 0.0;
      final lng = position?.longitude ?? 0.0;
      if (kDebugMode) print('SOS_LOG: Using location: $lat, $lng');

      // 3. Get User ID
      final patientId = _profileService.currentUser?.id;
      if (kDebugMode) print('SOS_LOG: Patient ID: $patientId');

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
            'lat': lat,
            'lng': lng,
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
    // Always clear local state — even if API fails
    Future<void> clearLocalState() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isSosActiveKey);
      await prefs.remove(_activeSosIdKey);
      await prefs.remove(_sosStartTimeKey);
    }

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
        if (kDebugMode) print('SOS Stop payload: ${jsonEncode(requestBody)}');
        final response = await http.patch(
          Uri.parse('${ApiConstants.baseUrl}/sos'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(requestBody),
        );

        if (response.statusCode != 200) {
          if (kDebugMode) print('SOS Stop failed: ${response.statusCode} ${response.body}');
          // Still clear local state so UI doesn't stay stuck
          await clearLocalState();
          throw Exception('Failed to update SOS status: ${response.body}');
        }

        if (kDebugMode) print('SOS Stop success: ${response.statusCode} ${response.body}');
      }
      // Clear local state regardless (sosId null or API success)
      await clearLocalState();
    } catch (e) {
      if (kDebugMode) print('SOS Stop Error: $e');
      // Ensure local state is always cleared
      await clearLocalState();
      rethrow;
    }
  }
}
