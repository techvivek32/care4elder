import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Preferences State
  final Map<String, bool> _preferences = {
    'emergency': true,
    'appointment': true,
    'tips': true,
  };

  // Filter State
  String _currentFilter = 'All'; // 'All', 'Unread', 'Read'
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      NotificationService().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.roboto(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              NotificationService().markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                ),
              );
            },
            child: Text(
              'Mark all as read',
              style: GoogleFonts.roboto(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simulate refresh delay
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preferences Section
              _buildPreferencesCard(),
              const SizedBox(height: 24),

              // Recent / List Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  // Filter Chips
                  Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Unread'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Read'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notification List
              ValueListenableBuilder<List<AppNotification>>(
                valueListenable: NotificationService().notificationsNotifier,
                builder: (context, notifications, child) {
                  final filteredNotifications = _filterNotifications(
                    notifications,
                  );

                  if (filteredNotifications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'No notifications found',
                          style: GoogleFonts.roboto(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(
                        filteredNotifications[index],
                      );
                    },
                  );
                },
              ),

              // Loading Indicator
              ValueListenableBuilder<bool>(
                valueListenable: NotificationService().isLoadingMoreNotifier,
                builder: (context, isLoading, child) {
                  if (!isLoading) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  List<AppNotification> _filterNotifications(
    List<AppNotification> notifications,
  ) {
    if (_currentFilter == 'Unread') {
      return notifications.where((n) => !n.isRead).toList();
    } else if (_currentFilter == 'Read') {
      return notifications.where((n) => n.isRead).toList();
    }
    return notifications;
  }

  Widget _buildPreferencesCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Preferences',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          _buildPreferenceItem(
            'Emergency alerts',
            'Critical safety updates',
            Icons.warning_amber_rounded,
            'emergency',
          ),
          _buildPreferenceItem(
            'Appointment reminders',
            'Upcoming visits and follow-ups',
            Icons.check_circle_outline_rounded,
            'appointment',
          ),
          _buildPreferenceItem(
            'Health tips',
            'Daily wellness suggestions',
            Icons.check_circle_outline_rounded,
            'tips',
            iconData: Icons.check_circle_outline_rounded,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem(
    String title,
    String subtitle,
    IconData icon,
    String key, {
    IconData? iconData,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      value: _preferences[key] ?? true,
      onChanged: (val) {
        setState(() {
          _preferences[key] = val;
        });
      },
      activeTrackColor: colorScheme.primary,
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        return Colors.white;
      }),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.roboto(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          iconData ?? icon,
          color: colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildFilterChip(String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _currentFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        NotificationService().deleteNotification(notification.id);
      },
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () =>
                NotificationService().toggleReadStatus(notification.id),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: Theme.of(context).brightness == Brightness.light
                          ? AppColors.premiumGradient
                          : AppColors.darkPremiumGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.blue
                                  : const Color(0xFF041E34))
                              .withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getTypeIcon(notification.type),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: GoogleFonts.roboto(
                                  fontWeight: notification.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: GoogleFonts.roboto(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: GoogleFonts.roboto(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'emergency':
        return Colors.red;
      case 'appointment':
        return Colors.blue;
      case 'tip':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'appointment':
        return Icons.check_circle_outline_rounded;
      case 'tip':
        return Icons.notifications_none_rounded;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }
}
