import 'dart:math';

import 'package:flutter/foundation.dart';

enum CancellationReason {
  falseAlarm('False Alarm'),
  systemCheck('System Check'),
  testAlert('Test Alert'),
  equipmentMalfunction('Equipment Malfunction'),
  humanError('Human Error'),
  other('Other');

  final String label;
  const CancellationReason(this.label);
}

class CancellationLog {
  final String id;
  final DateTime timestamp;
  final CancellationReason reason;
  final String userId;
  final String? comments;
  final Map<String, dynamic> originalAlertDetails;

  CancellationLog({
    required this.id,
    required this.timestamp,
    required this.reason,
    required this.userId,
    this.comments,
    required this.originalAlertDetails,
  });
}

class EmergencyAuditService extends ChangeNotifier {
  static final EmergencyAuditService _instance = EmergencyAuditService._internal();
  factory EmergencyAuditService() => _instance;
  EmergencyAuditService._internal();

  final List<CancellationLog> _logs = [];

  List<CancellationLog> get logs => List.unmodifiable(_logs);

  void logCancellation({
    required CancellationReason reason,
    required String userId,
    String? comments,
    required Map<String, dynamic> alertDetails,
  }) {
    final log = CancellationLog(
      id: _generateId(),
      timestamp: DateTime.now(),
      reason: reason,
      userId: userId,
      comments: comments,
      originalAlertDetails: alertDetails,
    );
    _logs.insert(0, log);
    notifyListeners();
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '$now-$random';
  }
  
  // For search and filtering
  List<CancellationLog> filterLogs({
    CancellationReason? reason,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) {
    return _logs.where((log) {
      if (reason != null && log.reason != reason) return false;
      if (startDate != null && log.timestamp.isBefore(startDate)) return false;
      if (endDate != null && log.timestamp.isAfter(endDate)) return false;
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesComment = log.comments?.toLowerCase().contains(query) ?? false;
        final matchesUser = log.userId.toLowerCase().contains(query);
        final matchesReason = log.reason.label.toLowerCase().contains(query);
        if (!matchesComment && !matchesUser && !matchesReason) return false;
      }
      return true;
    }).toList();
  }
}
