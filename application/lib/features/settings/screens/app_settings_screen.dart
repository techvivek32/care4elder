import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/background_service.dart';
import '../../../core/theme/app_colors.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  bool _backgroundServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBackgroundServiceState();
  }

  Future<void> _loadBackgroundServiceState() async {
    final isRunning = await BackgroundServiceHelper.isServiceRunning();
    setState(() {
      _backgroundServiceEnabled = isRunning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.light
                ? AppColors.premiumGradient
                : AppColors.darkPremiumGradient,
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
              _buildSectionHeader('Appearance', context),
              _buildSwitchTile(
                context: context,
                title: 'Dark Mode',
                subtitle: 'Enable dark theme for the application',
                icon: Icons.dark_mode_outlined,
                value: settings.themeMode == ThemeMode.dark,
                onChanged: (value) => settings.toggleTheme(value),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Protection', context),
              _buildSwitchTile(
                context: context,
                title: 'Background Protection',
                subtitle: 'Stay protected even if app is closed',
                icon: Icons.security_outlined,
                value: _backgroundServiceEnabled,
                onChanged: (value) async {
                  if (value) {
                    // Request notification permission before starting service
                    final status = await Permission.notification.request();
                    if (status.isGranted) {
                      await BackgroundServiceHelper.startService();
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification permission is required for background protection'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                  } else {
                    await BackgroundServiceHelper.stopService();
                  }
                  setState(() {
                    _backgroundServiceEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('General', context),
              /*
              _buildSwitchTile(
                context: context,
                title: 'Notifications',
                subtitle: 'Enable push notifications',
                icon: Icons.notifications_outlined,
                value: settings.notificationsEnabled,
                onChanged: (value) => settings.setNotifications(value),
              ),
              const SizedBox(height: 12),
              */
              _buildListTile(
                context: context,
                title: 'Language',
                subtitle: settings.language,
                icon: Icons.language,
                onTap: () => _showLanguageDialog(context, settings),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Data & Privacy', context),
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
              _buildSectionHeader('Account', context),
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

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF041E34).withOpacity(0.6)
              : Colors.blue.withOpacity(0.6),
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
            gradient: Theme.of(context).brightness == Brightness.light
                ? AppColors.premiumGradient
                : AppColors.darkPremiumGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF041E34)
                        : Colors.blue)
                    .withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        activeColor: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF041E34)
            : Colors.blue,
        activeTrackColor: (Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF041E34)
                : Colors.blue)
            .withOpacity(0.3),
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
            gradient: isDestructive
                ? null
                : (Theme.of(context).brightness == Brightness.light
                    ? AppColors.premiumGradient
                    : AppColors.darkPremiumGradient),
            color: isDestructive ? AppColors.error.withOpacity(0.1) : null,
            shape: BoxShape.circle,
            boxShadow: isDestructive
                ? null
                : [
                    BoxShadow(
                      color: (Theme.of(context).brightness == Brightness.light
                              ? const Color(0xFF041E34)
                              : Colors.blue)
                          .withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : Colors.white,
            size: 20,
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
