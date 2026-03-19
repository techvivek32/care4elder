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

class DoctorTransactionModel {
  final String id;
  final String type; // 'credit' | 'debit'
  final double amount;
  final String description;
  final double balanceAfter;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  DoctorTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.balanceAfter,
    this.metadata,
    required this.createdAt,
  });

  factory DoctorTransactionModel.fromJson(Map<String, dynamic> json) {
    return DoctorTransactionModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'credit',
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt']),
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

  Future<List<DoctorTransactionModel>> getDoctorTransactions() async {
    try {
      final token = await DoctorAuthService().getDoctorToken();
      final doctorId = await DoctorAuthService().getDoctorId();
      if (token == null || doctorId == null) return [];

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/doctors/$doctorId/transactions'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['transactions'] ?? [])
            .map((j) => DoctorTransactionModel.fromJson(j))
            .toList();
      }
    } catch (e) {
      debugPrint('getDoctorTransactions error: $e');
    }
    return [];
  }
}
