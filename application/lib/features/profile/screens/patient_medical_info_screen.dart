import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/file_download_service.dart';

class PatientMedicalInfoScreen extends StatefulWidget {
  const PatientMedicalInfoScreen({super.key});

  @override
  State<PatientMedicalInfoScreen> createState() => _PatientMedicalInfoScreenState();
}

class _PatientMedicalInfoScreenState extends State<PatientMedicalInfoScreen> {
  bool _loading = true;
  bool _isEditing = false;
  UserProfile? _patient;

  // Form fields
  final _formKey = GlobalKey<FormState>();
  DateTime? _dob;
  String? _gender;
  String? _bloodGroup;
  final _allergiesCtrl = TextEditingController();
  final _additionalInfoCtrl = TextEditingController();
  
  final List<_SurgeryRow> _surgeries = [];
  final List<_MedicationRow> _medications = [];
  final List<String> _additionalDocs = [];
  final List<String> _labReports = [];
  final List<String> _prescriptions = [];
  
  bool _hasSurgeries = false;
  bool _hasMedications = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await ProfileService().fetchProfile();
      final p = ProfileService().currentUser;
      if (p != null) {
        setState(() {
          _patient = p;
          _loadFormData(p);
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadFormData(UserProfile p) {
    _dob = p.dateOfBirth;
    _gender = p.gender;
    _bloodGroup = p.bloodGroup.isNotEmpty ? p.bloodGroup : null;
    _allergiesCtrl.text = p.allergies;
    _additionalInfoCtrl.text = p.additionalInfo ?? '';
    
    _surgeries.clear();
    for (final s in p.pastSurgeries) {
      _surgeries.add(_SurgeryRow(TextEditingController(text: s.procedure), s.date, s.documentUrl));
    }
    _hasSurgeries = _surgeries.isNotEmpty;

    _medications.clear();
    for (final m in p.currentMedications) {
      _medications.add(_MedicationRow(TextEditingController(text: m.name), TextEditingController(text: m.purpose ?? '')));
    }
    _hasMedications = _medications.isNotEmpty;

    _additionalDocs.clear();
    _additionalDocs.addAll(p.additionalDocuments);
    _labReports.clear();
    _labReports.addAll(p.labReports);
    _prescriptions.clear();
    _prescriptions.addAll(p.prescriptions);
  }

  Future<void> _downloadDocument(String url) async {
    await FileDownloadService.downloadAndOpenFile(context, url);
  }

  Future<void> _viewDocument(String url) async {
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
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open document: $finalUrl')),
        );
      }
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final initial = _dob ?? DateTime(now.year - 30, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _uploadDocForSurgery(int index) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) return;
    final file = result.files.single;
    final url = await ProfileService().uploadProfileImage(file);
    if (url != null) {
      setState(() => _surgeries[index].documentUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document uploaded')));
    }
  }

  Future<void> _uploadDoc(List<String> targetList, String label) async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null) return;
    final file = result.files.single;
    final url = await ProfileService().uploadProfileImage(file);
    if (url != null) {
      setState(() => targetList.add(url));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label uploaded')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final p = _patient;
      if (p == null) return;
      
      final surgeries = _hasSurgeries 
          ? _surgeries
            .where((s) => s.name.text.trim().isNotEmpty)
            .map((s) => PastSurgery(procedure: s.name.text.trim(), date: s.date, documentUrl: s.documentUrl))
            .toList()
          : <PastSurgery>[];

      final meds = _hasMedications
          ? _medications
            .where((m) => m.name.text.trim().isNotEmpty)
            .map((m) => Medication(name: m.name.text.trim(), purpose: m.purpose.text.trim().isEmpty ? null : m.purpose.text.trim()))
            .toList()
          : <Medication>[];

      final updated = p.copyWith(
        dateOfBirth: _dob,
        gender: _gender,
        bloodGroup: _bloodGroup ?? '',
        allergies: _allergiesCtrl.text.trim(),
        pastSurgeries: surgeries,
        currentMedications: meds,
        additionalInfo: _additionalInfoCtrl.text.trim().isEmpty ? null : _additionalInfoCtrl.text.trim(),
        additionalDocuments: List<String>.from(_additionalDocs),
        labReports: List<String>.from(_labReports),
        prescriptions: List<String>.from(_prescriptions),
      );

      final ok = await ProfileService().updateProfile(updated);
      if (mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved successfully')));
          setState(() {
            _patient = updated;
            _isEditing = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ProfileService().error ?? 'Failed to save')));
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_patient == null) return const Scaffold(body: Center(child: Text('No data')));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Medical Information', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_isEditing) ...[
            if (_saving)
              const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
            else
              TextButton(onPressed: _save, child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ] else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isEditing ? _buildEditView() : _buildViewMode(isDark),
    );
  }

  Widget _buildViewMode(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            isDark: isDark,
            title: 'Basic Clinical Info',
            icon: Icons.person_outline,
            content: Column(
              children: [
                _buildInfoRow('Full Name', _patient!.fullName, isDark),
                _buildInfoRow('Blood Group', _patient!.bloodGroup, isDark),
                _buildInfoRow('Gender', _patient!.gender ?? '—', isDark),
                _buildInfoRow('Date of Birth', _patient!.dateOfBirth != null ? '${_patient!.dateOfBirth!.day}/${_patient!.dateOfBirth!.month}/${_patient!.dateOfBirth!.year}' : '—', isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionCard(
            isDark: isDark,
            title: 'Allergies',
            icon: Icons.warning_amber,
            content: Text(_patient!.allergies.isEmpty ? 'None reported.' : _patient!.allergies),
          ),
          const SizedBox(height: 16),

          _buildSectionCard(
            isDark: isDark,
            title: 'Active Medications',
            icon: Icons.medication,
            content: _patient!.currentMedications.isEmpty
                ? const Text('No active medications.')
                : Column(
                    children: _patient!.currentMedications.map((m) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(m.purpose ?? '—', style: const TextStyle(fontSize: 12)),
                      leading: const Icon(Icons.circle, size: 8, color: Colors.green),
                    )).toList(),
                  ),
          ),
          const SizedBox(height: 16),

          _buildSectionCard(
            isDark: isDark,
            title: 'Past Surgeries',
            icon: Icons.history,
            content: _patient!.pastSurgeries.isEmpty
                ? const Text('No past surgeries.')
                : Column(
                    children: _patient!.pastSurgeries.map((s) => Container(
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
                                onPressed: () => _viewDocument(s.documentUrl!),
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
                              onPressed: () => _downloadDocument(s.documentUrl!),
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

          _buildDocSection(isDark, 'Prescriptions', _patient!.prescriptions),
          const SizedBox(height: 16),
          _buildDocSection(isDark, 'Laboratory Reports', _patient!.labReports),
          const SizedBox(height: 16),
          _buildDocSection(isDark, 'Other Medical Documents', _patient!.additionalDocuments),
          
          const SizedBox(height: 40),
        ],
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
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDocSection(bool isDark, String label, List<String> urls) {
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
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ElevatedButton.icon(
                        onPressed: () => _viewDocument(e.value),
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
                      onPressed: () => _downloadDocument(e.value),
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

  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Basic Information'),
            InkWell(
              onTap: _pickDob,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.cake_outlined)),
                child: Text(_dob != null ? '${_dob!.day}/${_dob!.month}/${_dob!.year}' : 'Select Date'),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.person_outline)),
              items: ['Male', 'Female', 'Other', 'Prefer not to say'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group', prefixIcon: Icon(Icons.bloodtype_outlined)),
              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _bloodGroup = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _allergiesCtrl,
              decoration: const InputDecoration(labelText: 'Allergies', prefixIcon: Icon(Icons.warning_amber_outlined)),
              maxLines: 2,
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Past Surgeries'),
                Switch(
                  value: _hasSurgeries,
                  onChanged: (v) => setState(() {
                    _hasSurgeries = v;
                    if (v && _surgeries.isEmpty) _surgeries.add(_SurgeryRow(TextEditingController(), null, null));
                  }),
                ),
              ],
            ),
            if (_hasSurgeries) ...[
              ..._surgeries.asMap().entries.map((e) => _buildSurgeryItem(e.key, e.value)),
              TextButton.icon(onPressed: () => setState(() => _surgeries.add(_SurgeryRow(TextEditingController(), null, null))), icon: const Icon(Icons.add), label: const Text('Add Surgery')),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Active Medications'),
                Switch(
                  value: _hasMedications,
                  onChanged: (v) => setState(() {
                    _hasMedications = v;
                    if (v && _medications.isEmpty) _medications.add(_MedicationRow(TextEditingController(), TextEditingController()));
                  }),
                ),
              ],
            ),
            if (_hasMedications) ...[
              ..._medications.asMap().entries.map((e) => _buildMedicationItem(e.key, e.value)),
              TextButton.icon(onPressed: () => setState(() => _medications.add(_MedicationRow(TextEditingController(), TextEditingController()))), icon: const Icon(Icons.add), label: const Text('Add Medication')),
            ],

            const SizedBox(height: 24),
            _buildSectionTitle('Documents & Additional Info'),
            TextFormField(
              controller: _additionalInfoCtrl,
              decoration: const InputDecoration(labelText: 'Additional Medical Information'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildDocEditSection('Lab Reports', _labReports),
            const SizedBox(height: 12),
            _buildDocEditSection('Prescriptions', _prescriptions),
            const SizedBox(height: 12),
            _buildDocEditSection('Other Medical Documents', _additionalDocs),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
    );
  }

  Widget _buildSurgeryItem(int index, _SurgeryRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextFormField(controller: row.name, decoration: const InputDecoration(labelText: 'Surgery Name'))),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _surgeries.removeAt(index))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: row.date ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
                      if (picked != null) setState(() => row.date = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Text(row.date != null ? '${row.date!.day}/${row.date!.month}/${row.date!.year}' : 'Select Date'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _uploadDocForSurgery(index),
                  icon: Icon(row.documentUrl != null ? Icons.check_circle : Icons.upload_file),
                  label: Text(row.documentUrl != null ? 'Uploaded' : 'Upload Doc'),
                  style: TextButton.styleFrom(foregroundColor: row.documentUrl != null ? Colors.green : AppColors.primaryBlue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationItem(int index, _MedicationRow row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: TextFormField(controller: row.name, decoration: const InputDecoration(labelText: 'Medicine Name'))),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _medications.removeAt(index))),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(controller: row.purpose, decoration: const InputDecoration(labelText: 'Purpose / Frequency')),
          ],
        ),
      ),
    );
  }

  Widget _buildDocEditSection(String label, List<String> urls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...urls.asMap().entries.map((e) => Chip(
              label: Text('Doc ${e.key + 1}', style: const TextStyle(fontSize: 12)),
              onDeleted: () => setState(() => urls.removeAt(e.key)),
            )),
            ActionChip(
              avatar: const Icon(Icons.add, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 12)),
              onPressed: () => _uploadDoc(urls, label),
            ),
          ],
        ),
      ],
    );
  }
}

class _SurgeryRow {
  final TextEditingController name;
  DateTime? date;
  String? documentUrl;
  _SurgeryRow(this.name, this.date, this.documentUrl);
}

class _MedicationRow {
  final TextEditingController name;
  final TextEditingController purpose;
  _MedicationRow(this.name, this.purpose);
}
