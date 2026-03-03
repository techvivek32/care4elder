import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/health_tip_service.dart';
import '../../../core/services/hero_service.dart';
import '../../../core/services/profile_service.dart';
import '../widgets/consult_doctor_card.dart';
import '../widgets/premium_banner.dart';
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
          SliverAppBar(
            backgroundColor: isDark ? AppColors.darkBackground : AppColors.primaryBlue,
            expandedHeight: 220.0,
            floating: false,
            pinned: false,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {},
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.go('/notifications'),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                    ],
                  ),
                  Text(
                    'Premium Member',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              background: PageView.builder(
                controller: _heroController,
                itemCount: _heroSections.isNotEmpty ? _heroSections.length : 1,
                itemBuilder: (context, index) {
                  final hero = _heroSections.isNotEmpty ? _heroSections[index] : null;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: isDark ? AppColors.darkPremiumGradient : AppColors.premiumGradient,
                      image: hero?.imageUrl.isNotEmpty == true
                          ? DecorationImage(
                              image: NetworkImage(hero!.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, top: 100, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLoadingHeroes)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          if (_isLoadingHeroes) const SizedBox(height: 12),
                          Text(
                            hero?.title.isNotEmpty == true ? hero!.title : 'Care4Elder',
                            style: GoogleFonts.roboto(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hero?.subtitle.isNotEmpty == true ? hero!.subtitle : 'Stay healthy, stay safe',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    const ConsultDoctorCard(),
                    const PremiumBanner(),
                    _buildSectionHeader(context, 'Services', () {}),
                    _buildServicesGrid(context),
                    _buildSectionHeader(context, 'Health Tips', () {}),
                    _buildHealthTipsList(),
                  ],
                ),
              ),
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
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'View All',
              style: GoogleFonts.roboto(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
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
          title: 'Vitals Monitor',
          subtitle: 'Check heart & oxygen',
          icon: Icons.monitor_heart_outlined,
          iconColor: Colors.orange,
          route: '/vitals', // Placeholder route
        ),
        ServiceCard(
          title: 'Medicines',
          subtitle: 'Manage prescriptions',
          icon: Icons.medication_outlined,
          iconColor: Colors.green,
          route: '/patient/profile/medicines',
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
