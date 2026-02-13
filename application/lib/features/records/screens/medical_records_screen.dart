import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
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

  Future<void> _downloadFile(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http')) {
      final baseUrl = ApiConstants.baseUrl;
      final rootUrl = baseUrl.endsWith('/api') 
          ? baseUrl.substring(0, baseUrl.length - 4) 
          : baseUrl;
      
      if (!url.startsWith('/')) {
        finalUrl = '$rootUrl/$url';
      } else {
        finalUrl = '$rootUrl$url';
      }
    }

    final uri = Uri.parse(finalUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch file URL: $finalUrl')),
          );
        }
      }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.light
                ? AppColors.premiumGradient
                : AppColors.darkPremiumGradient,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Records',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Your health documents',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
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
                color: const Color(0xFF041E34),
                onTap: () {
                  final allPrescriptions = _records.expand((r) => r.prescriptions).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientCategoryFilesScreen(
                        title: 'Prescriptions',
                        files: allPrescriptions,
                        icon: Icons.description_outlined,
                        color: const Color(0xFF041E34),
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
                color: const Color(0xFF041E34),
                onTap: () {
                  final allLabReports = _records.expand((r) => r.labReports).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientCategoryFilesScreen(
                        title: 'Lab Reports',
                        files: allLabReports,
                        icon: Icons.science_outlined,
                        color: const Color(0xFF041E34),
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
                color: const Color(0xFF041E34),
                onTap: () {
                  final allMedicalDocs = _records.expand((r) => r.medicalDocuments).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientCategoryFilesScreen(
                        title: 'Medical Documents',
                        files: allMedicalDocs,
                        icon: Icons.folder_open_outlined,
                        color: const Color(0xFF041E34),
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
                ..._buildRecentRecordsList(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecentRecordsList() {
    List<Widget> items = [];
    
    for (var record in _records) {
      if (record.prescriptions.isNotEmpty) {
        items.add(_buildRecordItemWrapper(
          record,
          'Prescription',
          Icons.description_outlined,
          record.prescriptions,
          const Color(0xFF041E34),
        ));
      }
      if (record.labReports.isNotEmpty) {
        items.add(_buildRecordItemWrapper(
          record,
          'Lab Report',
          Icons.science_outlined,
          record.labReports,
          const Color(0xFF041E34),
        ));
      }
      if (record.medicalDocuments.isNotEmpty) {
        items.add(_buildRecordItemWrapper(
          record,
          'Medical Document',
          Icons.folder_open_outlined,
          record.medicalDocuments,
          const Color(0xFF041E34),
        ));
      }
    }
    
    return items.take(10).toList(); // Show up to 10 recent items
  }

  Widget _buildRecordItemWrapper(
    CallRequestData record, 
    String title, 
    IconData icon,
    List<String> files,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          if (files.length == 1) {
            _downloadFile(files.first);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientCategoryFilesScreen(
                  title: title,
                  files: files,
                  icon: icon,
                  color: color,
                ),
              ),
            );
          }
        },
        child: _buildRecentRecordItem(
          title: title,
          subtitle: '${DateFormat('MMM d, yyyy').format(record.createdAt)} • ${record.doctorName}',
          icon: icon,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isDarkMode
                        ? AppColors.darkPremiumGradient
                        : AppColors.premiumGradient,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: (isDarkMode ? Colors.blue : const Color(0xFF041E34))
                            .withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    count,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
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
                  gradient: isDarkMode
                      ? AppColors.darkPremiumGradient
                      : AppColors.premiumGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_upload_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Upload New Document',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'PDF, JPG, PNG up to 10MB',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.light
                  ? AppColors.premiumGradient
                  : AppColors.darkPremiumGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
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
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.light
                  ? AppColors.premiumGradient
                  : AppColors.darkPremiumGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download_rounded,
              color: Colors.white,
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
