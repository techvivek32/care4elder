import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../doctor_auth/services/doctor_auth_service.dart';

class WithdrawalRequestModel {
  final String id;
  final double amount;
  final String status;
  final DateTime createdAt;
  final String? rejectionReason;

  WithdrawalRequestModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
  });

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestModel(
      id: json['_id'] ?? '',
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt']),
      rejectionReason: json['rejectionReason'],
    );
  }
}

class WithdrawalService {
  static final WithdrawalService _instance = WithdrawalService._internal();
  factory WithdrawalService() => _instance;
  WithdrawalService._internal();

  Future<List<WithdrawalRequestModel>> getWithdrawalRequests() async {
    final token = await DoctorAuthService().getDoctorToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/withdrawal-requests'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => WithdrawalRequestModel.fromJson(json)).toList();
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to fetch requests');
  }

  Future<WithdrawalRequestModel> createWithdrawalRequest(double amount) async {
    final token = await DoctorAuthService().getDoctorToken();
    if (token == null) throw Exception('Unauthorized');

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/withdrawal-requests'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'amount': amount}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return WithdrawalRequestModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to create request');
  }
}
