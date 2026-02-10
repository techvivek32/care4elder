import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _reportController = TextEditingController(text: widget.callRequest.report);
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
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
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.single.path == null) {
        return;
      }

      final file = File(result.files.single.path!);
      
      setState(() => _isSaving = true);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading report file...')),
      );

      final token = await DoctorAuthService().getDoctorToken();
      if (token == null) return;

      final url = await _callService.uploadReportFile(token: token, file: file);
      
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
          // Ideally we update the local state to show the file is uploaded, 
          // but for now just showing success message.
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
    final callDate = DateFormat('MMM d, yyyy • h:mm a').format(widget.callRequest.createdAt.toLocal());
    final duration = '${(widget.callRequest.duration / 60).ceil()} min';

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

            // Call Stats
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: 'Date & Time',
                    value: callDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.timer,
                    label: 'Duration',
                    value: duration,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Report Section
            Text(
              'Consultation Report / Notes',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                  TextField(
                    controller: _reportController,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Enter diagnosis, prescription, or notes here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(20),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    onTap: _isSaving ? null : _uploadReportFile,
                    leading: const Icon(Icons.attach_file, color: AppColors.primaryBlue),
                    title: Text(
                      widget.callRequest.reportUrl.isNotEmpty 
                          ? 'Update Report File (File already uploaded)' 
                          : 'Attach Report File (PDF/Image)',
                      style: GoogleFonts.roboto(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: _isSaving 
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          ) 
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Save Report',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
