import 'dart:async';
import 'dart:math' as math;

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

class _AppSettingsScreenState extends State<AppSettingsScreen>
    with SingleTickerProviderStateMixin {
  bool _backgroundServiceEnabled = false;
  final GlobalKey _bgProtectionCardKey = GlobalKey(debugLabel: 'bgProtectionCard');
  bool _highlightBgProtectionToggle = false;

  late final AnimationController _bgTogglePulseController;
  late final Animation<double> _bgTogglePulse;

  @override
  void initState() {
    super.initState();
    _bgTogglePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _bgTogglePulse = CurvedAnimation(
      parent: _bgTogglePulseController,
      curve: Curves.easeInOut,
    );
    _loadBackgroundServiceState();
  }

  @override
  void dispose() {
    _bgTogglePulseController.dispose();
    super.dispose();
  }

  static const _kBgProtectionKey = BackgroundServiceHelper.backgroundServiceEnabledKey;
  /// Shown once the first time the user opens App Settings (fresh install / new device).
  static const _kBgProtectionIntroSeen = 'seen_background_protection_intro_v1';

  Future<void> _loadBackgroundServiceState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_kBgProtectionKey) ?? false;
    setState(() {
      _backgroundServiceEnabled = saved;
    });
    if (saved) {
      await BackgroundServiceHelper.startService();
    } else {
      // Keep admin notifications polling running even when protection is OFF.
      await BackgroundServiceHelper.startAdminNotificationsPolling();
    }

    final seenIntro = prefs.getBool(_kBgProtectionIntroSeen) ?? false;
    if (!seenIntro && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_showBackgroundProtectionIntroOnce());
        }
      });
    }
  }

  Future<void> _showBackgroundProtectionIntroOnce() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kBgProtectionIntroSeen) == true || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) => _BackgroundProtectionIntroDialog(
        onGotIt: () => Navigator.of(ctx).pop(),
      ),
    );

    if (!mounted) return;
    await prefs.setBool(_kBgProtectionIntroSeen, true);

    setState(() => _highlightBgProtectionToggle = true);
    _bgTogglePulseController.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _bgProtectionCardKey.currentContext;
      if (target != null && mounted) {
        Scrollable.ensureVisible(
          target,
          alignment: 0.25,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
        );
      }
    });
    await Future<void>.delayed(const Duration(milliseconds: 2800));
    if (mounted) {
      _bgTogglePulseController.stop();
      _bgTogglePulseController.reset();
      setState(() => _highlightBgProtectionToggle = false);
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
                  KeyedSubtree(
                    key: _bgProtectionCardKey,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _highlightBgProtectionToggle
                              ? colorScheme.primary
                              : Colors.transparent,
                          width: _highlightBgProtectionToggle ? 2.5 : 0,
                        ),
                        boxShadow: _highlightBgProtectionToggle
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.28),
                                  blurRadius: 18,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : const [],
                      ),
                      child: _CardGroup(
                        children: [
                          _ToggleRow(
                            icon: Icons.security_outlined,
                            title: 'Background\nProtection',
                            subtitle: 'Real-time health\nmonitoring',
                            value: _backgroundServiceEnabled,
                            switchPulseAnimation: _highlightBgProtectionToggle
                                ? _bgTogglePulse
                                : null,
                            onChanged: (value) async {
                              if (value) {
                                // Notification already requested on first install via permissions gate.
                                // Directly start service.
                                final notifStatus = await Permission.notification.status;
                                if (notifStatus.isDenied || notifStatus.isPermanentlyDenied) {
                                  await Permission.notification.request();
                                }
                                await BackgroundServiceHelper.startService();
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setBool(_kBgProtectionKey, true);
                                setState(() {
                                  _backgroundServiceEnabled = value;
                                });
                                await _showProtectionEnabledNotification();
                                // Battery optimization already requested on first install.
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
                                await BackgroundServiceHelper
                                    .disableBackgroundProtectionKeepAdminPolling();
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setBool(_kBgProtectionKey, false);
                                setState(() {
                                  _backgroundServiceEnabled = value;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Background protection deactivated',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader('GENERAL'),
                  const SizedBox(height: 10),
                  _CardGroup(
                    children: [
                      _NavRow(
                        icon: Icons.language,
                        title: 'Language',
                        trailingText: 'English',
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

}

class _BackgroundProtectionIntroDialog extends StatefulWidget {
  final VoidCallback onGotIt;

  const _BackgroundProtectionIntroDialog({required this.onGotIt});

  @override
  State<_BackgroundProtectionIntroDialog> createState() =>
      _BackgroundProtectionIntroDialogState();
}

class _BackgroundProtectionIntroDialogState
    extends State<_BackgroundProtectionIntroDialog> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * 0.82;
    final maxW = math.min(440.0, mq.size.width - 40);

    final dialogFill = cs.surface;
    final headerFill =
        Color.alphaBlend(cs.primary.withOpacity(isDark ? 0.14 : 0.08), dialogFill);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Material(
          color: dialogFill,
          elevation: isDark ? 16 : 10,
          shadowColor: Colors.black.withOpacity(isDark ? 0.55 : 0.18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: cs.outlineVariant.withOpacity(isDark ? 0.4 : 0.45),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                color: headerFill,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(isDark ? 0.22 : 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shield_outlined, size: 32, color: cs.primary),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Background protection',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  thickness: 5,
                  radius: const Radius.circular(8),
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(22, 18, 14, 12),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    children: [
                      Text(
                        'This option helps keep fall detection and SOS working when you are not '
                        'actively using the Care4Elder app.',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _BgProtectionIntroBullet(
                        icon: Icons.phone_android_rounded,
                        iconColor: cs.primary,
                        text:
                            'When it is turned on, monitoring can continue if you close the app or leave it in the background (for example in your recent apps list).',
                      ),
                      const SizedBox(height: 14),
                      _BgProtectionIntroBullet(
                        icon: Icons.notifications_active_outlined,
                        iconColor: cs.primary,
                        text:
                            'You may see a small status notification while protection is active. That is normal and means the service is running safely.',
                      ),
                      const SizedBox(height: 14),
                      _BgProtectionIntroBullet(
                        icon: Icons.health_and_safety_outlined,
                        iconColor: cs.primary,
                        text:
                            'If a fall is detected, SOS and alerts can work more reliably so your emergency contacts can be notified.',
                      ),
                      const SizedBox(height: 14),
                      _BgProtectionIntroBullet(
                        icon: Icons.toggle_on_outlined,
                        iconColor: cs.primary,
                        text:
                            'Use the switch below to turn it on or off. The first time you turn it on, your phone may ask for notification permission so we can show important alerts.',
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withOpacity(isDark ? 0.35 : 0.4),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: FilledButton(
                  onPressed: widget.onGotIt,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Got it',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
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

class _BgProtectionIntroBullet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _BgProtectionIntroBullet({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(isDark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: GoogleFonts.roboto(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: isDark ? cs.onSurface.withOpacity(0.92) : cs.onSurface.withOpacity(0.87),
              ),
            ),
          ),
        ),
      ],
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/patient/profile'),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, color: colorScheme.onSurface, size: 18)
                    : null,
              ),
            ),
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
  /// When set (e.g. after “Got it” on background-protection intro), the switch gently pulses.
  final Animation<double>? switchPulseAnimation;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.switchPulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFEAF0FC);

    final toggle = Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: colorScheme.primary,
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: colorScheme.onSurface.withOpacity(0.15),
    );

    final Widget trailing = switchPulseAnimation != null
        ? AnimatedBuilder(
            animation: switchPulseAnimation!,
            builder: (context, child) {
              final v = switchPulseAnimation!.value;
              final wave = math.sin(v * math.pi);
              final scale = 1.0 + 0.11 * wave;
              final glow = isDark ? 0.38 : 0.42;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colorScheme.primary
                        .withOpacity(0.2 + 0.65 * wave),
                    width: 1.2 + 1.8 * wave,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(glow * wave),
                      blurRadius: 14 * wave,
                      spreadRadius: 0.5 * wave,
                    ),
                  ],
                ),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.center,
                  child: child,
                ),
              );
            },
            child: toggle,
          )
        : toggle;

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
          trailing,
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFEAF0FC);
    final interactive = onTap != null;
    final child = Padding(
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
          if (interactive)
            Icon(Icons.chevron_right,
                color: colorScheme.onSurface.withOpacity(0.25)),
        ],
      ),
    );
    if (!interactive) {
      return child;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: child,
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
