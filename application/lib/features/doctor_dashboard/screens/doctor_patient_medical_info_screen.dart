import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/file_download_service.dart';

class DoctorPatientMedicalInfoScreen extends StatelessWidget {
  final UserProfile patient;

  const DoctorPatientMedicalInfoScreen({super.key, required this.patient});

  Future<void> _downloadDocument(BuildContext context, String url) async {
    await FileDownloadService.downloadAndOpenFile(context, url);
  }

  Future<void> _viewDocument(BuildContext context, String url) async {
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open document: $finalUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Patient Medical Record', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            _buildSectionCard(
              isDark: isDark,
              title: 'Basic Clinical Info',
              icon: Icons.person_outline,
              content: Column(
                children: [
                  _buildInfoRow('Full Name', patient.fullName, isDark),
                  _buildInfoRow('Blood Group', patient.bloodGroup, isDark),
                  _buildInfoRow('Gender', patient.gender ?? '—', isDark),
                  _buildInfoRow('Location', patient.location, isDark),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medical History
            _buildSectionCard(
              isDark: isDark,
              title: 'General Health History',
              icon: Icons.history_edu,
              content: patient.medicalHistory.isEmpty
                  ? const Text('No history recorded.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: patient.medicalHistory.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 13)),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // Allergies
            _buildSectionCard(
              isDark: isDark,
              title: 'Allergies',
              icon: Icons.warning_amber,
              content: Text(patient.allergies.isEmpty ? 'None reported.' : patient.allergies),
            ),
            const SizedBox(height: 16),

            // Medications
            _buildSectionCard(
              isDark: isDark,
              title: 'Active Medications',
              icon: Icons.medication,
              content: patient.currentMedications.isEmpty
                  ? const Text('No active medications.')
                  : Column(
                      children: patient.currentMedications.map((m) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(m.purpose ?? '—', style: const TextStyle(fontSize: 12)),
                        leading: const Icon(Icons.circle, size: 8, color: Colors.green),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // Surgeries
            _buildSectionCard(
              isDark: isDark,
              title: 'Past Surgeries',
              icon: Icons.history,
              content: patient.pastSurgeries.isEmpty
                  ? const Text('No past surgeries.')
                  : Column(
                      children: patient.pastSurgeries.map((s) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkBackground.withOpacity(0.3) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.medical_services, color: AppColors.primaryBlue, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.procedure, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  if (s.date != null) 
                                    Text('${s.date!.day}/${s.date!.month}/${s.date!.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            if (s.documentUrl != null) ...[
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: ElevatedButton.icon(
                                  onPressed: () => _viewDocument(context, s.documentUrl!),
                                  icon: const Icon(Icons.visibility, size: 16),
                                  label: const Text('View'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: const Size(0, 32),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _downloadDocument(context, s.documentUrl!),
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Download'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(0, 32),
                                  textStyle: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )).toList(),
                    ),
            ),
            const SizedBox(height: 16),

            // Documents Section
            _buildDocSection(context, isDark, 'Prescriptions', patient.prescriptions),
            const SizedBox(height: 16),
            _buildDocSection(context, isDark, 'Laboratory Reports', patient.labReports),
            const SizedBox(height: 16),
            _buildDocSection(context, isDark, 'Other Medical Documents', patient.additionalDocuments),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required bool isDark, required String title, required IconData icon, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: AppColors.primaryBlue, size: 20), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const Divider(height: 24),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDocSection(BuildContext context, bool isDark, String label, List<String> urls) {
    return _buildSectionCard(
      isDark: isDark,
      title: label,
      icon: Icons.description_outlined,
      content: urls.isEmpty
          ? const Text('No documents found.', style: TextStyle(fontSize: 13, color: Colors.grey))
          : Column(
              children: urls.asMap().entries.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBackground.withOpacity(0.3) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$label ${e.key + 1}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                    // View Document Button
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _viewDocument(context, e.value),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('View'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    // Download Button
                    ElevatedButton.icon(
                      onPressed: () => _downloadDocument(context, e.value),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 32),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
    );
  }
}
