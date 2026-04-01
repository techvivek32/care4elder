import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
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

  String _resolvedDocumentUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final baseUrl = ApiConstants.baseUrl;
    final rootUrl = baseUrl.endsWith('/api')
        ? baseUrl.substring(0, baseUrl.length - 4)
        : baseUrl;
    if (!url.startsWith('/')) {
      return '$rootUrl/$url';
    }
    return '$rootUrl$url';
  }

  Future<void> _shareDocument(String url, String docTitle) async {
    final shareUrl = _resolvedDocumentUrl(url);
    if (shareUrl.isEmpty) return;
    try {
      await Share.share(shareUrl, subject: docTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e')),
        );
      }
    }
  }

  Future<void> _viewDocument(String url) async {
    final finalUrl = _resolvedDocumentUrl(url);

    final uri = Uri.parse(finalUrl);
    if (_isImageUrl(finalUrl)) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _InAppImageViewer(imageUrl: finalUrl),
        ),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );
      if (!opened) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open document: $finalUrl')),
        );
      }
    }
  }

  bool _isImageUrl(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.png') ||
        clean.endsWith('.jpg') ||
        clean.endsWith('.jpeg') ||
        clean.endsWith('.webp') ||
        clean.endsWith('.gif');
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
    final colorScheme = Theme.of(context).colorScheme;
    final profile = context.watch<ProfileService>().currentUser;
    if (profile != null && !identical(profile, _patient)) {
      // keep local snapshot fresh without changing behavior
      _patient = profile;
    }

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            _TopHeader(
              title: 'Medical Information',
              isEditing: _isEditing,
              isSaving: _saving,
              onBack: () => context.pop(),
              onEdit: () => setState(() => _isEditing = true),
              onSave: _save,
            ),
            Expanded(
              child: _isEditing ? _buildEditView() : _buildViewMode(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMode(bool isDark) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final patient = _patient!;
    final avatarUrl = patient.profilePictureUrl.trim().isNotEmpty
        ? patient.profilePictureUrl
        : null;
    final medsCount = patient.currentMedications.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('PATIENT PROFILE'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 22,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.surfaceContainerHighest,
                  image: avatarUrl != null
                      ? DecorationImage(image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: avatarUrl == null
                    ? Icon(Icons.person, color: colorScheme.onSurface.withOpacity(0.35))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniInfoCard(
                  label: 'Blood Group',
                  value: (patient.bloodGroup.isNotEmpty ? patient.bloodGroup : '—'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniInfoCard(
                  label: 'Gender',
                  value: (patient.gender?.isNotEmpty == true ? patient.gender! : '—'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WideInfoCard(
            label: 'Date of Birth',
            value: patient.dateOfBirth != null
                ? '${patient.dateOfBirth!.day}/${patient.dateOfBirth!.month}/${patient.dateOfBirth!.year}'
                : '—',
          ),
          const SizedBox(height: 18),

          _SectionTitleRow(
            icon: Icons.warning_amber_rounded,
            iconColor: colorScheme.error,
            title: 'Allergies',
          ),
          const SizedBox(height: 10),
          _MutedCard(
            child: Text(
              patient.allergies.isEmpty
                  ? 'No known allergies reported'
                  : patient.allergies,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ),
          const SizedBox(height: 18),

          _SectionTitleRow(
            icon: Icons.medication_outlined,
            iconColor: primary,
            title: 'Active Medications',
            trailing: medsCount > 0 ? _CountBadge(text: '$medsCount ACTIVE') : null,
          ),
          const SizedBox(height: 10),
          if (patient.currentMedications.isEmpty)
            _MutedCard(
              child: Text(
                'No active medications.',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          else
            ...patient.currentMedications.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MedicationCard(
                  name: m.name,
                  subtitle: (m.purpose?.isNotEmpty == true) ? m.purpose! : '—',
                ),
              );
            }),
          const SizedBox(height: 18),

          _SectionTitleRow(
            icon: Icons.history_rounded,
            iconColor: primary,
            title: 'Past Surgeries',
          ),
          const SizedBox(height: 10),
          if (patient.pastSurgeries.isEmpty)
            _MutedCard(
              child: Text(
                'No past surgeries.',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
          else
            ...patient.pastSurgeries.map((s) {
              final dateText = s.date != null
                  ? 'Performed on ${s.date!.day}/${s.date!.month}/${s.date!.year}'
                  : 'Performed on —';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SurgeryCard(
                  name: s.procedure.isNotEmpty ? s.procedure : '—',
                  subtitle: dateText,
                  canOpen: s.documentUrl != null && s.documentUrl!.isNotEmpty,
                  onView: s.documentUrl == null ? null : () => _viewDocument(s.documentUrl!),
                  onDownload: s.documentUrl == null ? null : () => _downloadDocument(s.documentUrl!),
                ),
              );
            }),
          const SizedBox(height: 18),

          _SectionTitleRow(
            icon: Icons.folder_open_outlined,
            iconColor: primary,
            title: 'Health Documents',
          ),
          const SizedBox(height: 10),
          ..._buildHealthDocsCards(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _buildHealthDocsCards() {
    final List<Widget> cards = [];
    void addCards(String label, IconData icon, List<String> urls) {
      for (int i = 0; i < urls.length; i++) {
        final url = urls[i];
        cards.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DocCard(
              icon: icon,
              title: '$label ${i + 1}',
              subtitle: 'Uploaded document',
              onOpen: () => _viewDocument(url),
              onShare: () => _shareDocument(url, '$label ${i + 1}'),
            ),
          ),
        );
      }
    }

    addCards('Prescriptions', Icons.description_outlined, _patient!.prescriptions);
    addCards('Laboratory Reports', Icons.science_outlined, _patient!.labReports);
    addCards('Other Documents', Icons.folder_open_outlined, _patient!.additionalDocuments);

    if (cards.isEmpty) {
      return [
        _MutedCard(
          child: Text(
            'No documents found.',
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ];
    }
    return cards;
  }

  // Legacy helpers still used in edit mode; keep as-is.

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

class _TopHeader extends StatelessWidget {
  final String title;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onSave;

  const _TopHeader({
    required this.title,
    required this.isEditing,
    required this.isSaving,
    required this.onBack,
    required this.onEdit,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          ),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (isEditing) ...[
            if (isSaving)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: onSave,
                child: Text(
                  'SAVE',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
          ] else
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit, color: colorScheme.onSurface),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideInfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _WideInfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  const _SectionTitleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String text;
  const _CountBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _MutedCard extends StatelessWidget {
  final Widget child;
  const _MutedCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: child,
    );
  }
}

class _MedicationCard extends StatelessWidget {
  final String name;
  final String subtitle;

  const _MedicationCard({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication_outlined, color: colorScheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
            ),
            child: Text(
              'DAILY',
              style: GoogleFonts.roboto(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurgeryCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool canOpen;
  final VoidCallback? onView;
  final VoidCallback? onDownload;

  const _SurgeryCard({
    required this.name,
    required this.subtitle,
    required this.canOpen,
    required this.onView,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: canOpen ? onView : null,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(color: colorScheme.outline.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: canOpen ? onDownload : null,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  const _DocCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onOpen,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Share',
                onPressed: onShare,
                icon: Icon(
                  Icons.share_outlined,
                  color: colorScheme.onSurface.withOpacity(0.55),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onOpen,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                foregroundColor: isDark ? Colors.white : colorScheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Open Document',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InAppImageViewer extends StatelessWidget {
  final String imageUrl;

  const _InAppImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load image',
                  style: GoogleFonts.roboto(
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
