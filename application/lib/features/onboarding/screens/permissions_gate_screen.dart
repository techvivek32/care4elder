import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';

class _PermissionItem {
  final IconData icon;
  final String title;
  final String description;
  final bool mandatory;
  final Permission permission;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.mandatory,
    required this.permission,
  });
}

const List<_PermissionItem> _permissions = [
  _PermissionItem(
    icon: Icons.location_on_outlined,
    title: 'Location',
    description: 'Required for SOS & fall detection to share your location',
    mandatory: true,
    permission: Permission.location,
  ),
  _PermissionItem(
    icon: Icons.videocam_outlined,
    title: 'Camera',
    description: 'Required for video consultations with doctors',
    mandatory: true,
    permission: Permission.camera,
  ),
  _PermissionItem(
    icon: Icons.mic_none_outlined,
    title: 'Microphone',
    description: 'Required for audio during video calls and SOS',
    mandatory: true,
    permission: Permission.microphone,
  ),
  _PermissionItem(
    icon: Icons.contacts_outlined,
    title: 'Contacts',
    description: 'To add emergency contacts for SOS alerts',
    mandatory: false,
    permission: Permission.contacts,
  ),
  _PermissionItem(
    icon: Icons.notifications_none_outlined,
    title: 'Notifications',
    description: 'To receive SOS alerts and health updates',
    mandatory: false,
    permission: Permission.notification,
  ),
  _PermissionItem(
    icon: Icons.battery_charging_full_outlined,
    title: 'Battery Optimization',
    description: 'Keeps fall detection active even when app is in background',
    mandatory: false,
    permission: Permission.ignoreBatteryOptimizations,
  ),
];

class PermissionsGateScreen extends StatefulWidget {
  const PermissionsGateScreen({super.key});

  @override
  State<PermissionsGateScreen> createState() => _PermissionsGateScreenState();
}

class _PermissionsGateScreenState extends State<PermissionsGateScreen> {
  bool _loading = false;

  Future<void> _handleAllow() async {
    setState(() => _loading = true);

    for (final item in _permissions) {
      await item.permission.request();
    }

    await PermissionService().setPermissionsRequested();

    setState(() => _loading = false);

    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF0F4F8);
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.primaryBlue;
    final subtitleColor = isDark ? Colors.white60 : AppColors.textGrey;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please Allow Access',
                        style: GoogleFonts.roboto(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'These permissions help us keep you safe',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ..._permissions.map(
                        (item) => _PermissionCard(
                          item: item,
                          cardBg: cardBg,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // SSL badge
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: subtitleColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '100% Data Security',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? AppColors.darkPremiumGradient
                          : AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleAllow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Allow Access',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final _PermissionItem item;
  final Color cardBg;
  final bool isDark;

  const _PermissionCard({
    required this.item,
    required this.cardBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mandatoryColor = isDark ? const Color(0xFF1565C0) : AppColors.primaryBlue;
    final importantColor = isDark ? Colors.white24 : const Color(0xFF757575);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? AppColors.darkPremiumGradient
                        : AppColors.premiumGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.title} Permission',
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.description,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : AppColors.textGrey,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Mandatory / Important badge
          Positioned(
            top: -10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: item.mandatory ? mandatoryColor : importantColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.mandatory ? 'Mandatory' : 'Important',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
