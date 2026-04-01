import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/patient_side_menu.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/call_request_service.dart';
import '../../../core/services/profile_service.dart';
import 'patient_record_detail_screen.dart';
import 'dart:ui';

class MedicalRecordsScreen extends StatefulWidget {
  final String? initialCategory;
  const MedicalRecordsScreen({super.key, this.initialCategory});

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
          _openInitialCategoryIfNeeded();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error fetching records: $e');
    }
  }

  void _openInitialCategoryIfNeeded() {
    if (widget.initialCategory == null || _records.isEmpty) return;
    final open = widget.initialCategory!.toLowerCase();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (open == 'prescriptions') {
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
      }
    });
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileImageUrl =
        context.watch<ProfileService>().currentUser?.profilePictureUrl;
    
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
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF6F8FB),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchRecords,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopHeader(
                        avatarUrl: (profileImageUrl != null &&
                                profileImageUrl.trim().isNotEmpty)
                            ? profileImageUrl
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Health Vault',
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          height: 1.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F4AA8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your health history, secured and simplified.',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withOpacity(0.62),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryCard(
                        title: 'Lab Reports',
                        count: '$labReportsCount files updated recently',
                        icon: Icons.science_outlined,
                        color: const Color(0xFF0F4AA8),
                        large: true,
                        onTap: () {
                          final allLabReports =
                              _records.expand((r) => r.labReports).toList();
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCategoryCard(
                              title: 'Prescriptions',
                              count: '$prescriptionsCount active files',
                              icon: Icons.description_outlined,
                              color: const Color(0xFF0F4AA8),
                              onTap: () {
                                final allPrescriptions =
                                    _records.expand((r) => r.prescriptions).toList();
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildCategoryCard(
                              title: 'Documents',
                              count: '$medicalDocsCount archived files',
                              icon: Icons.folder_open_outlined,
                              color: const Color(0xFF0F4AA8),
                              onTap: () {
                                final allMedicalDocs = _records
                                    .expand((r) => r.medicalDocuments)
                                    .toList();
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Entries',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 14),
                      _buildSecurityBanner(),
                      const SizedBox(height: 12),
                    ],
                  ),
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
    bool large = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFEAF0FC);

    return Container(
      constraints: BoxConstraints(minHeight: large ? 96 : 92),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(large ? 14 : 10),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(large ? 9 : 8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: large ? 18 : 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: large ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: large ? 14 : 12,
                          height: 1.05,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        count,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (large)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.28),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest
                  : const Color(0xFFEAF0FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.58),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download_rounded,
              color: colorScheme.primary.withOpacity(0.9),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader({String? avatarUrl}) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = Theme.of(context).brightness == Brightness.dark
        ? colorScheme.primary
        : const Color(0xFF1565C0);
    return Row(
      children: [
        InkWell(
          onTap: () => openPatientSideMenu(context),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.menu, color: colorScheme.onSurface, size: 22),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Health Vault',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/patient/profile'),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, color: colorScheme.onSurface, size: 18)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 10, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1E6CD6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data is\nencrypted and\nsecure.',
                  style: GoogleFonts.roboto(
                    fontSize: 31,
                    height: 0.9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: Colors.white.withOpacity(0.92),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Your Data Is Safe With Us!',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Icon(
              Icons.shield_outlined,
              color: Colors.white.withOpacity(0.22),
              size: 88,
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
