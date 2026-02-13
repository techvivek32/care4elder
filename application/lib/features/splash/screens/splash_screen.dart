import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../doctor_auth/services/doctor_auth_service.dart';
import '../../../core/services/permission_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Request all permissions on first time open
    final permissionService = PermissionService();
    bool alreadyRequested = await permissionService.hasRequestedPermissions();
    
    if (!alreadyRequested) {
      await permissionService.requestAllPermissions();
    }

    // Navigate based on auth state after a delay
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        bool isPatientLoggedIn = false;
        bool isDoctorLoggedIn = false;
        try {
          isPatientLoggedIn = await AuthService()
              .isSignedIn()
              .timeout(const Duration(milliseconds: 200), onTimeout: () {
                return false;
              });
          
          if (!isPatientLoggedIn) {
            isDoctorLoggedIn = await DoctorAuthService()
                .isSignedIn()
                .timeout(const Duration(milliseconds: 200), onTimeout: () {
                  return false;
                });
          }
        } catch (_) {
          isPatientLoggedIn = false;
          isDoctorLoggedIn = false;
        }

        if (mounted) {
          if (isPatientLoggedIn) {
            context.go('/patient/dashboard');
          } else if (isDoctorLoggedIn) {
            context.go('/doctor/home');
          } else {
            context.go('/selection');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.light
              ? AppColors.premiumGradient
              : AppColors.darkPremiumGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Logo
            Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.health_and_safety,
                      size: 150,
                      color: Colors.white,
                    );
                  },
                )
                .animate()
                .scale(duration: 600.ms, curve: Curves.easeOutBack)
                .then(delay: 200.ms)
                .fade(duration: 400.ms),

            const SizedBox(height: 32),

            const SizedBox(height: 12),

            // Tagline
            Text(
              'Healthcare & SOS Assistance',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.9),
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

          const Spacer(flex: 3),

          // Pagination Dots (Loading Indicator style)
          Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(context, true),
                  _buildDot(context, false),
                  _buildDot(context, false),
                ],
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1500.ms,
                color: Colors.white.withOpacity(0.8),
              ),

          const Spacer(flex: 1),
        ],
      ),
    ),
  );
}

Widget _buildDot(BuildContext context, bool isActive) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
      shape: BoxShape.circle,
    ),
  );
}
}
