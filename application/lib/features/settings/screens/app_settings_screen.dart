import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/theme/app_colors.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: SettingsService(),
        builder: (context, child) {
          final settings = SettingsService();
          if (settings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader('Appearance'),
              _buildSwitchTile(
                context: context,
                title: 'Dark Mode',
                subtitle: 'Enable dark theme for the application',
                icon: Icons.dark_mode_outlined,
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (value) => settings.toggleTheme(value),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('General'),
              _buildSwitchTile(
                context: context,
                title: 'Notifications',
                subtitle: 'Enable push notifications',
                icon: Icons.notifications_outlined,
                value: settings.notificationsEnabled,
                onChanged: (value) => settings.setNotifications(value),
              ),
              const SizedBox(height: 12),
              _buildListTile(
                context: context,
                title: 'Language',
                subtitle: settings.language,
                icon: Icons.language,
                onTap: () => _showLanguageDialog(context, settings),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Data & Privacy'),
              _buildListTile(
                context: context,
                title: 'Data Backup',
                subtitle: 'Last backup: Never',
                icon: Icons.backup_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Backup feature coming soon')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildListTile(
                context: context,
                title: 'Privacy Policy',
                subtitle: 'View privacy policy',
                icon: Icons.privacy_tip_outlined,
                onTap: () {},
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Account'),
              _buildListTile(
                context: context,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                icon: Icons.logout,
                onTap: () => _handleLogout(context),
                isDestructive: true,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.roboto(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        activeTrackColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

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
      await AuthService().signOut();
      if (context.mounted) {
        context.go('/selection');
      }
    }
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    SettingsService settings,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              settings.setLanguage('English');
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('English'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              settings.setLanguage('Spanish');
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Spanish'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              settings.setLanguage('Hindi');
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Hindi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDestructive
                ? AppColors.error
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.roboto(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withOpacity(0.1)
                : AppColors.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primaryBlue,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withOpacity(0.5),
        ),
      ),
    );
  }
}
