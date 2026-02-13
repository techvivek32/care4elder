import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../services/doctor_auth_service.dart';
import 'doctor_otp_screen.dart';

class DoctorLoginScreen extends StatefulWidget {
  const DoctorLoginScreen({super.key});

  @override
  State<DoctorLoginScreen> createState() => _DoctorLoginScreenState();
}

class _DoctorLoginScreenState extends State<DoctorLoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String _completePhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Phone Login (OTP)
    if (_tabController.index == 0) {
      final phoneIdentifier = _completePhoneNumber.isNotEmpty
          ? _completePhoneNumber.trim()
          : _phoneController.text.trim();
      if (phoneIdentifier.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number')),
        );
        return;
      }
      
      setState(() => _isLoading = true);
      try {
        final success = await DoctorAuthService().sendLoginOtp(phoneIdentifier);

        if (!mounted) return;

        if (success) {
           Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorOtpScreen(
                identifier: phoneIdentifier,
                isEmail: false,
                isLogin: true,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send OTP. Please try again.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    // Email/Password Login
    if (_tabController.index == 1) {
      if (_emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email')),
        );
        return;
      }
      if (_passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final result = await DoctorAuthService().loginWithPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (!mounted) return;

        if (result['success']) {
          final status = result['verificationStatus'];
          if (status == 'approved') {
            context.go('/doctor/home');
          } else if (status == 'pending') {
            context.go('/doctor/verification-pending');
          } else if (status == 'rejected') {
            context.go('/doctor/rejected');
          } else {
            // Fallback
            context.go('/doctor/home');
          }
        } else if (result['verificationStatus'] == 'rejected') {
          context.go('/doctor/rejected');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Login failed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/selection');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            // Logo
                            Image.asset(
                              'assets/images/logo.png',
                              width: 80,
                              height: 80,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'CareSOS Doctor',
                              style: GoogleFonts.roboto(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to continue',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Tabs
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                ),
                                indicatorPadding: const EdgeInsets.all(2),
                                dividerColor: Colors.transparent,
                                labelColor: AppColors.textDark,
                                unselectedLabelColor: AppColors.textGrey,
                                labelStyle: GoogleFonts.roboto(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                tabs: const [
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.phone_outlined, size: 16),
                                        SizedBox(width: 6),
                                        Text('Phone'),
                                      ],
                                    ),
                                  ),
                                  Tab(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.email_outlined, size: 16),
                                        SizedBox(width: 6),
                                        Text('Email'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Tab View Content
                            _tabController.index == 0
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Phone Number',
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      IntlPhoneField(
                                        controller: _phoneController,
                                        decoration: InputDecoration(
                                          hintText: 'Enter phone number',
                                          hintStyle: GoogleFonts.roboto(
                                            color: AppColors.textGrey,
                                            fontSize: 14,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.primaryBlue,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                        ),
                                        initialCountryCode: 'IN',
                                        onChanged: (phone) {
                                          _completePhoneNumber =
                                              phone.completeNumber;
                                        },
                                        languageCode: "en",
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Email Address',
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.email_outlined,
                                            size: 20,
                                          ),
                                          hintText: 'name@hospital.com',
                                          hintStyle: GoogleFonts.roboto(
                                            color: AppColors.textGrey,
                                            fontSize: 14,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.primaryBlue,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'Password',
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: !_isPasswordVisible,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                            size: 20,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _isPasswordVisible
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(() =>
                                                _isPasswordVisible =
                                                    !_isPasswordVisible),
                                          ),
                                          hintText: '••••••••',
                                          hintStyle: GoogleFonts.roboto(
                                            color: AppColors.textGrey,
                                            fontSize: 14,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8F0),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.primaryBlue,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            // Handle forgot password
                                          },
                                          child: Text(
                                            'Forgot Password?',
                                            style: GoogleFonts.roboto(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                            const SizedBox(height: 24),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Login',
                                            style: GoogleFonts.roboto(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const Spacer(),

                            // Footer
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                context.push('/doctor/signup');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: Text(
                                'Don\'t have an account? Register',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
