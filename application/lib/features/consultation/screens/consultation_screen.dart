import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/doctor_service.dart';

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final DoctorService _doctorService = DoctorService();
  Timer? _refreshTimer;

  final List<String> _categories = [
    'All',
    'General',
    'Cardiology',
    'Dermatology',
    'Neurology',
  ];

  @override
  void initState() {
    super.initState();
    // Ensure controller is available and add listener safely
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _loadDoctors();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _doctorService.fetchDoctors(silent: true);
      }
    });
  }

  Future<void> _loadDoctors() async {
    await _doctorService.fetchDoctors();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Find a Doctor',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book appointments with specialists',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() {}),
                            style: GoogleFonts.roboto(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Search doctors, specialization',
                              hintStyle: GoogleFonts.roboto(
                                color: colorScheme.onSurface.withOpacity(0.4),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? (Theme.of(context).brightness == Brightness.light
                                        ? AppColors.premiumGradient
                                        : AppColors.darkPremiumGradient)
                                    : null,
                                color: isSelected
                                    ? null
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colorScheme.primary.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.roboto(
                                  color: isSelected
                                      ? Colors.white
                                      : colorScheme.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _doctorService,
                builder: (context, child) {
                  if (_doctorService.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_doctorService.error != null) {
                    return Center(child: Text(_doctorService.error!, style: TextStyle(color: colorScheme.error)));
                  }

                  final filteredDoctors = _doctorService.doctors.where((doc) {
                    final matchesCategory =
                        _selectedCategory == 'All' ||
                        doc.specialization.contains(_selectedCategory) ||
                        (_selectedCategory == 'General' &&
                            doc.specialization.contains('General')) ||
                        (_selectedCategory == 'Cardiology' &&
                            doc.specialization.contains('Cardiolog'));
                            
                    final matchesSearch =
                        doc.name.toLowerCase().contains(
                          _searchController.text.toLowerCase(),
                        ) ||
                        doc.specialization.toLowerCase().contains(
                          _searchController.text.toLowerCase(),
                        );
                    return matchesCategory && matchesSearch;
                  }).toList();

                  if (filteredDoctors.isEmpty) {
                    return Center(
                      child: Text(
                        'No doctors found',
                        style: GoogleFonts.roboto(color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    itemCount: filteredDoctors.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final doctor = filteredDoctors[index];
                      return GestureDetector(
                        onTap: () =>
                            context.push('/patient/doctor/${doctor.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            gradient: Theme.of(context).brightness == Brightness.light
                                ? AppColors.premiumGradient
                                : AppColors.darkPremiumGradient,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(22.5),
                            ),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'doctor-${doctor.id}',
                                    child: Container(
                                      height: 80,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.shadow.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: doctor.profileImage.isNotEmpty
                                            ? Image.network(
                                                doctor.profileImage,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: colorScheme.surfaceContainerHighest,
                                                    child: Icon(
                                                      Icons.person,
                                                      color: colorScheme.onSurface.withOpacity(0.4),
                                                      size: 40,
                                                    ),
                                                  );
                                                },
                                              )
                                            : Container(
                                                color: colorScheme.surfaceContainerHighest,
                                                child: Icon(
                                                  Icons.person,
                                                  color: colorScheme.onSurface.withOpacity(0.4),
                                                  size: 40,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                doctor.name,
                                                style: GoogleFonts.roboto(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            Builder(
                                              builder: (context) {
                                                Color statusColor;
                                                String statusText;
                                                
                                                if (doctor.status == 'busy') {
                                                  statusColor = Colors.orange;
                                                  statusText = 'Busy';
                                                } else if (doctor.status == 'online' || (doctor.status == 'offline' && doctor.isAvailable)) {
                                                  statusColor = Colors.green;
                                                  statusText = 'Online';
                                                } else {
                                                  statusColor = Colors.grey;
                                                  statusText = 'Offline';
                                                }

                                                return Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    statusText,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          doctor.specialization,
                                          style: GoogleFonts.roboto(
                                            fontSize: 13,
                                            color: colorScheme.onSurface.withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${doctor.rating}',
                                              style: GoogleFonts.roboto(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                '•  ${doctor.experienceYears} years',
                                                style: GoogleFonts.roboto(
                                                  fontSize: 12,
                                                  color: colorScheme.onSurface.withOpacity(0.6),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Text(
                                              '₹${doctor.totalConsultationFee.toStringAsFixed(0)}',
                                              style: GoogleFonts.roboto(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
