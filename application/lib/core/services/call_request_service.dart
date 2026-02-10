import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  final String reportUrl;
  final List<String> prescriptions;
  final List<String> labReports;
  final List<String> medicalDocuments;
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
    this.reportUrl = '',
    this.prescriptions = const [],
    this.labReports = const [],
    this.medicalDocuments = const [],
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
      reportUrl: json['reportUrl'] ?? '',
      prescriptions: (json['prescriptions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      labReports: (json['labReports'] as List?)?.map((e) => e.toString()).toList() ?? [],
      medicalDocuments: (json['medicalDocuments'] as List?)?.map((e) => e.toString()).toList() ?? [],
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
    String? reportUrl,
    int? duration,
    String? status,
    List<String>? prescriptions,
    List<String>? labReports,
    List<String>? medicalDocuments,
  }) async {
    final body = <String, dynamic>{};
    if (report != null) body['report'] = report;
    if (reportUrl != null) body['reportUrl'] = reportUrl;
    if (duration != null) body['duration'] = duration;
    if (status != null) body['status'] = status;
    if (prescriptions != null) body['prescriptions'] = prescriptions;
    if (labReports != null) body['labReports'] = labReports;
    if (medicalDocuments != null) body['medicalDocuments'] = medicalDocuments;

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

  Future<String?> uploadReportFile({
    required String token,
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/upload'),
    );
    
    // Add file
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    // Add headers (Authorization if needed, though upload route might be public or check generic auth)
    // The current upload route doesn't seem to check auth, but it's good practice.
    // However, the upload route in Next.js example didn't show auth check middleware explicitly, 
    // but usually it's handled. For now, we'll just send the file.
    
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['urls'] != null && (data['urls'] as List).isNotEmpty) {
          return (data['urls'] as List).first as String;
        }
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
    }
    return null;
  }
}
