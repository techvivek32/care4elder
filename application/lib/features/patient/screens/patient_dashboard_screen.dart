import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/hero_service.dart';
import '../../../core/services/health_tip_service.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final PageController _pageController = PageController();
  int _carouselIndex = 0;
  Timer? _carouselTimer;
  List<HeroSection> _heroSections = [];
  List<HealthTip> _healthTips = [];
  bool _isLoadingHeroes = true;
  bool _isLoadingTips = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    ProfileService().fetchProfile();
  }

  String _getGreeting() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadHeroSections(),
      _loadHealthTips(),
    ]);
  }

  Future<void> _loadHeroSections() async {
    try {
      final heroes = await HeroService.fetchHeroSections('patient');
      if (mounted) {
        setState(() {
          _heroSections = heroes;
          _isLoadingHeroes = false;
        });
        if (_heroSections.isNotEmpty) {
          _startCarouselTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHeroes = false;
        });
      }
    }
  }

  Future<void> _loadHealthTips() async {
    try {
      final tips = await HealthTipService.fetchHealthTips();
      if (mounted) {
        setState(() {
          _healthTips = tips;
          _isLoadingTips = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTips = false;
        });
      }
    }
  }

  void _showTipDetails(HealthTip tip) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tip.title,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            tip.description,
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients && _heroSections.isNotEmpty) {
        int nextPage = _carouselIndex + 1;
        if (nextPage >= _heroSections.length) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: ListenableBuilder(
                                  listenable: ProfileService(),
                                  builder: (context, child) {
                                    final user = ProfileService().currentUser;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_getGreeting()},',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user?.fullName ?? 'User',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Stay safe and healthy',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              /*
                              GestureDetector(
                                onTap: () =>
                                    context.push('/patient/notifications'),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(
                                        Icons.notifications_none,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      Positioned(
                                        top: -2,
                                        right: -2,
                                        child: ValueListenableBuilder<int>(
                                          valueListenable: NotificationService()
                                              .unreadCountNotifier,
                                          builder: (context, count, child) {
                                            if (count == 0) {
                                              return const SizedBox.shrink();
                                            }
                                            return Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFFF5252),
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                count > 9
                                                    ? '9+'
                                                    : count.toString(),
                                                style: GoogleFonts.roboto(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              */
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Carousel (Replacing SOS Button)
                        if (_isLoadingHeroes)
                          const SizedBox(
                            height: 180,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_heroSections.isNotEmpty)
                          Column(
                            children: [
                              SizedBox(
                                height: 180,
                                child: PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) {
                                    setState(() {
                                      _carouselIndex = index;
                                    });
                                  },
                                  itemCount: _heroSections.length,
                                  itemBuilder: (context, index) {
                                    final item = _heroSections[index];
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Image with placeholder and error handling
                                            CachedNetworkImage(
                                              imageUrl: item.imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(
                                                color: colorScheme.surfaceVariant,
                                                child: const Center(
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                              errorWidget: (context, url, error) {
                                                if (kDebugMode) {
                                                  print('Error loading image: $url, error: $error');
                                                }
                                                return Container(
                                                  color: colorScheme.surfaceVariant,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.image_not_supported_outlined,
                                                        color: colorScheme.primary.withOpacity(0.5),
                                                        size: 40,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        'Image not available',
                                                        style: GoogleFonts.roboto(
                                                          fontSize: 12,
                                                          color: colorScheme.onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                            // Gradient Overlay
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(0.7),
                                                  ],
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(24.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  if (item.subtitle.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      item.subtitle,
                                                      style: GoogleFonts.roboto(
                                                        fontSize: 14,
                                                        color: Colors.white.withOpacity(0.9),
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Carousel Indicators
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  _heroSections.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: _carouselIndex == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _carouselIndex == index
                                          ? colorScheme.primary
                                          : colorScheme.onSurface.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 32),

                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.medical_services_outlined,
                                  label: 'Consult a\nDoctor',
                                  color: const Color(0xFF041E34),
                                  onTap: () =>
                                      context.push('/patient/consultation'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.description_outlined,
                                  label: 'Medical\nRecords',
                                  color: const Color(0xFF041E34),
                                  onTap: () => context.push('/patient/records'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildQuickActionCard(
                                  icon: Icons.people_outline,
                                  label: 'Emergency\nContacts',
                                  color: const Color(0xFF041E34),
                                  onTap: () => context.push('/patient/contacts'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Health Tips
                        Text(
                          'Health Tips',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _isLoadingTips
                            ? const Center(child: CircularProgressIndicator())
                            : _healthTips.isEmpty
                                ? const Text('No health tips available')
                                : Column(
                                    children: _healthTips.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final tip = entry.value;
                                      final colors = [
                                        colorScheme.primary,
                                        Colors.green.shade600,
                                        Colors.orange.shade600,
                                        Colors.purple.shade600,
                                        Colors.red.shade600,
                                      ];
                                      final cardColor = colors[index % colors.length];

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: GestureDetector(
                                          onTap: () => _showTipDetails(tip),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              color: cardColor,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        tip.title,
                                                        style: GoogleFonts.roboto(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        tip.description,
                                                        style: GoogleFonts.roboto(
                                                          fontSize: 13,
                                                          color: Colors.white.withOpacity(0.8),
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),

                        const SizedBox(height: 32),

                        // Tagline
                        Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.health_and_safety_outlined,
                                    size: 20,
                                    color: Color(0xFF007BFF),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Smart Care with Human Touch',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF007BFF),
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.medical_services_outlined,
                                    size: 20,
                                    color: Color(0xFF007BFF),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: 60,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF007BFF).withOpacity(0.1),
                                      const Color(0xFF007BFF),
                                      const Color(0xFF007BFF).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Extra padding for bottom nav
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthTipCard(HealthTip tip, Color cardColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
