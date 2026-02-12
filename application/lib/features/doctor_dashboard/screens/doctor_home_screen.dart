import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/call_request_service.dart';
import '../../../core/services/hero_service.dart';
import '../../doctor_auth/services/doctor_auth_service.dart';
import '../services/doctor_profile_service.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final DoctorProfileService _profileService = DoctorProfileService();
  late final ValueNotifier<int> _unreadCountNotifier;
  final CallRequestService _callService = CallRequestService();
  Timer? _incomingCallTimer;
  bool _checkingIncoming = false;
  String? _activeCallId;

  // Carousel controller and timer
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _carouselTimer;
  List<HeroSection> _heroSections = [];
  bool _isLoadingHeroes = true;

  @override
  void initState() {
    super.initState();
    // Ensure we have a valid notifier
    _unreadCountNotifier = NotificationService().unreadCountNotifier;
    _loadProfile();
    _startIncomingCallPolling();
    _loadHeroSections();
  }

  Future<void> _loadHeroSections() async {
    try {
      final heroes = await HeroService.fetchHeroSections('doctor');
      if (mounted) {
        setState(() {
          _heroSections = heroes;
          _isLoadingHeroes = false;
        });
        if (_heroSections.isNotEmpty) {
          _startCarouselTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHeroes = false;
        });
      }
    }
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _heroSections.isNotEmpty) {
        _currentPage = (_currentPage + 1) % _heroSections.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadProfile() async {
    try {
      await _profileService.getProfile();
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  String _getGreeting() {
    // IST is UTC + 5:30
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  void dispose() {
    _incomingCallTimer?.cancel();
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startIncomingCallPolling() {
    _incomingCallTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkIncomingCall();
    });
  }

  Future<void> _checkIncomingCall() async {
    if (_checkingIncoming) return;
    final profile = _profileService.currentProfile;
    if (!profile.isAvailable) return;
    
    // If we are on Home Screen and status is busy, it might be a leftover from a previous call
    // However, we should only reset if we are sure no call is active.
    // To be safe, we'll let the VideoCallScreen handle its own status.
    // Only reset if it's been busy for a long time without an active call (not implemented here)

    if (_activeCallId != null) return;

    _checkingIncoming = true;
    try {
      final token = await DoctorAuthService().getDoctorToken();
      final doctorId = await DoctorAuthService().getDoctorId();
      if (token == null || doctorId == null) {
        _checkingIncoming = false;
        return;
      }

      final incoming = await _callService.fetchIncomingCallForDoctor(
        token: token,
        doctorId: doctorId,
      );

      if (incoming == null || incoming.status != 'ringing') {
        _checkingIncoming = false;
        return;
      }

      _activeCallId = incoming.id;
      if (!mounted) {
        _checkingIncoming = false;
        return;
      }

      final result = await _showIncomingCallDialog(incoming);
      if (!mounted) {
        _activeCallId = null;
        _checkingIncoming = false;
        return;
      }

      if (result == 'accept') {
        await _callService.updateCallRequestStatus(
          token: token,
          callRequestId: incoming.id,
          status: 'accepted',
        );
        if (mounted) {
          context.push('/doctor/call-room', extra: {
            'channel': incoming.channelName,
            'remoteName': incoming.patientName,
            'callRequestId': incoming.id,
          });
        }
      } else if (result == 'decline') {
        await _callService.updateCallRequestStatus(
          token: token,
          callRequestId: incoming.id,
          status: 'declined',
        );
      }
      _activeCallId = null;
    } finally {
      _checkingIncoming = false;
    }
  }

  Future<String?> _showIncomingCallDialog(CallRequestData call) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Incoming Call',
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Patient: ${call.patientName}'),
              const SizedBox(height: 8),
              Text(
                call.consultationType == 'emergency'
                    ? 'Emergency Call'
                    : 'Consultation Call',
              ),
              const SizedBox(height: 8),
              Text('Fee: ₹${call.fee.toStringAsFixed(0)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'decline'),
              child: const Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // Carousel
              _buildCarousel(),
              const SizedBox(height: 24),

              // Status Card
              _buildStatusCard(),
              const SizedBox(height: 24),

              // Stats Row
              _buildStatsRow(),
              const SizedBox(height: 24),

              // Quick Actions
              _buildSectionHeader('Quick Actions'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: 'History',
                      subtitle: 'Past consults',
                      icon: Icons.access_time,
                      color: const Color(0xFFE0E7FF), // Light Blue
                      iconColor: AppColors.primaryBlue,
                      onTap: () => context.push('/doctor/history'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: 'Earnings',
                      subtitle: '₹24,500',
                      icon: Icons.trending_up,
                      color: const Color(0xFFDCFCE7), // Light Green
                      iconColor: Colors.green,
                      onTap: () => context.push('/doctor/earnings'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Tagline
              Center(
                child: Column(
                  children: [
                    Text(
                      'Smart Care with Human Touch',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryBlue.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    if (_isLoadingHeroes) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_heroSections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _heroSections.length,
            itemBuilder: (context, index) {
              final item = _heroSections[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(24),
                  image: DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (item.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Carousel Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _heroSections.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.primaryBlue
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return ListenableBuilder(
      listenable: _profileService,
      builder: (context, _) {
        final profile = _profileService.currentProfile;
        final greeting = _getGreeting();
        
        return Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: profile.profileImage != null && profile.profileImage!.isNotEmpty
                  ? NetworkImage(profile.profileImage!)
                  : const AssetImage('assets/images/doctor_profile.png') as ImageProvider,
              child: (profile.profileImage == null || profile.profileImage!.isEmpty) 
                  ? const Icon(Icons.person, color: Colors.grey) 
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                  Text(
                    profile.name.isNotEmpty ? profile.name : 'Dr. User',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/doctor/notifications'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textDark,
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: ValueListenableBuilder<int>(
                        valueListenable: _unreadCountNotifier,
                        builder: (context, count, child) {
                          if (count <= 0) {
                            return const SizedBox.shrink();
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(minWidth: 16),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusCard() {
    return ListenableBuilder(
      listenable: _profileService,
      builder: (context, _) {
        final profile = _profileService.currentProfile;
        // Use profile status, default to true if not loaded
        final isOnline = profile.isAvailable;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Status',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOnline
                            ? 'You are accepting consultations'
                            : 'You are offline',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isOnline,
                      activeThumbColor: Colors.green,
                      onChanged: (value) {
                         _updateStatus(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isOnline) ...[
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live - Accepting new requests',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Future<void> _updateStatus(bool value) async {
    try {
      await _profileService.updateAvailability(value);
      try {
        final newStatus = value ? 'online' : 'offline';
        await _profileService.updateStatus(newStatus);
        debugPrint('Doctor status manually updated to: $newStatus');
      } catch (e) {
        debugPrint('Secondary status update failed: $e');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline,
            value: '8',
            label: 'Today',
            iconColor: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.trending_up,
            value: '42',
            label: 'This Week',
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.schedule,
            value: '3',
            label: 'Pending',
            iconColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onActionTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        if (onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Row(
              children: [
                Text(
                  'View All',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRequestCard({
    required String name,
    required String time,
    required String type,
    required String reason,
    required bool isNew,
    required String imageAsset,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: AssetImage(imageAsset),
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'New',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          type == 'Video'
                              ? Icons.videocam_outlined
                              : Icons.phone_outlined,
                          size: 14,
                          color: AppColors.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          type,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
