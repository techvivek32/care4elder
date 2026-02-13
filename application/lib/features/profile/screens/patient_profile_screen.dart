import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';

class PatientProfileScreen extends StatelessWidget {
  const PatientProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Clear auth state
      await AuthService().signOut();
      if (context.mounted) {
        context.go('/selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.light
                ? AppColors.premiumGradient
                : AppColors.darkPremiumGradient,
          ),
        ),
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Profile Settings',
              onTap: () => context.push('/patient/profile/personal-info'),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'My Wallet',
              onTap: () => context.push('/patient/profile/wallet'),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context,
              icon: Icons.people_outline,
              title: 'Emergency Contacts',
              onTap: () => context.push('/patient/contacts'),
            ),
            const SizedBox(height: 16),
            /*
            _buildMenuItem(
              context,
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () => context.push('/patient/notifications'),
            ),
            const SizedBox(height: 16),
            */
            _buildMenuItem(
              context,
              icon: Icons.settings_applications_outlined,
              title: 'App Settings',
              onTap: () => context.push('/patient/profile/settings'),
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: isDarkMode
                    ? AppColors.darkPremiumGradient
                    : AppColors.premiumGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
