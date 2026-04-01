import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Brand colors for Help & Support (matches marketing mockups).
abstract final class _HelpSupportPalette {
  static const navy = Color(0xFF002D62);
  /// Hero title / button — reference blue (~#003399).
  static const heroTitleBlue = Color(0xFF003399);
  static const primaryBlue = Color(0xFF0056D2);
  static const lightBlueAccent = Color(0xFFEBF2FF);
  static const bodyGrey = Color(0xFF5C6570);
  /// Faint line-art headset (slate, not primary blue).
  static const heroHeadsetLine = Color(0xFF94A3B8);
}

/// Patient Help & Support — Care4Elder contact, FAQ, and care messaging.
class PatientHelpSupportScreen extends StatelessWidget {
  const PatientHelpSupportScreen({super.key});

  static const _email = 'connect.us@care4elder.com';
  static const _phone = '0341-3543415';
  static const _whatsappLiveChat = 'https://wa.me/919093335679';

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      query: 'subject=${Uri.encodeComponent('Care4Elder Support')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email: $_email')),
      );
    }
  }

  Future<void> _openPhone(BuildContext context) async {
    final digits = _phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Phone: $_phone')),
      );
    }
  }

  Future<void> _liveChat(BuildContext context) async {
    final uri = Uri.parse(_whatsappLiveChat);
    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp. Try again or use email below.'),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open: $_whatsappLiveChat')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg =
        isDark ? colorScheme.surface : const Color(0xFFF7F9FC);
    final titleBlue =
        isDark ? colorScheme.primary : _HelpSupportPalette.navy;
    final iconTileBg = isDark
        ? colorScheme.primary.withValues(alpha: 0.12)
        : _HelpSupportPalette.lightBlueAccent;
    final cardBg = isDark ? colorScheme.surfaceContainerHighest : Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark
                          ? colorScheme.onSurface
                          : _HelpSupportPalette.navy,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Help & Support',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: titleBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCard(
                      cardBg: cardBg,
                      isDark: isDark,
                      colorScheme: colorScheme,
                      onLiveChat: () => _liveChat(context),
                    ),
                    SizedBox(height: isDark ? 18 : 16),
                    _WeCareBanner(isDark: isDark),
                    const SizedBox(height: 24),
                    Text(
                      'Reach Out to Us',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _ContactTile(
                      cardBg: cardBg,
                      iconBg: iconTileBg,
                      icon: Icons.email_outlined,
                      label: 'Email Address',
                      value: _email,
                      colorScheme: colorScheme,
                      titleBlue: titleBlue,
                      onTap: () => _openEmail(context),
                    ),
                    const SizedBox(height: 12),
                    _ContactTile(
                      cardBg: cardBg,
                      iconBg: iconTileBg,
                      icon: Icons.phone_outlined,
                      label: 'Phone Line',
                      value: _phone,
                      colorScheme: colorScheme,
                      titleBlue: titleBlue,
                      onTap: () => _openPhone(context),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Common Topics',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quick answers to your frequently asked questions.',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TopicCard(
                      cardBg: cardBg,
                      iconBg: iconTileBg,
                      icon: Icons.smartphone_outlined,
                      title: 'App Usage',
                      colorScheme: colorScheme,
                      titleBlue: titleBlue,
                      bullets: const [
                        'Setting up your medication alerts',
                        'Connecting your heart rate monitor',
                        'How to add a family caretaker',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TopicCard(
                      cardBg: cardBg,
                      iconBg: iconTileBg,
                      icon: Icons.medical_services_outlined,
                      title: 'Consultations',
                      colorScheme: colorScheme,
                      titleBlue: titleBlue,
                      bullets: const [
                        'Booking a virtual doctor visit',
                        'Accessing your lab results',
                        'Prescription refill requests',
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TopicCard(
                      cardBg: cardBg,
                      iconBg: iconTileBg,
                      icon: Icons.receipt_long_outlined,
                      title: 'Billing & Plans',
                      colorScheme: colorScheme,
                      titleBlue: titleBlue,
                      bullets: const [
                        'Understanding your monthly plan',
                        'Updating payment methods',
                        'Insurance coverage FAQ',
                      ],
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

class _HeroCard extends StatelessWidget {
  final Color cardBg;
  final bool isDark;
  final ColorScheme colorScheme;
  final VoidCallback onLiveChat;

  const _HeroCard({
    required this.cardBg,
    required this.isDark,
    required this.colorScheme,
    required this.onLiveChat,
  });

  @override
  Widget build(BuildContext context) {
    final radius = 18.0;
    if (isDark) {
      return _HeroCardDark(
        cardBg: cardBg,
        colorScheme: colorScheme,
        radius: radius,
        onLiveChat: onLiveChat,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.96, 0.96),
                    radius: 0.92,
                    colors: [
                      _HelpSupportPalette.lightBlueAccent.withValues(alpha: 0.72),
                      _HelpSupportPalette.lightBlueAccent.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.38, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              top: 8,
              child: Icon(
                Icons.support_agent_outlined,
                size: 132,
                color: _HelpSupportPalette.heroHeadsetLine.withValues(alpha: 0.42),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _HelpSupportPalette.lightBlueAccent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      'DEDICATED CARE',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.05,
                        color: _HelpSupportPalette.heroTitleBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Care4Elder Support Team',
                    style: GoogleFonts.roboto(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: _HelpSupportPalette.heroTitleBlue,
                      height: 1.22,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Our compassionate specialists are here to ensure your '
                    'wellness journey is smooth and worry-free.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                      color: _HelpSupportPalette.bodyGrey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _HelpSupportPalette.heroTitleBlue
                              .withValues(alpha: 0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      onPressed: onLiveChat,
                      style: FilledButton.styleFrom(
                        backgroundColor: _HelpSupportPalette.heroTitleBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 22,
                        ),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.chat_rounded, size: 22),
                      label: Text(
                        'Live Chat',
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCardDark extends StatelessWidget {
  final Color cardBg;
  final ColorScheme colorScheme;
  final double radius;
  final VoidCallback onLiveChat;

  const _HeroCardDark({
    required this.cardBg,
    required this.colorScheme,
    required this.radius,
    required this.onLiveChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'DEDICATED CARE',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Care4Elder Support Team',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Our compassionate specialists are here to ensure your '
                'wellness journey is smooth and worry-free.',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onLiveChat,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: Text(
                    'Live Chat',
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

class _WeCareBanner extends StatelessWidget {
  final bool isDark;

  const _WeCareBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = 20.0;

    if (isDark) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.onPrimary.withValues(alpha: 0.2),
              ),
              child: Icon(
                Icons.volunteer_activism_outlined,
                color: scheme.onPrimary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We Care for You',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: scheme.onPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Available 24/7 for medical emergencies.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: scheme.onPrimary.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: _HelpSupportPalette.primaryBlue.withValues(alpha: 0.32),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0B6CF0),
                      _HelpSupportPalette.primaryBlue,
                      const Color(0xFF003D99),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _CareCardSmokePainter(),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Transform.rotate(
                    angle: -0.04,
                    child: Text(
                      'CARE',
                      style: GoogleFonts.roboto(
                        fontSize: 112,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.09),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2B7FFF),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_outlined,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'We Care for You',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Available 24/7 for medical emergencies.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft dark-blue “smoke” depth on the care card (no external assets).
class _CareCardSmokePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = const Color(0xFF001A40).withValues(alpha: 0.11);
    final soft = Paint()..style = PaintingStyle.fill;

    void blob(double cx, double cy, double r, double a) {
      soft.color = base.withValues(alpha: a);
      canvas.drawCircle(Offset(cx * size.width, cy * size.height), r, soft);
    }

    blob(0.15, 0.85, size.width * 0.42, 0.06);
    blob(0.88, 0.12, size.width * 0.38, 0.055);
    blob(0.55, 0.45, size.width * 0.55, 0.04);
    blob(0.05, 0.35, size.width * 0.3, 0.05);
    blob(0.92, 0.72, size.width * 0.35, 0.045);

    final wave = Path()
      ..moveTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.42,
        size.width * 0.55,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.82,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    soft.color = const Color(0xFF001030).withValues(alpha: 0.07);
    canvas.drawPath(wave, soft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ContactTile extends StatelessWidget {
  final Color cardBg;
  final Color iconBg;
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final Color titleBlue;
  final VoidCallback onTap;

  const _ContactTile({
    required this.cardBg,
    required this.iconBg,
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.titleBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: titleBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: titleBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withValues(alpha: 0.28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Color cardBg;
  final Color iconBg;
  final IconData icon;
  final String title;
  final ColorScheme colorScheme;
  final Color titleBlue;
  final List<String> bullets;

  const _TopicCard({
    required this.cardBg,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.colorScheme,
    required this.titleBlue,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: titleBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
