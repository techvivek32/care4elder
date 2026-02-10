import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class CallRequestData {
  final String id;
  final String doctorId;
  final String patientId;
  final String status;
  final String channelName;
  final String patientName;
  final String doctorName;
  final String consultationType;
  final double fee;
  final DateTime createdAt;
  final int duration;
  final String report;
  final String patientProfile;
  final String patientLocation;
  final DateTime? patientDob;

  CallRequestData({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.status,
    required this.channelName,
    required this.patientName,
    required this.doctorName,
    required this.consultationType,
    required this.fee,
    required this.createdAt,
    this.duration = 0,
    this.report = '',
    this.patientProfile = '',
    this.patientLocation = '',
    this.patientDob,
  });

  factory CallRequestData.fromJson(Map<String, dynamic> json) {
    final patient = json['patientId'];
    final doctor = json['doctorId'];
    return CallRequestData(
      id: json['_id'] ?? '',
      doctorId: doctor is Map ? (doctor['_id'] ?? '') : (json['doctorId'] ?? ''),
      patientId: patient is Map ? (patient['_id'] ?? '') : (json['patientId'] ?? ''),
      status: json['status'] ?? 'ringing',
      channelName: json['channelName'] ?? '',
      patientName: patient is Map ? (patient['name'] ?? 'Patient') : 'Patient',
      doctorName: doctor is Map ? (doctor['name'] ?? 'Doctor') : 'Doctor',
      consultationType: json['consultationType'] ?? 'consultation',
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      report: json['report'] ?? '',
      patientProfile: patient is Map ? (patient['profilePictureUrl'] ?? '') : '',
      patientLocation: patient is Map ? (patient['location'] ?? '') : '',
      patientDob: (patient is Map && patient['dateOfBirth'] != null) 
          ? DateTime.tryParse(patient['dateOfBirth']) 
          : null,
    );
  }
}

class CallRequestService {
  Future<CallRequestData?> createCallRequest({
    required String token,
    required String doctorId,
    required String patientId,
    required String consultationType,
    required double fee,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/call-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'doctorId': doctorId,
        'patientId': patientId,
        'consultationType': consultationType,
        'fee': fee,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CallRequestData.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<CallRequestData?> fetchIncomingCallForDoctor({
    required String token,
    required String doctorId,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/call-requests?doctorId=$doctorId&status=ringing',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return CallRequestData.fromJson(data.first);
      }
    }
    return null;
  }

  Future<CallRequestData?> getCallRequest({
    required String token,
    required String callRequestId,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/call-requests/$callRequestId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return CallRequestData.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<CallRequestData?> updateCallRequestStatus({
    required String token,
    required String callRequestId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/call-requests/$callRequestId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return CallRequestData.fromJson(jsonDecode(response.body));
    }
    return null;
  }

  Future<List<CallRequestData>> getDoctorHistory({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/call-requests/doctor-history'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CallRequestData.fromJson(json)).toList();
    }
    return [];
  }

  Future<bool> updateCallReport({
    required String token,
    required String callRequestId,
    String? report,
    int? duration,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    if (report != null) body['report'] = report;
    if (duration != null) body['duration'] = duration;
    if (status != null) body['status'] = status;

    final response = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/call-requests/$callRequestId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }
}
