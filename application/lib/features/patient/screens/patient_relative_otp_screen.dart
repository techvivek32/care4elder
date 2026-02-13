import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/services/profile_service.dart';

class PatientRelativeOtpScreen extends StatefulWidget {
  final String phoneNumber;
  final List<Map<String, String>>? contactsToSave;

  const PatientRelativeOtpScreen({
    super.key,
    required this.phoneNumber,
    this.contactsToSave,
  });

  @override
  State<PatientRelativeOtpScreen> createState() =>
      _PatientRelativeOtpScreenState();
}

class _PatientRelativeOtpScreenState extends State<PatientRelativeOtpScreen> {
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
          _timer?.cancel();
          _canResend = true;
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
    // Basic formatting for +91 XXXXX X1234
    // Assuming 10 digits input
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
      // Verify OTP (Relative Verification)
      await AuthService().verifyRelativeOtp(otp);

      // Save contacts ONLY after successful verification
      if (widget.contactsToSave != null) {
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'emergency_relatives',
          jsonEncode(widget.contactsToSave),
        );

        // Save to Backend
        await AuthService().updateRelatives(widget.contactsToSave!);
        
        // Refresh local profile
        await ProfileService().fetchProfile();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification Successful!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Dashboard
        context.go('/patient/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Theme.of(context).colorScheme.error,
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
      await AuthService().sendOtp(widget.phoneNumber);

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
            backgroundColor: Theme.of(context).colorScheme.error,
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
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? colorScheme.surface
          : AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? colorScheme.surface
            : AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).brightness == Brightness.light
                  ? colorScheme.onSurface
                  : Colors.white),
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
                // Header Logo (Same as Login)
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.light
                            ? colorScheme.onSurface
                            : Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // Title
                Text(
                  'Verify Relative',
                  style: GoogleFonts.roboto(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.light
                        ? colorScheme.onSurface
                        : Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the verification code sent to the relative\'s number ${_getFormattedPhone()}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.light
                        ? colorScheme.onSurfaceVariant
                        : Colors.white70,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // OTP Inputs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 48,
                      height: 56,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        onChanged: (value) => _onOtpChanged(value, index),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.light
                              ? colorScheme.onSurface
                              : Colors.white,
                        ),
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: Theme.of(context).brightness ==
                                  Brightness.light
                              ? colorScheme.surface
                              : AppColors.darkCardBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? colorScheme.outlineVariant
                                    : Colors.white24),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? colorScheme.outlineVariant
                                    : Colors.white24),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Resend Timer
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Didn't receive code? ",
                      style: GoogleFonts.roboto(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                      children: [
                        _canResend
                            ? TextSpan(
                                text: 'Resend',
                                style: GoogleFonts.roboto(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _isLoading ? null : _handleResend,
                              )
                            : TextSpan(
                                text: 'Resend in ${_start}s',
                                style: GoogleFonts.roboto(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? colorScheme.onSurface
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Verify Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: Theme.of(context).brightness == Brightness.light
                        ? AppColors.premiumGradient
                        : AppColors.darkPremiumGradient,
                    borderRadius: BorderRadius.circular(30),
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
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Verify',
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
