import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/patient_side_menu.dart';
import '../../../core/services/profile_service.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = context.watch<ProfileService>().currentUser;
    final profileImageUrl = profile?.profilePictureUrl.trim().isNotEmpty == true
        ? profile!.profilePictureUrl
        : null;
    final displayName =
        profile?.fullName.trim().isNotEmpty == true ? profile!.fullName : 'Member';
    final walletBalance = profile?.walletBalance ?? 0.0;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF6F8FB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopHeaderBar(
                title: 'Profile',
                onMenuTap: () => openPatientSideMenu(context),
                avatarUrl: profileImageUrl,
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    _ProfileAvatar(
                      imageUrl: profileImageUrl,
                      onEditTap: () => context.push('/patient/profile/personal-info'),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: GoogleFonts.roboto(
                        fontSize: 26,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PillBadge(
                      icon: Icons.verified,
                      text: 'Premium Member',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _SectionLabel('ACCOUNT & HEALTH'),
              const SizedBox(height: 10),
              _CardGroup(
                children: [
                  _MenuRow(
                    icon: Icons.settings_outlined,
                    title: 'Profile Settings',
                    onTap: () => context.push('/patient/profile/personal-info'),
                  ),
                  _MenuRow(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'My Wallet',
                    trailingText: '₹${walletBalance.toStringAsFixed(2)}',
                    onTap: () => context.push('/patient/profile/wallet'),
                  ),
                  _MenuRow(
                    icon: Icons.medical_services_outlined,
                    title: 'Patient Medical\nInformation',
                    onTap: () => context.push('/patient/profile/medical-info'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel('SUPPORT & SAFETY'),
              const SizedBox(height: 10),
              _CardGroup(
                children: [
                  _MenuRow(
                    icon: Icons.people_outline,
                    title: 'Emergency Contacts',
                    onTap: () => context.push(
                      '/patient/contacts?from=${Uri.encodeComponent('/patient/profile')}',
                    ),
                  ),
                  _MenuRow(
                    icon: Icons.settings_applications_outlined,
                    title: 'App Settings',
                    onTap: () => context.push('/patient/profile/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _LogoutCard(
                onTap: () => _handleLogout(context),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Care4elder v2.4.0',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeaderBar extends StatelessWidget {
  final String title;
  final VoidCallback onMenuTap;
  final String? avatarUrl;

  const _TopHeaderBar({
    required this.title,
    required this.onMenuTap,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = Theme.of(context).brightness == Brightness.dark
        ? colorScheme.primary
        : const Color(0xFF1565C0);
    return Row(
      children: [
        InkWell(
          onTap: onMenuTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.menu, color: colorScheme.onSurface, size: 22),
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

class _ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onEditTap;

  const _ProfileAvatar({
    required this.imageUrl,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
            image: imageUrl != null
                ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
                : null,
          ),
          child: imageUrl == null
              ? Icon(Icons.person, size: 56, color: colorScheme.onSurface.withOpacity(0.35))
              : null,
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: InkWell(
            onTap: onEditTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PillBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFFEAF0FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w700,
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

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  const _MenuRow({
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
    final primary = Theme.of(context).colorScheme.primary;
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
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
                  color: primary,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Icon(Icons.chevron_right,
                color: colorScheme.onSurface.withOpacity(0.25)),
          ],
        ),
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.errorContainer.withOpacity(0.6)
                    : const Color(0xFFFFEBEE),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? colorScheme.error.withOpacity(0.35)
                      : const Color(0xFFFFCDD2),
                ),
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
          ],
        ),
      ),
    );
  }
}
