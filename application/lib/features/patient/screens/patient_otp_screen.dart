import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
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
        await AuthService().verifyPatientEmail(widget.email!, otp);
      } else {
        // Fallback or Login OTP logic (Legacy/Mock)
        await AuthService().verifyOtp(widget.phoneNumber, otp);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
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
                        return const Icon(
                          Icons.health_and_safety,
                          size: 50,
                          color: AppColors.primaryBlue,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Care4Elder',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
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
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification code to your phone\n${_getFormattedPhone()}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: AppColors.textGrey,
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
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primaryBlue,
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
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : RichText(
                          text: TextSpan(
                            text: 'Resend code in ',
                            style: GoogleFonts.roboto(
                              color: AppColors.textGrey,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: '${_start}s',
                                style: GoogleFonts.roboto(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
