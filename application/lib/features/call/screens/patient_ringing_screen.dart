import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/call_request_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import 'video_call_screen.dart';

class PatientRingingScreen extends StatefulWidget {
  final String callRequestId;
  final String channelName;
  final String doctorName;

  const PatientRingingScreen({
    super.key,
    required this.callRequestId,
    required this.channelName,
    required this.doctorName,
  });

  @override
  State<PatientRingingScreen> createState() => _PatientRingingScreenState();
}

class _PatientRingingScreenState extends State<PatientRingingScreen> {
  final CallRequestService _callService = CallRequestService();
  Timer? _pollingTimer;
  Timer? _timeoutTimer;
  bool _ending = false;
  int _ringSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _startTimeout();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final token = await AuthService().getToken();
      if (token == null || _ending) return;

      final call = await _callService.getCallRequest(
        token: token,
        callRequestId: widget.callRequestId,
      );

      if (call == null) return;

      if (call.status == 'accepted') {
        _ending = true;
        if (mounted) {
          context.pushReplacement(
            '/patient/doctor/${widget.callRequestId}/call',
            extra: {
              'channelName': widget.channelName,
              'doctorName': widget.doctorName,
              'callRequestId': widget.callRequestId,
            },
          );
        }
      } else if (call.status == 'declined') {
        _ending = true;
        _showMessageAndExit('Doctor declined the call');
      } else if (call.status == 'cancelled') {
        _ending = true;
        _showMessageAndExit('Call cancelled');
      } else if (call.status == 'timeout') {
        _ending = true;
        _showMessageAndExit('Doctor did not pick up');
      } else {
        setState(() {
          _ringSeconds += 2;
        });
      }
    });
  }

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
      if (_ending) return;
      final token = await AuthService().getToken();
      if (token == null) return;
      await _callService.updateCallRequestStatus(
        token: token,
        callRequestId: widget.callRequestId,
        status: 'timeout',
      );
      _ending = true;
      _showMessageAndExit('Doctor did not pick up');
    });
  }

  void _showMessageAndExit(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    context.pop();
  }

  Future<void> _cancelCall() async {
    if (_ending) return;
    _ending = true;
    final token = await AuthService().getToken();
    if (token != null) {
      await _callService.updateCallRequestStatus(
        token: token,
        callRequestId: widget.callRequestId,
        status: 'cancelled',
      );
    }
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade800,
                child: const Icon(Icons.person, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 20),
              Text(
                widget.doctorName,
                style: GoogleFonts.roboto(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ringing... ${_ringSeconds}s',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _cancelCall,
                icon: const Icon(Icons.call_end),
                label: const Text('Cancel Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
