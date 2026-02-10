import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/doctor_service.dart';
import '../../../core/services/profile_service.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;

  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Doctor? _doctor;
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchDoctor();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchDoctor(silent: true);
      }
    });
  }

  Future<void> _fetchDoctor({bool silent = false}) async {
    try {
      final doctor = await DoctorService().fetchDoctorById(widget.doctorId);
      if (mounted) {
        setState(() {
          _doctor = doctor;
          if (!silent) _isLoading = false;
          if (doctor == null) {
            _error = 'Doctor not found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load doctor details';
          if (!silent) _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _doctor == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Text(
            _error ?? 'Doctor not found',
            style: GoogleFonts.roboto(fontSize: 16),
          ),
        ),
      );
    }

    final doctor = _doctor!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                bottom: 140,
              ), // Space for bottom bar
              child: Stack(
                children: [
                  // Background Image
                  Hero(
                    tag: 'doctor-${doctor.id}',
                    child: Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        image: doctor.profileImage.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(doctor.profileImage),
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              )
                            : null,
                      ),
                      child: doctor.profileImage.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 100,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),

                  // Back Button
                  Positioned(
                    top: 40,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.only(top: 240),
                    child: Column(
                      children: [
                        // Main Info Card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      doctor.name,
                                      style: GoogleFonts.roboto(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: doctor.isAvailable
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      doctor.isAvailable ? 'Online' : 'Offline',
                                      style: GoogleFonts.roboto(
                                        color: doctor.isAvailable
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                doctor.specialization,
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${doctor.rating} (${doctor.reviews} reviews)',
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: AppColors.textGrey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Stats Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              _buildStatCard(
                                Icons.access_time,
                                '${doctor.experienceYears} years',
                                'Experience',
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                Icons.school,
                                doctor.qualifications.isNotEmpty 
                                    ? doctor.qualifications 
                                    : 'MBBS', // Fallback if empty
                                'Degree',
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                Icons.chat_bubble_outline,
                                '${doctor.reviews}',
                                'Reviews',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // About Section
                        if (doctor.about.isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  doctor.about,
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: AppColors.textGrey,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Location Section (Static for now, or add to backend)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.lightBlue.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Clinic Location',
                                      style: GoogleFonts.roboto(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      doctor.hospitalAffiliation.isNotEmpty
                                          ? doctor.hospitalAffiliation
                                          : 'Main City Hospital', // Fallback
                                      style: GoogleFonts.roboto(
                                        fontSize: 14,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Add some padding at the bottom
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Consultation Fee',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${doctor.consultationFee}',
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _showConsultationDialog(context, doctor);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5252),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFFFF5252).withValues(alpha: 0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.videocam_rounded,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Call Now',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConsultationDialog(BuildContext context, Doctor doctor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ConsultationTypeSheet(doctor: doctor),
    );
  }
}

class _ConsultationTypeSheet extends StatefulWidget {
  final Doctor doctor;

  const _ConsultationTypeSheet({required this.doctor});

  @override
  State<_ConsultationTypeSheet> createState() => _ConsultationTypeSheetState();
}

class _ConsultationTypeSheetState extends State<_ConsultationTypeSheet> {
  String _selectedType = 'consultation'; // 'consultation' or 'emergency'
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final double fee = _selectedType == 'consultation' 
        ? widget.doctor.consultationFee 
        : widget.doctor.emergencyFee;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Consultation Type',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          _buildOption(
            title: 'Standard Consultation',
            price: widget.doctor.consultationFee,
            value: 'consultation',
            icon: Icons.video_call_rounded,
          ),
          const SizedBox(height: 16),
          _buildOption(
            title: 'Emergency Call',
            price: widget.doctor.emergencyFee,
            value: 'emergency',
            icon: Icons.emergency_rounded,
            isEmergency: true,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.6),
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
                      'Pay ₹$fee & Call',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption({
    required String title,
    required double price,
    required String value,
    required IconData icon,
    bool isEmergency = false,
  }) {
    final isSelected = _selectedType == value;
    
    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isEmergency ? Colors.red[50] : AppColors.primaryBlue.withOpacity(0.1))
              : Colors.grey[50],
          border: Border.all(
            color: isSelected
                ? (isEmergency ? Colors.red : AppColors.primaryBlue)
                : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEmergency ? Colors.red[100] : Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isEmergency ? Colors.red : AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (isEmergency)
                    Text(
                      'Immediate response',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '₹$price',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isEmergency ? Colors.red : AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 16),
            Radio<String>(
              value: value,
              groupValue: _selectedType,
              activeColor: isEmergency ? Colors.red : AppColors.primaryBlue,
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleProceed() async {
    setState(() => _isLoading = true);
    
    try {
      final profileService = context.read<ProfileService>();
      final walletBalance = profileService.currentUser?.walletBalance ?? 0;
      final fee = _selectedType == 'consultation' 
          ? widget.doctor.consultationFee 
          : widget.doctor.emergencyFee;

      if (walletBalance < fee) {
        if (mounted) {
          Navigator.pop(context); // Close sheet
          _showInsufficientBalanceDialog(context, fee, walletBalance);
        }
        return;
      }

      final success = await profileService.deductFromWallet(fee);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context); // Close sheet
          context.push('/patient/doctor/${widget.doctor.id}/call');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(profileService.error ?? 'Transaction failed')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showInsufficientBalanceDialog(BuildContext context, double required, double available) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insufficient Balance', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You need ₹$required for this consultation, but your wallet balance is ₹$available.'),
            const SizedBox(height: 16),
            Text('Please recharge your wallet to proceed.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/patient/profile/wallet');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Recharge Now'),
          ),
        ],
      ),
    );
  }
}
