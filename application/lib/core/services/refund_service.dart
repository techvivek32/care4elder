import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class RefundService {
  Future<List<Map<String, dynamic>>> fetchMyRefundRequests(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/refund-requests'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['refunds'] ?? []);
      }
    } catch (e) {
      debugPrint('fetchMyRefundRequests error: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> submitRefundRequest({
    required String token,
    required String callRequestId,
    required String doctorId,
    required double amount,
    required String reason,
    required String patientName,
    required String doctorName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/refund-requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'callRequestId': callRequestId,
          'doctorId': doctorId,
          'amount': amount,
          'reason': reason,
          'patientName': patientName,
          'doctorName': doctorName,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to submit refund request'};
      }
    } catch (e) {
      debugPrint('RefundService error: $e');
      return {'success': false, 'error': 'Network error'};
    }
  }
}
