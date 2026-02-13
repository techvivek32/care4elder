import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/call_request_service.dart';

class PatientRecordDetailScreen extends StatefulWidget {
  final CallRequestData callRequest;

  const PatientRecordDetailScreen({super.key, required this.callRequest});

  @override
  State<PatientRecordDetailScreen> createState() => _PatientRecordDetailScreenState();
}

class _PatientRecordDetailScreenState extends State<PatientRecordDetailScreen> {
  late List<String> _prescriptions;
  late List<String> _labReports;
  late List<String> _medicalDocuments;

  @override
  void initState() {
    super.initState();
    _prescriptions = List.from(widget.callRequest.prescriptions);
    _labReports = List.from(widget.callRequest.labReports);
    _medicalDocuments = List.from(widget.callRequest.medicalDocuments);
  }

  void _openCategoryFiles(String category, List<String> files) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PatientCategoryFilesScreen(
          title: category,
          files: files,
          icon: category == 'Prescriptions'
              ? Icons.description
              : category == 'Lab Reports'
                  ? Icons.science
                  : Icons.folder,
          color: category == 'Prescriptions'
              ? const Color(0xFF041E34)
              : category == 'Lab Reports'
                  ? const Color(0xFF041E34)
                  : const Color(0xFF041E34),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Consultation Details',
          style: GoogleFonts.roboto(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    backgroundImage: widget.callRequest.doctorProfileImage != null
                        ? NetworkImage(widget.callRequest.doctorProfileImage!)
                        : null,
                    child: widget.callRequest.doctorProfileImage == null
                        ? Text(
                            widget.callRequest.doctorName.substring(0, 1).toUpperCase(),
                            style: GoogleFonts.roboto(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.callRequest.doctorName,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Date: ${DateFormat('MMM d, yyyy').format(widget.callRequest.createdAt)}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Report Section
            Text(
              'Doctor\'s Report',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.08),
                ),
              ),
              child: Text(
                widget.callRequest.report.isEmpty 
                    ? 'No report added yet.' 
                    : widget.callRequest.report,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Attachments Section
            Text(
              'Attachments',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            _buildAttachmentCard(
              'Prescriptions',
              '${_prescriptions.length} files',
              Icons.description,
              const Color(0xFF041E34),
              () => _openCategoryFiles('Prescriptions', _prescriptions),
            ),
            const SizedBox(height: 12),
            _buildAttachmentCard(
              'Lab Reports',
              '${_labReports.length} files',
              Icons.science,
              const Color(0xFF041E34),
              () => _openCategoryFiles('Lab Reports', _labReports),
            ),
            const SizedBox(height: 12),
            _buildAttachmentCard(
              'Medical Documents',
              '${_medicalDocuments.length} files',
              Icons.folder,
              const Color(0xFF041E34),
              () => _openCategoryFiles('Medical Documents', _medicalDocuments),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentCard(
    String title,
    String count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    count,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class PatientCategoryFilesScreen extends StatefulWidget {
  final String title;
  final List<String> files;
  final IconData icon;
  final Color color;

  const PatientCategoryFilesScreen({
    super.key,
    required this.title,
    required this.files,
    required this.icon,
    required this.color,
  });

  @override
  State<PatientCategoryFilesScreen> createState() => _PatientCategoryFilesScreenState();
}

class _PatientCategoryFilesScreenState extends State<PatientCategoryFilesScreen> {
  Future<void> _downloadFile(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http')) {
      // Handle relative URLs
      final baseUrl = ApiConstants.baseUrl; // e.g., http://10.0.2.2:3000/api
      // Remove '/api' suffix if present to get root
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.roboto(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.onSurface.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.files.length} files',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Files List
            Expanded(
              child: widget.files.isEmpty
                  ? Center(
                      child: Text(
                        'No files in this category',
                        style: GoogleFonts.roboto(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.files.length,
                      itemBuilder: (context, index) {
                        final file = widget.files[index];
                        final fileName = file.split('/').last;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.insert_drive_file_outlined,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              fileName,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.download_rounded, color: Color(0xFF041E34)),
                              onPressed: () => _downloadFile(file),
                            ),
                          ),
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
