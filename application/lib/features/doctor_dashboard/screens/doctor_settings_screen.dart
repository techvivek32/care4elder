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
                        onTap: () {
                          // Show Terms of Service dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
                              title: Text(
                                'Terms of Service',
                                style: GoogleFonts.roboto(
                                  color: isDark ? Colors.white : AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: Text(
                                  'Last updated: 12 March 2026\n\n'
                                  '1. Acceptance of Terms\n'
                                  'By accessing and using the Care4Elder website and services, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.\n\n'
                                  '2. Description of Services\n'
                                  'Care4Elder provides technology-enabled elder care services including but not limited to emergency response, nursing care, physiotherapy, doctor visits, hospital-at-home care, caregiver services, and medical equipment rental. Service availability may vary by location.\n\n'
                                  '3. User Responsibilities\n'
                                  'You agree to:\n'
                                  '• Provide accurate and complete information when using our services\n'
                                  '• Use our services only for lawful purposes\n'
                                  '• Not interfere with the proper functioning of our website\n'
                                  '• Keep your account credentials secure, if applicable\n\n'
                                  '4. Service Availability\n'
                                  'While we strive to provide uninterrupted services, Care4Elder does not guarantee that our website or services will be available at all times. We reserve the right to modify, suspend, or discontinue any part of our services at any time.\n\n'
                                  '5. Payment & Subscriptions\n'
                                  'Certain services require payment through our subscription plans. All fees are as listed on our pricing page and are subject to change with prior notice. Refund policies apply as per the specific plan terms.\n\n'
                                  '6. Limitation of Liability\n'
                                  'Care4Elder shall not be liable for any indirect, incidental, special, or consequential damages arising out of or in connection with the use of our services. Our total liability shall not exceed the amount paid by you for the specific service in question.\n\n'
                                  '7. Intellectual Property\n'
                                  'All content on the Care4Elder website, including text, graphics, logos, and software, is the property of Care4Elder and is protected by applicable intellectual property laws. Unauthorized use is prohibited.\n\n'
                                  '8. Governing Law\n'
                                  'These Terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in Asansol, West Bengal.\n\n'
                                  '9. Contact Us\n'
                                  'For questions regarding these Terms of Service, please contact us at:\n\n'
                                  'Care4Elder\n'
                                  'Email: connect.us@care4elder.com\n'
                                  'Phone: 0341-3543415',
                                  style: GoogleFonts.roboto(
                                    color: isDark ? Colors.white70 : AppColors.textGrey,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.roboto(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
                        onTap: () {
                          // Show Help & Support dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
                              title: Text(
                                'Help & Support',
                                style: GoogleFonts.roboto(
                                  color: isDark ? Colors.white : AppColors.textDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'For questions regarding these Terms of Service, please contact us at:\n\n'
                                      'Care4Elder\n'
                                      'Email: connect.us@care4elder.com\n'
                                      'Phone: 0341-3543415',
                                      style: GoogleFonts.roboto(
                                        color: isDark ? Colors.white70 : AppColors.textGrey,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Close',
                                    style: GoogleFonts.roboto(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
