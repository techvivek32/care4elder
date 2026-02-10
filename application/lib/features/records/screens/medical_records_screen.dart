import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/call_request_service.dart';
import 'patient_record_detail_screen.dart';
import 'dart:ui';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  bool _isLoading = true;
  List<CallRequestData> _records = [];
  final CallRequestService _callRequestService = CallRequestService();

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    try {
      final token = await AuthService().getToken();
      if (token != null) {
        final records = await _callRequestService.getPatientHistory(token: token);
        if (mounted) {
          setState(() {
            _records = records;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error fetching records: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate counts
    int prescriptionsCount = 0;
    int labReportsCount = 0;
    int medicalDocsCount = 0;

    for (var record in _records) {
      prescriptionsCount += record.prescriptions.length;
      labReportsCount += record.labReports.length;
      medicalDocsCount += record.medicalDocuments.length;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Records',
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your health documents',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: AppColors.textGrey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        toolbarHeight: 80,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchRecords,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryCard(
                title: 'Prescriptions',
                count: '$prescriptionsCount files',
                icon: Icons.description_outlined,
                color: Colors.blue,
                onTap: () {
                  final allPrescriptions = _records.expand((r) => r.prescriptions).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientCategoryFilesScreen(
                        title: 'Prescriptions',
                        files: allPrescriptions,
                        icon: Icons.description_outlined,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCategoryCard(
                title: 'Lab Reports',
                count: '$labReportsCount files',
                icon: Icons.science_outlined,
                color: Colors.green,
                onTap: () {
                  final allLabReports = _records.expand((r) => r.labReports).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientCategoryFilesScreen(
                        title: 'Lab Reports',
                        files: allLabReports,
                        icon: Icons.science_outlined,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildCategoryCard(
                title: 'Medical Documents',
                count: '$medicalDocsCount files',
                icon: Icons.folder_open_outlined,
                color: Colors.orange,
                onTap: () {
                  final allMedicalDocs = _records.expand((r) => r.medicalDocuments).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientCategoryFilesScreen(
                        title: 'Medical Documents',
                        files: allMedicalDocs,
                        icon: Icons.folder_open_outlined,
                        color: Colors.orange,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Recent Records',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              if (_records.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'No records found',
                      style: GoogleFonts.roboto(color: AppColors.textGrey),
                    ),
                  ),
                )
              else
                ..._records.take(5).map((record) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientRecordDetailScreen(callRequest: record),
                        ),
                      );
                    },
                    child: _buildRecentRecordItem(
                      title: 'Consultation Report',
                      subtitle: '${DateFormat('MMM d, yyyy').format(record.createdAt)} • ${record.doctorName}',
                      icon: Icons.description_outlined,
                    ),
                  ),
                )),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
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
                  Text(
                    count,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: Colors.blue.withValues(alpha: 0.4),
          strokeWidth: 2,
          radius: 20,
          gap: 6,
          dash: 6,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload New Document',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PDF, JPG, PNG up to 10MB',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRecordItem({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 24),
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
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              // shape: BoxShape.circle, // Duplicate
            ),
            child: const Icon(
              Icons.download_rounded,
              color: Colors.blue,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double gap;
  final double dash;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.radius = 0.0,
    this.gap = 5.0,
    this.dash = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    Path dashedPath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
