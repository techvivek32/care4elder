import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/call_request_service.dart';
import '../../doctor_auth/services/doctor_auth_service.dart';
import 'package:intl/intl.dart';

class DoctorHistoryDetailScreen extends StatefulWidget {
  final CallRequestData callRequest;

  const DoctorHistoryDetailScreen({super.key, required this.callRequest});

  @override
  State<DoctorHistoryDetailScreen> createState() => _DoctorHistoryDetailScreenState();
}

class _DoctorHistoryDetailScreenState extends State<DoctorHistoryDetailScreen> {
  late TextEditingController _reportController;
  final CallRequestService _callService = CallRequestService();
  bool _isSaving = false;
  
  late List<String> _prescriptions;
  late List<String> _labReports;
  late List<String> _medicalDocuments;

  @override
  void initState() {
    super.initState();
    _reportController = TextEditingController(text: widget.callRequest.report);
    _prescriptions = List.from(widget.callRequest.prescriptions);
    _labReports = List.from(widget.callRequest.labReports);
    _medicalDocuments = List.from(widget.callRequest.medicalDocuments);
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _openCategoryFiles(String category, List<String> currentList) async {
    final updatedList = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (context) => DoctorCategoryFilesScreen(
          title: category,
          files: currentList,
          callRequestId: widget.callRequest.id,
          icon: category == 'Prescriptions'
              ? Icons.description
              : category == 'Lab Reports'
                  ? Icons.science
                  : Icons.folder,
          color: category == 'Prescriptions'
              ? const Color(0xFF2196F3)
              : category == 'Lab Reports'
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF9800),
          category: category,
        ),
      ),
    );

    if (updatedList != null && mounted) {
      setState(() {
        if (category == 'Prescriptions') _prescriptions = updatedList;
        if (category == 'Lab Reports') _labReports = updatedList;
        if (category == 'Medical Documents') _medicalDocuments = updatedList;
      });
    }
  }

  Future<void> _saveReport() async {
    setState(() => _isSaving = true);
    final token = await DoctorAuthService().getDoctorToken();
    if (token != null) {
      final success = await _callService.updateCallReport(
        token: token,
        callRequestId: widget.callRequest.id,
        report: _reportController.text,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report saved successfully')),
          );
          context.pop(true); // Return true to indicate update
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save report')),
          );
        }
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _uploadReportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.any,
      );
      if (result == null) return;
      
      final bytes = result.files.single.bytes;
      final name = result.files.single.name;
      
      if (bytes == null) {
        throw Exception('Failed to read file data');
      }
      
      setState(() => _isSaving = true);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading report file...')),
      );

      final token = await DoctorAuthService().getDoctorToken();
      if (token == null) return;

      final url = await _callService.uploadReportFile(
        token: token, 
        bytes: bytes,
        filename: name,
      );
      
      if (url != null) {
        final success = await _callService.updateCallReport(
          token: token,
          callRequestId: widget.callRequest.id,
          reportUrl: url,
        );

        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report file uploaded successfully')),
          );
        } else {
          throw Exception('Failed to update record');
        }
      } else {
        throw Exception('Failed to upload file');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.callRequest.patientName;
    final patientAge = widget.callRequest.patientDob != null 
        ? (DateTime.now().difference(widget.callRequest.patientDob!).inDays / 365).floor().toString() 
        : 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Consultation Details',
          style: GoogleFonts.roboto(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: widget.callRequest.patientProfile.isNotEmpty
                        ? NetworkImage(widget.callRequest.patientProfile)
                        : const AssetImage('assets/images/logo.png') as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Age: $patientAge • ${widget.callRequest.patientLocation}',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            _buildCategoryCard(
              title: 'Prescriptions',
              count: _prescriptions.length,
              icon: Icons.description,
              color: const Color(0xFF2196F3), // Blue
              onTap: () => _openCategoryFiles('Prescriptions', _prescriptions),
            ),
            const SizedBox(height: 16),
            _buildCategoryCard(
              title: 'Lab Reports',
              count: _labReports.length,
              icon: Icons.science,
              color: const Color(0xFF4CAF50), // Green
              onTap: () => _openCategoryFiles('Lab Reports', _labReports),
            ),
            const SizedBox(height: 16),
            _buildCategoryCard(
              title: 'Medical Documents',
              count: _medicalDocuments.length,
              icon: Icons.folder,
              color: const Color(0xFFFF9800), // Orange
              onTap: () => _openCategoryFiles('Medical Documents', _medicalDocuments),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isSaving ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count files',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorCategoryFilesScreen extends StatefulWidget {
  final String title;
  final List<String> files;
  final String callRequestId;
  final IconData icon;
  final Color color;
  final String category;

  const DoctorCategoryFilesScreen({
    super.key,
    required this.title,
    required this.files,
    required this.callRequestId,
    required this.icon,
    required this.color,
    required this.category,
  });

  @override
  State<DoctorCategoryFilesScreen> createState() => _DoctorCategoryFilesScreenState();
}

class _DoctorCategoryFilesScreenState extends State<DoctorCategoryFilesScreen> {
  late List<String> _files;
  bool _isUploading = false;
  final CallRequestService _callService = CallRequestService();

  @override
  void initState() {
    super.initState();
    _files = List.from(widget.files);
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
        allowMultiple: false,
      );
      
      if (result == null) return;
      
      final bytes = result.files.single.bytes;
      final name = result.files.single.name;
      
      if (bytes == null) {
        throw Exception('Failed to read file data');
      }
      
      setState(() => _isUploading = true);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading file...')),
      );

      final token = await DoctorAuthService().getDoctorToken();
      if (token == null) return;

      final url = await _callService.uploadReportFile(
        token: token, 
        bytes: bytes,
        filename: name,
      );
      
      if (url != null) {
        final newList = List<String>.from(_files)..add(url);
        
        bool success = false;
        if (widget.category == 'Prescriptions') {
          success = await _callService.updateCallReport(
            token: token,
            callRequestId: widget.callRequestId,
            prescriptions: newList,
          );
        } else if (widget.category == 'Lab Reports') {
          success = await _callService.updateCallReport(
            token: token,
            callRequestId: widget.callRequestId,
            labReports: newList,
          );
        } else if (widget.category == 'Medical Documents') {
          success = await _callService.updateCallReport(
            token: token,
            callRequestId: widget.callRequestId,
            medicalDocuments: newList,
          );
        }

        if (success) {
          setState(() => _files = newList);
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully')),
          );
        } else {
          throw Exception('Failed to update record');
        }
      } else {
        throw Exception('Failed to upload file');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteFile(int index) async {
    final fileUrl = _files[index];
    final newList = List<String>.from(_files)..removeAt(index);
    
    setState(() => _isUploading = true);
    
    try {
      final token = await DoctorAuthService().getDoctorToken();
      if (token == null) return;

      bool success = false;
      if (widget.category == 'Prescriptions') {
        success = await _callService.updateCallReport(
          token: token,
          callRequestId: widget.callRequestId,
          prescriptions: newList,
        );
      } else if (widget.category == 'Lab Reports') {
        success = await _callService.updateCallReport(
          token: token,
          callRequestId: widget.callRequestId,
          labReports: newList,
        );
      } else if (widget.category == 'Medical Documents') {
        success = await _callService.updateCallReport(
          token: token,
          callRequestId: widget.callRequestId,
          medicalDocuments: newList,
        );
      }

      if (success) {
        setState(() => _files = newList);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File deleted successfully')),
          );
        }
      } else {
        throw Exception('Failed to delete file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
      // Fallback: try launching without checking canLaunchUrl (sometimes required for specific schemes)
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_files);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text(
            widget.title,
            style: GoogleFonts.roboto(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(_files),
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
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_files.length} files',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upload Area
              InkWell(
                onTap: _isUploading ? null : _uploadFile,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F7FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF90CAF9),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primaryBlue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Upload New Document',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload any file format (Video, PDF, Image, etc)',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_isUploading) ...[
                        const SizedBox(height: 16),
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // File List
              Expanded(
                child: ListView.separated(
                  itemCount: _files.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final fileUrl = _files[index];
                    final fileName = fileUrl.split('/').last;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined, color: Colors.grey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fileName,
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.download_rounded, color: AppColors.primaryBlue),
                            onPressed: () => _downloadFile(fileUrl),
                            tooltip: 'Download',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteFile(index),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
