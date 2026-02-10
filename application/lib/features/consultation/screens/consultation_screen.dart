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
  }

  Future<void> _loadDoctors() async {
    await _doctorService.fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Book appointments with specialists',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Search doctors, specialization',
                              hintStyle: GoogleFonts.roboto(
                                color: AppColors.textGrey,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: AppColors.textGrey,
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
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                category,
                                style: GoogleFonts.roboto(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textGrey,
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
                    return Center(child: Text(_doctorService.error!));
                  }

                  final filteredDoctors = _doctorService.doctors.where((doc) {
                    final matchesCategory =
                        _selectedCategory == 'All' ||
                        // Check if specialization contains category or mapped category
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
                        style: GoogleFonts.roboto(color: AppColors.textGrey),
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
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey.shade100),
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
                              Hero(
                                tag: 'doctor-${doctor.id}',
                                child: SizedBox(
                                  height: 80,
                                  width: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: doctor.profileImage.isNotEmpty
                                        ? Image.network(
                                            doctor.profileImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.person,
                                                  color: Colors.grey,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          )
                                        : Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.grey,
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
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: doctor.isAvailable
                                                ? Colors.green.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.grey.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            doctor.isAvailable ? 'Online' : 'Offline',
                                            style: GoogleFonts.roboto(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: doctor.isAvailable
                                                  ? Colors.green
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      doctor.specialization,
                                      style: GoogleFonts.roboto(
                                        fontSize: 13,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
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
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '•  ${doctor.experienceYears} years',
                                            style: GoogleFonts.roboto(
                                              fontSize: 12,
                                              color: AppColors.textGrey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '₹${doctor.consultationFee}',
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryBlue,
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
