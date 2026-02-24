import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/doctor_patient_service.dart';
import '../../../core/services/profile_service.dart';

class DoctorRequestDetailsScreen extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic>? requestData;

  const DoctorRequestDetailsScreen({
    super.key,
    required this.requestId,
    this.requestData,
  });

  @override
  State<DoctorRequestDetailsScreen> createState() => _DoctorRequestDetailsScreenState();
}

class _DoctorRequestDetailsScreenState extends State<DoctorRequestDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserProfile? _patientProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadPatientData();
  }

  Future<void> _loadPatientData() async {
    final patientId = widget.requestData?['patientId'] as String?;
    if (patientId != null) {
      final profile = await DoctorPatientService().fetchPatientById(patientId);
      if (mounted) {
        setState(() {
          _patientProfile = profile;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime? dob) {
    if (dob == null) return 0;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _downloadDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasData = widget.requestData != null && widget.requestData!.isNotEmpty;
    final patientName = _patientProfile?.fullName ?? (hasData ? (widget.requestData!['name'] ?? '') : "Sarah Johnson");
    final age = _patientProfile?.dateOfBirth != null ? "${_calculateAge(_patientProfile!.dateOfBirth)} yrs" : "—";
    final gender = _patientProfile?.gender ?? "—";
    final bloodType = _patientProfile?.bloodGroup ?? "—";
    final time = hasData ? (widget.requestData!['time'] ?? '') : "—";
    final isVideo = hasData ? (widget.requestData!['type'] == 'Video Call') : true;

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.textDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Request Details',
          style: GoogleFonts.roboto(
            color: isDark ? Colors.white : AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primaryBlue,
          labelColor: isDark ? Colors.white : AppColors.primaryBlue,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Patient Info'),
            Tab(text: 'Medical Info'),
            Tab(text: 'Prescription'),
            Tab(text: 'Lab Report'),
            Tab(text: 'Medical Documentation'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPatientInfoTab(isDark, patientName, age, gender, bloodType, isVideo, time),
          _buildMedicalInfoTab(isDark),
          _buildDocumentsTab(isDark, 'Prescription', _patientProfile?.prescriptions ?? []),
          _buildDocumentsTab(isDark, 'Lab Report', _patientProfile?.labReports ?? []),
          _buildDocumentsTab(isDark, 'Medical Documentation', _patientProfile?.additionalDocuments ?? []),
        ],
      ),
    );
  }

  Widget _buildPatientInfoTab(bool isDark, String name, String age, String gender, String bloodType, bool isVideo, String time) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 30, backgroundColor: AppColors.primaryBlue.withOpacity(0.1), child: const Icon(Icons.person, size: 30, color: AppColors.primaryBlue)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                      const SizedBox(height: 4),
                      Text('$age • $gender • $bloodType', style: GoogleFonts.roboto(fontSize: 14, color: isDark ? Colors.white60 : AppColors.textGrey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Prominent Medical Information Section (as requested)
          _buildSectionCard(
            isDark: isDark,
            title: 'Medical Information Menu',
            icon: Icons.medical_services_outlined,
            iconColor: AppColors.primaryBlue,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Current Status', 'Active Request', isDark),
                _buildInfoRow('Age', age, isDark),
                _buildInfoRow('Blood Group', bloodType, isDark),
                _buildInfoRow('Location', _patientProfile?.location ?? '—', isDark),
                const Divider(height: 24),
                _buildMedicalMenuButton(context, 'Patient Medical History', Icons.history, () => _tabController.animateTo(1)),
                _buildMedicalMenuButton(context, 'Prescriptions & Medication', Icons.medication_outlined, () => _tabController.animateTo(2)),
                _buildMedicalMenuButton(context, 'Laboratory Reports', Icons.microscope_outlined, () => _tabController.animateTo(3)),
                _buildMedicalMenuButton(context, 'Other Medical Documentation', Icons.description_outlined, () => _tabController.animateTo(4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            isDark: isDark,
            title: 'Consultation Detail',
            icon: isVideo ? Icons.videocam : Icons.phone,
            iconColor: AppColors.primaryBlue,
            content: Column(
              children: [
                _buildInfoRow('Type', isVideo ? 'Video Call' : 'Voice Call', isDark),
                _buildInfoRow('Time', time, isDark),
                _buildInfoRow('Symptoms', widget.requestData?['symptom'] ?? '—', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalMenuButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoTab(bool isDark) {
    if (_patientProfile == null) return const Center(child: Text('No medical data available.'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(isDark: isDark, title: 'Allergies', icon: Icons.warning_amber, iconColor: Colors.orange, content: Text(_patientProfile!.allergies.isEmpty ? 'None reported.' : _patientProfile!.allergies)),
          const SizedBox(height: 16),
          _buildSectionCard(
            isDark: isDark,
            title: 'Current Medications',
            icon: Icons.medication,
            iconColor: Colors.green,
            content: _patientProfile!.currentMedications.isEmpty
                ? const Text('No active medications.')
                : Column(children: _patientProfile!.currentMedications.map((m) => _buildInfoRow(m.name, m.purpose ?? '—', isDark)).toList()),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            isDark: isDark,
            title: 'Past Surgeries',
            icon: Icons.history,
            iconColor: Colors.purple,
            content: _patientProfile!.pastSurgeries.isEmpty
                ? const Text('No past surgeries reported.')
                : Column(
                    children: _patientProfile!.pastSurgeries.map((s) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.procedure, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      subtitle: s.date != null ? Text('${s.date!.day}/${s.date!.month}/${s.date!.year}') : null,
                      trailing: s.documentUrl != null ? IconButton(icon: const Icon(Icons.download), onPressed: () => _downloadDocument(s.documentUrl!)) : null,
                    )).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab(bool isDark, String label, List<String> urls) {
    if (urls.isEmpty) return Center(child: Text('No $label found.'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: urls.length,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const Icon(Icons.description, color: AppColors.primaryBlue),
          title: Text('$label ${index + 1}'),
          trailing: const Icon(Icons.download),
          onTap: () => _downloadDocument(urls[index]),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required bool isDark, required String title, required IconData icon, required Color iconColor, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: iconColor, size: 20), const SizedBox(width: 8), Text(title, style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
