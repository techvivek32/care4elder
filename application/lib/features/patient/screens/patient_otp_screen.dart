import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/profile_service.dart';
import '../../auth/services/auth_service.dart';

class PatientOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String? email;
  final bool isSignup;
  final Map<String, dynamic>? signupData;

  const PatientOtpScreen({
    super.key,
    required this.phoneNumber,
    this.email,
    this.isSignup = false,
    this.signupData,
  });

  @override
  State<PatientOtpScreen> createState() => _PatientOtpScreenState();
}

class _PatientOtpScreenState extends State<PatientOtpScreen> {
  // OTP Logic
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  // Timer Logic
  Timer? _timer;
  int _start = 60;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _start = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  String _getFormattedPhone() {
    if (widget.phoneNumber.length == 10) {
      return '+91 ${widget.phoneNumber.substring(0, 5)} ${widget.phoneNumber.substring(5)}';
    }
    return '+91 ${widget.phoneNumber}';
  }

  Future<void> _handleVerify() async {
    String otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isSignup && widget.email != null) {
        // Verify Email OTP (Backend)
        final result = await AuthService().verifyPatientEmail(widget.email!, otp);
        
        // Update ProfileService with registration data (like DOB)
        if (mounted && widget.signupData != null) {
          final profileService = Provider.of<ProfileService>(context, listen: false);
          
          // Initial user profile from registration data and verification response
          final userData = result['user'] ?? {};
          final dobStr = widget.signupData!['dob'];
          
          if (profileService.currentUser == null) {
            // Create initial profile if not exists
            profileService.updateLocalProfile(UserProfile(
              id: userData['id'] ?? userData['_id'] ?? '',
              fullName: userData['name'] ?? widget.signupData!['name'] ?? '',
              email: userData['email'] ?? widget.email!,
              phoneNumber: userData['phone'] ?? widget.phoneNumber,
              profilePictureUrl: '',
              dateOfBirth: dobStr != null ? DateTime.tryParse(dobStr) : null,
              location: '',
              bloodGroup: '',
              allergies: '',
            ));
          } else {
            // Update existing profile with DOB if it's missing
            if (dobStr != null && profileService.currentUser?.dateOfBirth == null) {
              profileService.updateLocalProfile(
                profileService.currentUser!.copyWith(
                  dateOfBirth: DateTime.tryParse(dobStr),
                )
              );
            }
          }
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification Successful!'),
              backgroundColor: Colors.green,
            ),
          );

          context.go('/patient/permissions');
        }
      } else {
        // Login OTP logic
        await AuthService().verifyLoginOtp(widget.phoneNumber, otp);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Successful!'),
              backgroundColor: Colors.green,
            ),
          );

          context.go('/patient/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isSignup && widget.email != null) {
        await AuthService().resendOtp(email: widget.email!, role: 'Patient');
      } else {
        await AuthService().sendLoginOtp(widget.phoneNumber);
      }

      if (mounted) {
        _startTimer();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('OTP Resent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.health_and_safety,
                          size: 50,
                          color: colorScheme.primary,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Care4Elder',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                Text(
                  'Enter OTP',
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification code to your phone\n${_getFormattedPhone()}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      height: 56,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) => _onOtpChanged(value, index),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Center(
                  child: _canResend
                      ? TextButton(
                          onPressed: _handleResend,
                          child: Text(
                            'Resend Code',
                            style: GoogleFonts.roboto(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : RichText(
                          text: TextSpan(
                            text: 'Resend code in ',
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: '${_start}s',
                                style: GoogleFonts.roboto(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: Theme.of(context).brightness == Brightness.light
                        ? AppColors.premiumGradient
                        : AppColors.darkPremiumGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
