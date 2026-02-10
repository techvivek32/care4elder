import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/theme/app_colors.dart';
import '../services/emergency_audit_service.dart';
import '../services/sos_service.dart';
import '../widgets/cancellation_dialog.dart';
import '../widgets/emergency_map.dart';
import '../widgets/safety_tips_section.dart';
import 'alert_history_screen.dart';

class SosScreen extends StatefulWidget {
  final bool autoStart;
  const SosScreen({super.key, this.autoStart = false});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final SOSService _sosService = SOSService();
  bool _isActive = false;
  bool _isActivating = false;
  String? _activationError;
  Timer? _etaTimer;
  Timer? _statusPollingTimer;
  Duration _etaRemaining = const Duration(minutes: 8);

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _checkActiveState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleFallDetection();
      });
    }
  }

  Future<void> _checkActiveState() async {
    final isActive = await _sosService.isSosActive();
    if (isActive && mounted) {
      setState(() {
        _isActive = true;
        _isActivating = false;
        _etaRemaining = const Duration(minutes: 8); // Should calculate based on start time
      });
      _startEtaTimer();
      _startStatusPolling();
    }
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final sosId = await _sosService.getActiveSosId();
      if (sosId != null) {
        final statusData = await _sosService.getSOSStatus(sosId);
        if (statusData != null && mounted) {
            // Check if resolved
            if (statusData['status'] == 'resolved') {
                await _sosService.stopSOS(); // Clean up local state
                setState(() {
                    _isActive = false;
                });
                timer.cancel();
                return;
            }

            // Update Services
            if (statusData['callStatus'] != null && statusData['callStatus']['service'] != null) {
                final servicesData = statusData['callStatus']['service']['selectedServices'] as List?;
                if (servicesData != null) {
                    setState(() {
                        _services = servicesData.map<Map<String, dynamic>>((s) {
                            String name = s['name'] ?? 'Unknown';
                            return {
                                'name': name,
                                'status': s['status'] == 'active' ? 'Dispatched' : (s['status'] ?? 'Active'),
                                'eta': s['eta'] ?? 'Calculating...',
                                'icon': _getServiceIcon(name),
                                'color': _getServiceColor(name),
                            };
                        }).toList();
                    });
                }
            }
        }
      }
    });
  }

  IconData _getServiceIcon(String name) {
    switch (name.toLowerCase()) {
      case 'ambulance': return Icons.medical_services_outlined;
      case 'police': return Icons.local_police_outlined;
      case 'fire dept': return Icons.fire_truck_outlined;
      default: return Icons.emergency_outlined;
    }
  }

  Color _getServiceColor(String name) {
    switch (name.toLowerCase()) {
      case 'ambulance': return Colors.red;
      case 'police': return Colors.blue;
      case 'fire dept': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Future<void> _loadContacts() async {
    final profileService = ProfileService();
    if (profileService.currentUser == null) {
      await profileService.fetchProfile();
    }

    if (profileService.currentUser != null && mounted) {
      setState(() {
        _contacts = profileService.currentUser!.emergencyContacts.map((c) {
          return {
            'name': c.name,
            'relation': c.relation,
            'phone': c.phone,
            'status': 'Notified',
            'initial': c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
            'color': Colors.blue,
          };
        }).toList();
      });
    }
  }

  Future<void> _handleFallDetection() async {
    final confirmed = await _showFallDetectionDialog();
    if (confirmed && mounted) {
      await _activateSos();
    }
  }

  Future<bool> _showFallDetectionDialog() async {
    int secondsRemaining = 10;
    Timer? timer;
    bool timerStarted = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (!timerStarted) {
              timerStarted = true;
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (secondsRemaining > 0) {
                  setState(() => secondsRemaining--);
                } else {
                  t.cancel();
                  Navigator.of(context).pop(true);
                }
              });
            }
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Fall Detected!',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
              content: Text(
                'SOS will be activated automatically in $secondsRemaining seconds.',
                style: GoogleFonts.roboto(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Activate Now'),
                ),
              ],
            );
          },
        );
      },
    );

    timer?.cancel();
    return result ?? false;
  }

  List<Map<String, dynamic>> _contacts = [];

  List<Map<String, dynamic>> _services = [];

  @override
  void dispose() {
    _etaTimer?.cancel();
    _statusPollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleSosPressed() async {
    final confirmed = await _showConfirmationDialog();
    if (!confirmed || !mounted) return;
    await _activateSos();
  }

  Future<bool> _showConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SosConfirmationDialog(),
    );
    return result ?? false;
  }

  Future<void> _activateSos() async {
    setState(() {
      _isActivating = true;
      _activationError = null;
    });
    _logEvent('activation_requested');
    try {
      await _sosService.startSOS();

      if (!mounted) return;
      setState(() {
        _isActive = true;
        _isActivating = false;
        _etaRemaining = const Duration(minutes: 8);
      });
      _startEtaTimer();
      _logEvent('activation_success');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isActivating = false;
        _activationError = 'Activation failed. Please try again.';
      });
      _logEvent('activation_failed: $error');
    }
  }

  void _startEtaTimer() {
    _etaTimer?.cancel();
    _etaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_etaRemaining.inSeconds <= 0) {
        timer.cancel();
        setState(() {
          _etaRemaining = Duration.zero;
        });
      } else {
        setState(() {
          _etaRemaining -= const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _confirmCancel() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CancellationDialog(),
    );

    if (result != null && mounted) {
      await _sosService.stopSOS();

      // Log cancellation
      EmergencyAuditService().logCancellation(
        reason: result['reason'] as CancellationReason,
        userId: ProfileService().currentUser?.id ?? 'unknown',
        comments: result['comments'] as String?,
        alertDetails: {
          'activationTime': DateTime.now()
              .subtract(const Duration(minutes: 1))
              .toString(),
          'location': 'New Delhi, India', // Consistent with map mock
          'services_notified': ['Ambulance', 'Police'],
        },
      );

      _logEvent('activation_cancelled');
      setState(() {
        _isActive = false;
      });
      _etaTimer?.cancel();
    }
  }

  Future<void> _callEmergency() async {
    final Uri launchUri = Uri(scheme: 'tel', path: '911');
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _logEvent(String event) {
    debugPrint('SOS_EVENT: $event');
  }

  String _formatEta(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SOS',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textDark),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertHistoryScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isActive ? _buildActiveState() : _buildIdleState(),
          if (_isActivating) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildIdleState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: Color(0xFFFF3B30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Emergency SOS',
            style: GoogleFonts.roboto(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the button below to alert emergency services and your contacts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleSosPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Activate SOS',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_activationError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _activationError!,
                      style: GoogleFonts.roboto(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          const SafetyTipsSection(),
        ],
      ),
    );
  }

  Widget _buildActiveState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Help is On The Way',
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFCE2C2C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emergency services have been alerted',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 18,
                      color: AppColors.textGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatEta(_etaRemaining),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const EmergencyMap(),
          const SizedBox(height: 24),
          _buildContactsCard(),
          const SizedBox(height: 24),
          _buildServicesCard(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirmCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Cancel Emergency Alert',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const SafetyTipsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContactsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              'Emergency Contacts',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final contact in _contacts)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: (contact['color'] as Color).withValues(
                    alpha: 0.1,
                  ),
                  radius: 24,
                  child: Text(
                    contact['initial'] as String,
                    style: GoogleFonts.roboto(
                      color: contact['color'] as Color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        contact['relation'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: contact['status'] == 'Called'
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    contact['status'] as String,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: contact['status'] == 'Called'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () async {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: contact['phone'] as String,
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildServicesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Emergency Services',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        for (final service in _services)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png', // Fallback or placeholder, using icon instead below
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      service['icon'] as IconData,
                      color: service['color'] as Color,
                      size: 32,
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['name'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        service['status'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ETA: ${service['eta']}',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF3B30)),
              const SizedBox(height: 16),
              Text(
                'Activating SOS...',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SosConfirmationDialog extends StatefulWidget {
  const SosConfirmationDialog({super.key});

  @override
  State<SosConfirmationDialog> createState() => _SosConfirmationDialogState();
}

class _SosConfirmationDialogState extends State<SosConfirmationDialog> {
  int _secondsRemaining = 4;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _secondsRemaining == 0;
    return AlertDialog(
      title: Text(
        'Activate SOS?',
        style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        'This will alert emergency services and your contacts.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
          ),
          onPressed: canConfirm ? () => Navigator.pop(context, true) : null,
          child: Text(
            canConfirm ? 'Confirm' : 'Confirm (${_secondsRemaining}s)',
          ),
        ),
      ],
    );
  }
}
