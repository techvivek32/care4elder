import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/api_constants.dart';
import '../../features/auth/services/auth_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'emergency', 'appointment', 'tip', 'general'
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      timestamp: DateTime.parse(json['createdAt'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final ValueNotifier<List<AppNotification>> notificationsNotifier =
      ValueNotifier([]);
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isLoadingMoreNotifier = ValueNotifier(false);
  final ValueNotifier<bool> hasMoreNotifier = ValueNotifier(true);

  int _currentPage = 1;
  static const int _itemsPerPage = 20;

  Future<void> fetchNotifications({int page = 1, String filter = 'all'}) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/notifications?page=$page&limit=$_itemsPerPage&filter=$filter'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notificationsJson = data['notifications'] ?? [];
        
        final notifications = notificationsJson
            .map((json) => AppNotification.fromJson(json))
            .toList();

        if (page == 1) {
          notificationsNotifier.value = notifications;
        } else {
          notificationsNotifier.value = [
            ...notificationsNotifier.value,
            ...notifications,
          ];
        }

        unreadCountNotifier.value = data['unreadCount'] ?? 0;
        hasMoreNotifier.value = data['pagination']?['hasMore'] ?? false;
        _currentPage = page;
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMoreNotifier.value || !hasMoreNotifier.value) return;

    isLoadingMoreNotifier.value = true;
    await fetchNotifications(page: _currentPage + 1);
    isLoadingMoreNotifier.value = false;
  }

  Future<void> markAsRead(String id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'isRead': true}),
      );

      if (response.statusCode == 200) {
        final list = List<AppNotification>.from(notificationsNotifier.value);
        final index = list.indexWhere((n) => n.id == id);
        if (index != -1) {
          list[index].isRead = true;
          notificationsNotifier.value = list;
          _updateUnreadCount();
        }
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> toggleReadStatus(String id) async {
    try {
      final list = List<AppNotification>.from(notificationsNotifier.value);
      final index = list.indexWhere((n) => n.id == id);
      if (index == -1) return;

      final newStatus = !list[index].isRead;
      
      final token = await AuthService().getToken();
      if (token == null) return;

      final response = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'isRead': newStatus}),
      );

      if (response.statusCode == 200) {
        list[index].isRead = newStatus;
        notificationsNotifier.value = list;
        _updateUnreadCount();
      }
    } catch (e) {
      debugPrint('Error toggling read status: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final list = List<AppNotification>.from(notificationsNotifier.value);
        for (var n in list) {
          n.isRead = true;
        }
        notificationsNotifier.value = list;
        unreadCountNotifier.value = 0;
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/notifications/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final list = List<AppNotification>.from(notificationsNotifier.value);
        list.removeWhere((n) => n.id == id);
        notificationsNotifier.value = list;
        _updateUnreadCount();
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  void _updateUnreadCount() {
    unreadCountNotifier.value = notificationsNotifier.value
        .where((n) => !n.isRead)
        .length;
  }

  // Helper method to create notification (for testing or system use)
  Future<void> createNotification({
    required String title,
    required String body,
    required String type,
    String? userId,
  }) async {
    try {
      final token = await AuthService().getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('${ApiConstants.baseUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title,
          'body': body,
          'type': type,
          if (userId != null) 'userId': userId,
        }),
      );
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }
}
