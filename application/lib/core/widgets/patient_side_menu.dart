import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../services/profile_service.dart';
import '../../features/auth/services/auth_service.dart';

/// Opens a phone-style drawer: full height, flush to the start edge, scrim fades in sync.
Future<void> openPatientSideMenu(BuildContext context) {
  final anchorContext = context;
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final mediaQuery = MediaQuery.of(dialogContext);
      final drawerWidth =
          (mediaQuery.size.width * 0.88).clamp(288.0, 360.0).toDouble();
      final drawerMotion = CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
      );

      return Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: drawerMotion,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(dialogContext).pop(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.40),
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(drawerMotion),
              child: SizedBox(
                width: drawerWidth,
                height: mediaQuery.size.height,
                child: _PatientSideMenuPanel(
                  anchorContext: anchorContext,
                  onClose: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _PatientSideMenuPanel extends StatelessWidget {
  final BuildContext anchorContext;
  final VoidCallback onClose;

  const _PatientSideMenuPanel({
    required this.anchorContext,
    required this.onClose,
  });

  void _go(BuildContext dialogContext, String location) {
    Navigator.of(dialogContext).pop();
    GoRouter.of(anchorContext).go(location);
  }

  Future<void> _logout(BuildContext dialogContext) async {
    Navigator.of(dialogContext).pop();
    final confirmed = await showDialog<bool>(
      context: anchorContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && anchorContext.mounted) {
      await AuthService().signOut();
      if (anchorContext.mounted) {
        GoRouter.of(anchorContext).go('/selection');
      }
    }
  }

  void _helpSupport(BuildContext dialogContext) {
    Navigator.of(dialogContext).pop();
    GoRouter.of(anchorContext).push('/patient/help-support');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = context.watch<ProfileService>().currentUser;
    final avatarUrl = profile?.profilePictureUrl.trim().isNotEmpty == true
        ? profile!.profilePictureUrl
        : null;
    final displayName =
        profile?.fullName.trim().isNotEmpty == true ? profile!.fullName : 'Member';

    final cardBg = isDark ? colorScheme.surfaceContainerHighest : Colors.white;
    final sectionLabelStyle = GoogleFonts.roboto(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.4,
      color: colorScheme.onSurface.withValues(alpha: 0.45),
    );

    final drawerShape = const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.only(
        topEnd: Radius.circular(20),
        bottomEnd: Radius.circular(20),
      ),
    );

    return Material(
      color: cardBg,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.5 : 0.35),
      shape: drawerShape,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: true,
        bottom: true,
        left: false,
        right: false,
        minimum: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 10, 14),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 36),
                    child: _ProfileHeader(
                      displayName: displayName,
                      avatarUrl: avatarUrl,
                      isDark: isDark,
                      colorScheme: colorScheme,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: onClose,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                      icon: Icon(
                        Icons.close,
                        size: 22,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Text('SERVICES', style: sectionLabelStyle),
                        const SizedBox(height: 10),
                        _ServiceRow(
                          icon: Icons.videocam_outlined,
                          label: 'Consult Doctor',
                          onTap: () => _go(context, '/patient/consultation'),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _ServiceRow(
                          icon: Icons.folder_open_outlined,
                          label: 'Medical Vault',
                          onTap: () => _go(context, '/patient/records'),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _ServiceRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Wallet',
                          onTap: () =>
                              _go(context, '/patient/profile/wallet'),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 8),
                        _ServiceRow(
                          icon: Icons.settings_outlined,
                          label: 'App Settings',
                          onTap: () =>
                              _go(context, '/patient/profile/settings'),
                          colorScheme: colorScheme,
                        ),
                        const SizedBox(height: 20),
                        Text('SAFETY', style: sectionLabelStyle),
                        const SizedBox(height: 10),
                        Material(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => _go(
                              context,
                              '/patient/contacts?from=${Uri.encodeComponent('/patient/profile')}',
                            ),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFC62828),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.medical_services_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Emergency Contacts',
                                      style: GoogleFonts.roboto(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFB71C1C),
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: const Color(0xFFB71C1C)
                                        .withValues(alpha: 0.85),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        InkWell(
                          onTap: () => _helpSupport(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorScheme.outline
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.help_outline,
                                    size: 20,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Help & Support',
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _logout(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  size: 22,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Logout',
                                  style: GoogleFonts.roboto(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final bool isDark;
  final ColorScheme colorScheme;

  const _ProfileHeader({
    required this.displayName,
    required this.avatarUrl,
    required this.isDark,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final nameColor = isDark ? colorScheme.primary : const Color(0xFF1565C0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 64,
                height: 64,
                color: const Color(0xFF0D1117),
                alignment: Alignment.center,
                child: avatarUrl != null
                    ? Image.network(
                        avatarUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _DrawerLogoPlaceholder(colorScheme: colorScheme),
                      )
                    : _DrawerLogoPlaceholder(colorScheme: colorScheme),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  shape: BoxShape.circle,
                  border: Border.all(color: _badgeBorderColor()),
                ),
                child: const Icon(
                  Icons.verified,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: nameColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.primary.withValues(alpha: 0.2)
                : const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'PREMIUM MEMBER',
            style: GoogleFonts.roboto(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: nameColor,
            ),
          ),
        ),
      ],
    );
  }

  Color _badgeBorderColor() {
    return isDark ? colorScheme.surfaceContainerHighest : Colors.white;
  }
}

/// App logo in the profile square when no photo (matches design reference).
class _DrawerLogoPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DrawerLogoPlaceholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.person,
          size: 32,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ServiceRow({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final circleBg = colorScheme.primary.withValues(alpha: 0.12);
    final iconColor =
        Theme.of(context).brightness == Brightness.dark
            ? colorScheme.primary
            : const Color(0xFF1565C0);

    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.28),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
