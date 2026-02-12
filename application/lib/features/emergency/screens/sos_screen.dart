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
  int? _lastKnownMinEtaMinutes;

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
                    // Calculate minimum ETA
                    int? minMinutes;
                    for (var s in servicesData) {
                        int? minutes = _parseEtaToMinutes(s['eta']);
                        if (minutes != null) {
                            if (minMinutes == null || minutes < minMinutes) {
                                minMinutes = minutes;
                            }
                        }
                    }

                    if (minMinutes != null && minMinutes != _lastKnownMinEtaMinutes) {
                        _lastKnownMinEtaMinutes = minMinutes;
                        _etaRemaining = Duration(minutes: minMinutes);
                    }

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

  int? _parseEtaToMinutes(String? eta) {
    if (eta == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(eta);
    if (match != null) {
      int val = int.parse(match.group(1)!);
      if (eta.toLowerCase().contains('hour') || eta.toLowerCase().contains('hr')) {
        val *= 60;
      }
      return val;
    }
    return null;
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
              backgroundColor: Theme.of(context).colorScheme.surface,
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
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
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
      setState(() {
        _isActivating = true; // Use the same loading state
      });

      try {
        final reason = result['reason'] as CancellationReason;
        final comments = result['comments'] as String?;

        await _sosService.stopSOS(
          cancellationReason: reason.label,
          cancellationComments: comments,
        );

        // Log cancellation
        EmergencyAuditService().logCancellation(
          reason: reason,
          userId: ProfileService().currentUser?.id ?? 'unknown',
          comments: comments,
          alertDetails: {
            'activationTime': DateTime.now()
                .subtract(const Duration(minutes: 1))
                .toString(),
            'location': 'New Delhi, India', // Consistent with map mock
            'services_notified': ['Ambulance', 'Police'],
          },
        );

        _logEvent('activation_cancelled');
        if (mounted) {
          setState(() {
            _isActive = false;
            _isActivating = false;
          });
          _etaTimer?.cancel();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isActivating = false;
            _activationError = 'Failed to stop SOS: $e';
          });
        }
      }
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'SOS',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: colorScheme.onSurface),
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
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withOpacity(0.12),
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
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap the button below to alert emergency services and your contacts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
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
                color: colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _activationError!,
                      style: GoogleFonts.roboto(color: colorScheme.error),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                        color: const Color(0xFFFF3B30).withOpacity(0.3),
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
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatEta(_etaRemaining),
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people_outline, size: 20, color: colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(
              'Emergency Contacts',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
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
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: contact['color'].withOpacity(0.1),
                  child: Text(
                    contact['initial'],
                    style: TextStyle(
                      color: contact['color'],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name'],
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        contact['relation'],
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Notified',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.security_outlined, size: 20, color: colorScheme.onSurface),
            const SizedBox(width: 8),
            Text(
              'Responding Services',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_services.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Contacting nearest services...',
                  style: GoogleFonts.roboto(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          for (final service in _services)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: service['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      service['icon'],
                      color: service['color'],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['name'],
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          service['status'],
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    service['eta'],
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                _isActive ? 'Stopping SOS...' : 'Activating SOS...',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Activate SOS?',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: Text(
        'This will alert emergency services and your contacts.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
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
