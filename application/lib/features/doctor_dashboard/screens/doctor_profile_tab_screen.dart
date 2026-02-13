import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../consultation/screens/doctor_reviews_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../services/doctor_profile_service.dart';

class DoctorProfileTabScreen extends StatefulWidget {
  const DoctorProfileTabScreen({super.key});

  @override
  State<DoctorProfileTabScreen> createState() =>
      _DoctorProfileTabScreenState();
}

class _DoctorProfileTabScreenState extends State<DoctorProfileTabScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      await DoctorProfileService().getProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AnimatedBuilder(
      animation: DoctorProfileService(),
      builder: (context, _) {
        final profile = DoctorProfileService().currentProfile;

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile',
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBackground : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            context.push('/doctor/settings');
                          },
                          icon: const Icon(Icons.settings_outlined),
                          color: isDark ? Colors.white70 : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with Camera Icon
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE3F2FD),
                              ),
                              child: ClipOval(
                                child: profile.profileImage != null
                                    ? CachedNetworkImage(
                                        imageUrl: profile.profileImage!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        errorWidget: (context, url, error) => Icon(
                                          Icons.person,
                                          size: 50,
                                          color: isDark ? Colors.white38 : AppColors.primaryBlue,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 50,
                                        color: isDark ? Colors.white38 : AppColors.primaryBlue,
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: isDark
                                      ? AppColors.darkPremiumGradient
                                      : AppColors.premiumGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () {
                                    context.push('/doctor/profile/edit');
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profile.name,
                          style: GoogleFonts.roboto(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.specialty,
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildBadge(
                              icon: Icons.verified,
                              label: 'Verified',
                              color: Colors.green,
                              bgColor: isDark ? Colors.green.withOpacity(0.1) : const Color(0xFFE8F5E9),
                            ),
                            const SizedBox(width: 12),
                            _buildBadge(
                              icon: Icons.emoji_events,
                              label: 'Top Doctor',
                              color: Colors.blue,
                              bgColor: isDark ? Colors.blue.withOpacity(0.1) : const Color(0xFFE3F2FD),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatCard(
                        profile.rating.toString(),
                        'Rating',
                        icon: Icons.star,
                        iconColor: Colors.amber,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorReviewsScreen(
                                doctorId: profile.id,
                                doctorName: profile.name,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      /* // Hiding Consultations card as requested
                      _buildStatCard(
                        profile.totalConsultations.toString(),
                        'Consultations',
                        onTap: () {
                          context.push('/doctor/history');
                        },
                      ),
                      const SizedBox(width: 8),
                      */
                      _buildStatCard(
                        '₹${profile.walletBalance.toStringAsFixed(0)}',
                        'Earnings',
                        onTap: () {
                          context.push('/doctor/earnings');
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildStatCard(
                        profile.reviews.toString(),
                        'Reviews',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorReviewsScreen(
                                doctorId: profile.id,
                                doctorName: profile.name,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info Cards
                  _buildInfoCard(
                    icon: Icons.work_outline,
                    iconBg: isDark ? Colors.blue.withOpacity(0.1) : const Color(0xFFE3F2FD),
                    iconColor: Colors.blue,
                    label: 'Experience',
                    value: '${profile.experience} years',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.school_outlined,
                    iconBg: isDark ? Colors.green.withOpacity(0.1) : const Color(0xFFE8F5E9),
                    iconColor: Colors.green,
                    label: 'Qualifications',
                    value: profile.qualifications,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.local_hospital_outlined,
                    iconBg: isDark ? Colors.pink.withOpacity(0.1) : const Color(0xFFFCE4EC),
                    iconColor: Colors.pink,
                    label: 'Hospital/Clinic',
                    value: profile.hospitalAffiliation.isNotEmpty
                        ? profile.hospitalAffiliation
                        : 'Not added',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    iconBg: isDark ? Colors.blue.withOpacity(0.1) : const Color(0xFFE3F2FD),
                    iconColor: Colors.blue,
                    label: 'Phone',
                    value: profile.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.email_outlined,
                    iconBg: isDark ? Colors.blue.withOpacity(0.1) : const Color(0xFFE3F2FD),
                    iconColor: Colors.blue,
                    label: 'Email',
                    value: profile.email,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    iconBg: isDark ? Colors.orange.withOpacity(0.1) : const Color(0xFFFFF3E0),
                    iconColor: Colors.orange,
                    label: 'About',
                    value: profile.about,
                  ),

                  const SizedBox(height: 32),

                  // Edit Profile Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: isDark ? AppColors.darkPremiumGradient : AppColors.premiumGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        context.push('/doctor/profile/edit');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Edit Profile',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label, {
    IconData? icon,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: iconColor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    value,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
