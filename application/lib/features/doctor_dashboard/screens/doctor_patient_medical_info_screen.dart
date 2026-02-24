import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/profile_service.dart';

class DoctorPatientMedicalInfoScreen extends StatelessWidget {
  final UserProfile patient;

  const DoctorPatientMedicalInfoScreen({super.key, required this.patient});

  Future<void> _downloadDocument(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open document')),
      );
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
                      children: patient.pastSurgeries.map((s) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.procedure, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: s.date != null ? Text('${s.date!.day}/${s.date!.month}/${s.date!.year}') : null,
                        trailing: s.documentUrl != null 
                          ? IconButton(icon: const Icon(Icons.download, color: AppColors.primaryBlue), onPressed: () => _downloadDocument(context, s.documentUrl!))
                          : null,
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
              children: urls.asMap().entries.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                title: Text('$label ${e.key + 1}', style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.download, color: AppColors.primaryBlue),
                onTap: () => _downloadDocument(context, e.value),
              )).toList(),
            ),
    );
  }
}
