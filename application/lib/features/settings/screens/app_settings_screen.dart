import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/settings_service.dart';
import '../../../core/services/background_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/patient_side_menu.dart';
import '../../../core/services/profile_service.dart';
import 'privacy_policy_screen.dart';

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

  static const _kBgProtectionKey = BackgroundServiceHelper.backgroundServiceEnabledKey;

  Future<void> _loadBackgroundServiceState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kBgProtectionKey) ?? false;
    setState(() {
      _backgroundServiceEnabled = saved;
    });
    if (saved) {
      await BackgroundServiceHelper.startService();
    } else {
      await BackgroundServiceHelper.stopService();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = context.watch<ProfileService>().currentUser;
    final avatarUrl = profile?.profilePictureUrl.trim().isNotEmpty == true
        ? profile!.profilePictureUrl
        : null;
    final name =
        profile?.fullName.trim().isNotEmpty == true ? profile!.fullName : 'Member';
    final handle =
        profile?.email.trim().isNotEmpty == true ? profile!.email : '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF6F8FB),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: SettingsService(),
          builder: (context, child) {
            final settings = SettingsService();
            if (settings.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopHeaderBar(
                    title: 'App Settings',
                    avatarUrl: avatarUrl,
                    onLeadingTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        openPatientSideMenu(context);
                      }
                    },
                    showBackIfPossible: Navigator.of(context).canPop(),
                  ),
                  const SizedBox(height: 14),
                  _UserCard(
                    name: name,
                    subtitleLine1: 'Premium Member •',
                    subtitleLine2: handle,
                    avatarUrl: avatarUrl,
                    onEditTap: () => context.push('/patient/profile/personal-info'),
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader('APPEARANCE'),
                  const SizedBox(height: 10),
                  _CardGroup(
                    children: [
                      _ToggleRow(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        value: settings.themeMode == ThemeMode.dark,
                        onChanged: (value) => settings.toggleTheme(value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader('PROTECTION'),
                  const SizedBox(height: 10),
                  _CardGroup(
                    children: [
                      _ToggleRow(
                        icon: Icons.security_outlined,
                        title: 'Background\nProtection',
                        subtitle: 'Real-time health\nmonitoring',
                        value: _backgroundServiceEnabled,
                        onChanged: (value) async {
                          if (value) {
                            final status = await Permission.notification.request();
                            if (status.isGranted) {
                              await BackgroundServiceHelper.startService();
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool(_kBgProtectionKey, true);
                              setState(() {
                                _backgroundServiceEnabled = value;
                              });

                              await _showProtectionEnabledNotification();
                              await _requestBatteryOptimizationExemption();

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Background protection activated!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Notification permission is required for background protection',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              return;
                            }
                          } else {
                            await BackgroundServiceHelper.stopService();
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(_kBgProtectionKey, false);
                            setState(() {
                              _backgroundServiceEnabled = value;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Background protection deactivated'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader('GENERAL'),
                  const SizedBox(height: 10),
                  _CardGroup(
                    children: [
                      _NavRow(
                        icon: Icons.language,
                        title: 'Language',
                        trailingText: settings.language,
                        onTap: () => _showLanguageDialog(context, settings),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader('DATA & PRIVACY'),
                  const SizedBox(height: 10),
                  _CardGroup(
                    children: [
                      _NavRow(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader('ACCOUNT'),
                  const SizedBox(height: 10),
                  _CardGroup(
                    children: [
                      _LogoutRow(
                        onTap: () => _handleLogout(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'VERSION 2.4.1 (CARE4ELDER BUILD)',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.35),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showProtectionEnabledNotification() async {
    final plugin = FlutterLocalNotificationsPlugin();
    const channelId = 'protection_status_channel';

    // Create channel
    const channel = AndroidNotificationChannel(
      channelId,
      'Protection Status',
      description: 'Shows when background protection is active',
      importance: Importance.high,
    );
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await plugin.show(
      777,
      'Background Protection Active',
      'Care4Elder is monitoring for falls in the background.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Protection Status',
          channelDescription: 'Shows when background protection is active',
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  Future<void> _requestBatteryOptimizationExemption() async {
    // Check if already exempted
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return;

    if (!mounted) return;

    // Show explanation dialog first
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Important: Battery Setting'),
        content: const Text(
          'For fall detection to work reliably (especially on Samsung phones), '
          'please allow Care4Elder to run without battery restrictions.\n\n'
          'On the next screen, tap "Allow" to keep background protection always active.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (shouldRequest == true) {
      await Permission.ignoreBatteryOptimizations.request();
    }
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
}

class _TopHeaderBar extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final VoidCallback onLeadingTap;
  final bool showBackIfPossible;

  const _TopHeaderBar({
    required this.title,
    required this.avatarUrl,
    required this.onLeadingTap,
    required this.showBackIfPossible,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = Theme.of(context).brightness == Brightness.dark
        ? colorScheme.primary
        : const Color(0xFF1565C0);
    final leadingIcon = showBackIfPossible ? Icons.arrow_back_ios_new : Icons.menu;
    return Row(
      children: [
        InkWell(
          onTap: onLeadingTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(leadingIcon, color: colorScheme.onSurface, size: 22),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Icon(Icons.person, color: colorScheme.onSurface, size: 18)
                : null,
          ),
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String subtitleLine1;
  final String subtitleLine2;
  final String? avatarUrl;
  final VoidCallback onEditTap;

  const _UserCard({
    required this.name,
    required this.subtitleLine1,
    required this.subtitleLine2,
    required this.avatarUrl,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameColor =
        isDark ? colorScheme.onSurface : const Color(0xFF0F4AA8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
              image: avatarUrl != null
                  ? DecorationImage(image: NetworkImage(avatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: avatarUrl == null
                ? Icon(Icons.person, size: 38, color: colorScheme.onSurface.withOpacity(0.35))
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: nameColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitleLine1,
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          if (subtitleLine2.isNotEmpty)
            Text(
              subtitleLine2,
              style: GoogleFonts.roboto(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: onEditTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                elevation: 0,
              ),
              child: Text(
                'Edit Profile',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: colorScheme.onSurface.withOpacity(0.45),
        ),
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  final List<Widget> children;
  const _CardGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outline.withOpacity(0.08),
              ),
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFEAF0FC);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      height: 1.15,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: colorScheme.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: colorScheme.onSurface.withOpacity(0.15),
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFEAF0FC);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.25)),
          ],
        ),
      ),
    );
  }
}

class _LogoutRow extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Icon(Icons.logout, size: 20, color: Color(0xFFD32F2F)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Logout',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFD32F2F),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.25)),
          ],
        ),
      ),
    );
  }
}
