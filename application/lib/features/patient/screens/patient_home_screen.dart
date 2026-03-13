import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/health_tip_service.dart';
import '../../../core/services/hero_service.dart';
import '../../../core/services/profile_service.dart';
import '../widgets/service_card.dart';
import '../widgets/health_tip_card.dart';
import '../widgets/show_health_tip_detail.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  late Future<List<HealthTip>> _healthTipsFuture;
  List<HeroSection> _heroSections = [];
  bool _isLoadingHeroes = true;
  final PageController _heroController = PageController();
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _healthTipsFuture = HealthTipService.fetchHealthTips();
    _loadHeroSections();
  }

  Future<void> _loadHeroSections() async {
    try {
      final heroes = await HeroService.fetchHeroSections('patient');
      if (!mounted) return;
      heroes.sort((a, b) => a.order.compareTo(b.order));
      setState(() {
        _heroSections = heroes;
        _isLoadingHeroes = false;
      });
      if (_heroSections.isNotEmpty) {
        _startHeroTimer();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingHeroes = false;
      });
    }
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_heroController.hasClients || _heroSections.isEmpty) return;
      final nextIndex =
          (_heroController.page?.round() ?? 0) + 1 >= _heroSections.length
              ? 0
              : (_heroController.page?.round() ?? 0) + 1;
      _heroController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = context.watch<ProfileService>().currentUser;
    final displayName = profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Care4Elder Member';
    final surfaceColor = isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: CustomScrollView(
        slivers: [
          // Full screen hero section with overlapping card
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Full screen hero section
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.38,
                  child: _isLoadingHeroes
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : PageView.builder(
                          controller: _heroController,
                          itemCount: _heroSections.isNotEmpty ? _heroSections.length : 1,
                          itemBuilder: (context, index) {
                            final hero = _heroSections.isNotEmpty ? _heroSections[index] : null;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: isDark ? AppColors.darkPremiumGradient : AppColors.premiumGradient,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                image: hero?.imageUrl.isNotEmpty == true
                                    ? DecorationImage(
                                        image: NetworkImage(hero!.imageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  // Gradient overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.3),
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.5),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),
                                  // Hero content (centered)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            hero?.title.isNotEmpty == true ? hero!.title : 'Care4Elder',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.roboto(
                                              fontSize: 40,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            hero?.subtitle.isNotEmpty == true ? hero!.subtitle : 'Stay healthy, stay safe',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              color: Colors.white.withOpacity(0.95),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                // Transparent header INSIDE hero section
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => context.go('/patient/profile'),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  backgroundImage: profile?.profilePictureUrl.isNotEmpty == true
                                      ? NetworkImage(profile!.profilePictureUrl)
                                      : null,
                                  child: profile?.profilePictureUrl.isEmpty ?? true
                                      ? const Icon(Icons.person, color: Colors.white, size: 24)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      profile?.email ?? '',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () => context.push('/patient/notifications'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Consult Doctor Card - 95% overlapped with hero
                Positioned(
                  bottom: -180,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(24),
                    shadowColor: Colors.black.withOpacity(0.1),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBackground : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primaryBlue.withOpacity(isDark ? 0.25 : 0.15),
                                      AppColors.primaryBlue.withOpacity(isDark ? 0.15 : 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.medical_services_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 32,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'FEATURED',
                                  style: GoogleFonts.roboto(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Consult a Doctor',
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Get instant medical advice from certified doctors via video or audio call.',
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              color: isDark ? Colors.white70 : AppColors.textGrey,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Book Appointment Button - below the card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 200, 16, 0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.error,
                            AppColors.error.withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            print('Book Appointment pressed - navigating to consultation');
                            context.go('/patient/consultation');
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.white),
                                const SizedBox(width: 10),
                                Text(
                                  'Book Appointment',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Main content
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildSectionHeader(context, 'Services', () {}),
                _buildServicesGrid(context),
                _buildSectionHeader(context, 'Health Tips', () {}),
                _buildHealthTipsList(),
                const SizedBox(height: 40),
                // Footer Tagline
                Container(
                  width: double.infinity,
                  height: 220,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        Theme.of(context).brightness == Brightness.dark
                          ? 'assets/images/footer app c4e.png'
                          : 'assets/images/footer_black_on_white.png',
                      ),
                      fit: BoxFit.cover,
                      opacity: 0.12,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '#Care4Elder',
                        style: GoogleFonts.roboto(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark.withOpacity(0.15),
                          letterSpacing: 1,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            'Made for India',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Smart Care with Human Touch',
                        style: GoogleFonts.roboto(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textGrey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onViewAll) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: const [
        ServiceCard(
          title: 'Health Records',
          subtitle: 'Lab reports & history',
          icon: Icons.receipt_long_outlined,
          iconColor: AppColors.primaryBlue,
          route: '/patient/profile/medical-info',
        ),
        ServiceCard(
          title: 'Emergency',
          subtitle: '24/7 Rapid support',
          icon: Icons.sos_outlined,
          iconColor: AppColors.error,
          route: '/patient/sos',
        ),
        ServiceCard(
          title: 'Manage Records',
          subtitle: 'Medical records',
          icon: Icons.folder_open,
          iconColor: Colors.orange,
          route: '/patient/records',
        ),
        ServiceCard(
          title: 'Medicines',
          subtitle: 'Manage prescriptions',
          icon: Icons.medication_outlined,
          iconColor: Colors.green,
          route: '/patient/records?open=prescriptions',
        ),
      ],
    );
  }

  Widget _buildHealthTipsList() {
    return FutureBuilder<List<HealthTip>>(
      future: _healthTipsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No health tips available.'));
        }

        final healthTips = snapshot.data!;
        final colors = [AppColors.primaryBlue, Colors.green, Colors.purple, Colors.orange, Colors.teal];

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: healthTips.length,
            itemBuilder: (context, index) {
              final tip = healthTips[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: GestureDetector(
                  onTap: () => showHealthTipDetail(context, tip),
                  child: HealthTipCard(
                    title: tip.title,
                    subtitle: 'View Details',
                    icon: Icons.lightbulb_outline_rounded,
                    color: colors[index % colors.length],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
