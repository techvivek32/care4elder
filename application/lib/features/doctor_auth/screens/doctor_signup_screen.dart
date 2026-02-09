import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import '../services/doctor_auth_service.dart';
import '../../../core/theme/app_colors.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _phoneOtpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailOtpController = TextEditingController();

  // State Variables
  String _completePhoneNumber = '';
  bool _isPhoneValid = false;
  bool _showPhoneOtp = false;
  bool _isPhoneVerified = false;
  bool _isPhoneLoading = false;
  bool _isEmailValid = false;

  bool _showEmailOtp = false;

  bool _isEmailVerified = false;

  bool _isEmailLoading = false;

  // Timers
  Timer? _phoneTimer;
  int _phoneResendSeconds = 30;
  bool _canResendPhone = false;
  Timer? _emailTimer;
  int _emailResendSeconds = 30;
  bool _canResendEmail = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneOtpController.dispose();
    _emailController.dispose();
    _emailOtpController.dispose();
    _phoneTimer?.cancel();
    _emailTimer?.cancel();
    super.dispose();
  }

  // --- Phone Logic ---
  void _startPhoneTimer() {
    setState(() {
      _phoneResendSeconds = 30;
      _canResendPhone = false;
    });
    _phoneTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_phoneResendSeconds == 0) {
        setState(() {
          _canResendPhone = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _phoneResendSeconds--;
        });
      }
    });
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _completePhoneNumber.isNotEmpty
        ? _completePhoneNumber
        : _phoneController.text.trim();
    if (phone.isEmpty || !_isPhoneValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() => _isPhoneLoading = true);

    try {
      final success = await DoctorAuthService().sendOtp(phone, isEmail: false);

      if (mounted) {
        setState(() {
          _isPhoneLoading = false;
          if (success) {
            _showPhoneOtp = true;
            _startPhoneTimer();
          }
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your phone number')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send OTP. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPhoneLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _verifyPhoneOtp() async {
    if (_phoneOtpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isPhoneLoading = true);

    try {
      final result = await DoctorAuthService().verifyOtp(
        _phoneOtpController.text,
        isEmail: false,
      );
      final success = result['success'] == true;

      if (mounted) {
        setState(() {
          _isPhoneLoading = false;
          if (success) {
            _isPhoneVerified = true;
            _showPhoneOtp = false;
          }
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Phone number verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error'] ?? 'Invalid OTP. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPhoneLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Email Logic ---

  void _startEmailTimer() {
    setState(() {
      _emailResendSeconds = 30;
      _canResendEmail = false;
    });
    _emailTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_emailResendSeconds == 0) {
        setState(() {
          _canResendEmail = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _emailResendSeconds--;
        });
      }
    });
  }

  Future<void> _sendEmailOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isEmailLoading = true);

    try {
      // Use real service
      final success = await DoctorAuthService().sendOtp(email, isEmail: true);

      if (mounted) {
        setState(() {
          _isEmailLoading = false;
          if (success) {
            _showEmailOtp = true;
            _startEmailTimer();
          }
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent to your email address')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send OTP. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEmailLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _verifyEmailOtp() async {
    if (_emailOtpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isEmailLoading = true);

    try {
      final result = await DoctorAuthService().verifyOtp(
        _emailOtpController.text,
        isEmail: true,
      );
      final success = result['success'] == true;

      if (mounted) {
        setState(() {
          _isEmailLoading = false;
          if (success) {
            _isEmailVerified = true;
            _showEmailOtp = false;
          }
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email address verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error'] ?? 'Invalid OTP. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isEmailLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- UI Builders ---

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 4),
          Text(
            'Verified',
            style: GoogleFonts.roboto(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton(VoidCallback onPressed, bool isLoading) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Verify OTP',
                style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildSendOtpButton(VoidCallback? onPressed, bool isLoading) {
    return SizedBox(
      height: 56, // Match input height
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Get OTP',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  Widget _buildOtpInput(
    TextEditingController controller,
    VoidCallback onVerify,
    bool isLoading,
    VoidCallback onResend,
    int timerSeconds,
    bool canResend,
  ) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: GoogleFonts.roboto(
        fontSize: 20,
        color: AppColors.textDark,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Enter OTP',
          style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textGrey),
        ),
        const SizedBox(height: 8),
        Pinput(
          controller: controller,
          length: 6,
          defaultPinTheme: defaultPinTheme,
          focusedPinTheme: defaultPinTheme.copyWith(
            decoration: defaultPinTheme.decoration!.copyWith(
              border: Border.all(color: AppColors.primaryBlue),
            ),
          ),
          onCompleted: (_) => onVerify(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildVerifyButton(onVerify, isLoading)),
            const SizedBox(width: 16),
            TextButton(
              onPressed: canResend ? onResend : null,
              child: Text(
                canResend ? 'Resend OTP' : 'Resend in ${timerSeconds}s',
                style: GoogleFonts.roboto(
                  color: canResend ? AppColors.primaryBlue : AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Doctor Registration',
          style: GoogleFonts.roboto(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify Contact Details',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please verify your mobile number and email to continue',
                  style: GoogleFonts.roboto(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),

                // --- Mobile Number Section ---
                _buildSectionLabel('Mobile Number'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IntlPhoneField(
                          controller: _phoneController,
                          enabled: !_isPhoneVerified,
                          decoration: InputDecoration(
                            hintText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            counterText: '', // Hide counter
                          ),
                          initialCountryCode: 'IN',
                          disableLengthCheck: true, // Custom validation
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: (phone) {
                            setState(() {
                              _completePhoneNumber = phone.completeNumber;
                              _isPhoneValid = phone.number.length >= 10;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_isPhoneVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: _buildVerifiedBadge(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: _buildSendOtpButton(
                          (_isPhoneValid && !_showPhoneOtp)
                              ? _sendPhoneOtp
                              : null,
                          _isPhoneLoading && !_showPhoneOtp,
                        ),
                      ),
                  ],
                ),

                if (_showPhoneOtp && !_isPhoneVerified)
                  _buildOtpInput(
                    _phoneOtpController,
                    _verifyPhoneOtp,
                    _isPhoneLoading,
                    _sendPhoneOtp,
                    _phoneResendSeconds,
                    _canResendPhone,
                  ),

                const SizedBox(height: 32),

                // --- Email Section ---
                _buildSectionLabel('Email Address'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          enabled: !_isEmailVerified,
                          decoration: InputDecoration(
                            hintText: 'john.doe@example.com',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.textGrey,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          onChanged: (value) {
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            setState(() {
                              _isEmailValid = emailRegex.hasMatch(value);
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_isEmailVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: _buildVerifiedBadge(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: _buildSendOtpButton(
                          (_isEmailValid && !_showEmailOtp)
                              ? _sendEmailOtp
                              : null,
                          _isEmailLoading && !_showEmailOtp,
                        ),
                      ),
                  ],
                ),

                if (_showEmailOtp && !_isEmailVerified)
                  _buildOtpInput(
                    _emailOtpController,
                    _verifyEmailOtp,
                    _isEmailLoading,
                    _sendEmailOtp,
                    _emailResendSeconds,
                    _canResendEmail,
                  ),

                const SizedBox(height: 48),

                // --- Continue Button ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isPhoneVerified && _isEmailVerified)
                        ? () {
                            DoctorAuthService().updateRegistrationData(
                              email: _emailController.text.trim(),
                              phoneNumber: _completePhoneNumber.isNotEmpty
                                  ? _completePhoneNumber.trim()
                                  : _phoneController.text.trim(),
                            );
                            context.push('/doctor/register-form');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: AppColors.primaryBlue.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    child: Text(
                      'Continue to Details',
                      style: GoogleFonts.roboto(
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
