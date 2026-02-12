import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../services/doctor_auth_service.dart';

class DoctorOtpScreen extends StatefulWidget {
  final String identifier;
  final bool isEmail;
  final bool isLogin;

  const DoctorOtpScreen({
    super.key,
    required this.identifier,
    this.isEmail = false,
    this.isLogin = false,
  });

  @override
  State<DoctorOtpScreen> createState() => _DoctorOtpScreenState();
}

class _DoctorOtpScreenState extends State<DoctorOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isResendEnabled = false;
  int _resendCountdown = 60;
  Timer? _timer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _isResendEnabled = false;
      _resendCountdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isResendEnabled = true;
          });
        }
        timer.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;
      if (widget.isLogin && !widget.isEmail) {
        result = await DoctorAuthService().verifyLoginOtp(
          widget.identifier,
          _otpController.text,
        );
      } else {
        result = await DoctorAuthService().verifyOtp(
          _otpController.text,
          isEmail: widget.isEmail,
        );
      }

      if (result['success'] == true) {
        if (mounted) {
          if (widget.isLogin) {
            final status = result['verificationStatus'];
            if (status == 'approved') {
              context.go('/doctor/home');
            } else if (status == 'pending') {
              context.go('/doctor/verification-pending');
            } else if (status == 'rejected') {
              context.go('/doctor/rejected');
            } else {
              // Default fallback
              context.go('/doctor/verification-pending');
            }
          } else {
            // Registration flow
            context.push('/doctor/register-form');
          }
        }
      } else {
        if (mounted) {
          final errorText = result['error'] ?? 'Invalid OTP. Please try again.';
          if (errorText.toString().toLowerCase().contains('rejected')) {
            context.go('/doctor/rejected');
            return;
          }
          setState(() {
            _errorMessage = errorText;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_isResendEnabled) return;

    setState(() {
      _isLoading = true;
      _otpController.clear();
      _errorMessage = null;
    });

    try {
      final success = await DoctorAuthService().sendOtp(
        widget.identifier,
        isEmail: widget.isEmail,
        intent: widget.isLogin ? 'login' : 'register',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent successfully')),
          );
          _startResendTimer();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Failed to send OTP')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to resend OTP: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getMaskedIdentifier() {
    if (widget.identifier.length < 4) return widget.identifier;
    if (widget.isEmail) {
      // Simple email masking
      final parts = widget.identifier.split('@');
      if (parts.length == 2) {
        final name = parts[0];
        if (name.length > 2) {
          return '${name.substring(0, 2)}***@${parts[1]}';
        }
        return widget.identifier;
      }
    }
    // Phone masking
    final visibleDigits = widget.identifier.substring(
      widget.identifier.length - 4,
    );
    return '******$visibleDigits';
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppColors.primaryBlue, width: 2),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.red, width: 2),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isEmail ? Icons.email_outlined : Icons.phone_android,
                  color: AppColors.primaryBlue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verification Code',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We have sent the verification code to',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: AppColors.textGrey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getMaskedIdentifier(),
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 32),
              Pinput(
                controller: _otpController,
                focusNode: _focusNode,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                errorPinTheme: _errorMessage != null ? errorPinTheme : null,
                onCompleted: (_) => _handleVerify(),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.roboto(color: Colors.red, fontSize: 14),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verify OTP',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Didn\'t receive code? ',
                    style: GoogleFonts.roboto(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: _isResendEnabled ? _handleResend : null,
                    child: Text(
                      _isResendEnabled
                          ? 'Resend'
                          : 'Resend in ${_resendCountdown}s',
                      style: GoogleFonts.roboto(
                        color: _isResendEnabled
                            ? AppColors.primaryBlue
                            : AppColors.textGrey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
