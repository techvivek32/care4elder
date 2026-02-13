import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../doctor_auth/services/doctor_auth_service.dart';
import '../services/doctor_profile_service.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: DoctorProfileService(),
      builder: (context, child) {
        final profile = DoctorProfileService().currentProfile;
        final fees = profile.consultationFees ?? {};
        final standardFee =
            fees['standard'] ?? profile.consultationFees?['standard'] ?? 500;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: isDark ? Colors.white : Colors.black, size: 20),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            title: Text(
              'Settings',
              style: GoogleFonts.roboto(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('PREFERENCES'),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('PRACTICE'),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.access_time,
                        title: 'Availability',
                        subtitle: 'Manage working hours',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        onTap: () {
                          context.push('/doctor/settings/availability');
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 20,
                        color: isDark ? Colors.white10 : null,
                      ),
                      _buildSettingItem(
                        icon: Icons.credit_card,
                        title: 'Consultation Fee',
                        subtitle: '₹$standardFee per session',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        onTap: () {
                          context.push('/doctor/settings/consultation-fee');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('SECURITY'),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        onTap: () {
                          context.push('/doctor/settings/change-password');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('SUPPORT'),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        onTap: () {},
                      ),
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 20,
                        color: isDark ? Colors.white10 : null,
                      ),
                      _buildSettingItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: isDark ? Colors.white38 : Colors.grey,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('ACCOUNT'),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSettingItem(
                        icon: Icons.logout,
                        title: 'Logout',
                        subtitle: 'Sign out of your account',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.red,
                        ),
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        title: Text(
          'Logout',
          style: GoogleFonts.roboto(
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.roboto(
            color: isDark ? Colors.white70 : AppColors.textGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.roboto(
                color: isDark ? Colors.white38 : AppColors.textGrey,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              'Logout',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await DoctorAuthService().logout();
      if (mounted) {
        context.go('/doctor/login');
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white38 : Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkPremiumGradient
                    : AppColors.premiumGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
