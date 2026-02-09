import 'package:flutter/foundation.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'emergency', 'appointment', 'tip'
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
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _initMockData();
  }

  final ValueNotifier<List<AppNotification>> notificationsNotifier =
      ValueNotifier([]);
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isLoadingMoreNotifier = ValueNotifier(false);
  final ValueNotifier<bool> hasMoreNotifier = ValueNotifier(true);

  // Simulated pagination
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  void _initMockData() {
    _loadPage(1);
  }

  Future<void> loadMore() async {
    if (isLoadingMoreNotifier.value || !hasMoreNotifier.value) return;

    isLoadingMoreNotifier.value = true;

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));

    _currentPage++;
    _loadPage(_currentPage);

    isLoadingMoreNotifier.value = false;
  }

  void _loadPage(int page) {
    final now = DateTime.now();
    // Generate mock data for the requested page
    final newNotifications = List.generate(_itemsPerPage, (index) {
      final globalIndex = (page - 1) * _itemsPerPage + index;
      final timeOffset = Duration(
        hours: globalIndex * 2,
      ); // Spread out over time

      // Rotate types
      final types = ['emergency', 'appointment', 'tip'];
      final type = types[globalIndex % 3];

      return AppNotification(
        id: 'notification_$globalIndex',
        title: _getMockTitle(type, globalIndex),
        body: _getMockBody(type, globalIndex),
        type: type,
        timestamp: now.subtract(timeOffset),
        isRead: globalIndex > 2, // First few are unread
      );
    });

    if (page == 1) {
      notificationsNotifier.value = newNotifications;
    } else {
      notificationsNotifier.value = [
        ...notificationsNotifier.value,
        ...newNotifications,
      ];
    }

    // Stop after 5 pages for demo
    if (page >= 5) {
      hasMoreNotifier.value = false;
    }

    _updateUnreadCount();
  }

  String _getMockTitle(String type, int index) {
    switch (type) {
      case 'emergency':
        return 'Emergency Alert #$index';
      case 'appointment':
        return 'Appointment Reminder #$index';
      case 'tip':
        return 'Health Tip #$index';
      default:
        return 'Notification #$index';
    }
  }

  String _getMockBody(String type, int index) {
    switch (type) {
      case 'emergency':
        return 'Your SOS signal was received. Help is on the way.';
      case 'appointment':
        return 'You have an appointment with Dr. Smith tomorrow at 10:00 AM.';
      case 'tip':
        return 'Remember to drink water and stay hydrated throughout the day.';
      default:
        return 'This is a notification body text for item #$index.';
    }
  }

  void _updateUnreadCount() {
    unreadCountNotifier.value = notificationsNotifier.value
        .where((n) => !n.isRead)
        .length;
  }

  void markAsRead(String id) {
    final list = List<AppNotification>.from(notificationsNotifier.value);
    final index = list.indexWhere((n) => n.id == id);
    if (index != -1 && !list[index].isRead) {
      list[index].isRead = true;
      notificationsNotifier.value = list;
      _updateUnreadCount();
    }
  }

  void toggleReadStatus(String id) {
    final list = List<AppNotification>.from(notificationsNotifier.value);
    final index = list.indexWhere((n) => n.id == id);
    if (index != -1) {
      list[index].isRead = !list[index].isRead;
      notificationsNotifier.value = list;
      _updateUnreadCount();
    }
  }

  void markAllAsRead() {
    final list = List<AppNotification>.from(notificationsNotifier.value);
    for (var n in list) {
      n.isRead = true;
    }
    notificationsNotifier.value = list;
    _updateUnreadCount();
  }

  void deleteNotification(String id) {
    final list = List<AppNotification>.from(notificationsNotifier.value);
    list.removeWhere((n) => n.id == id);
    notificationsNotifier.value = list;
    _updateUnreadCount();
  }
}
