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
}
