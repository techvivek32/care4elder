import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/profile_service.dart';

class PatientMedicalInfoScreen extends StatefulWidget {
  const PatientMedicalInfoScreen({super.key});

  @override
  State<PatientMedicalInfoScreen> createState() => _PatientMedicalInfoScreenState();
}

class _PatientMedicalInfoScreenState extends State<PatientMedicalInfoScreen> {
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
  bool _loading = true;

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
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
      final p = ProfileService().currentUser;
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
          // Removed context.pop() to allow editing after save
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Medical Information', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        actions: [
          if (_saving)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
          else
            TextButton(onPressed: _save, child: const Text('SAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info
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
              // Surgeries
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
              // Medications
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
              _buildDocSection('Lab Reports', _labReports),
              const SizedBox(height: 12),
              _buildDocSection('Prescriptions', _prescriptions),
              const SizedBox(height: 12),
              _buildDocSection('Other Medical Documents', _additionalDocs),
              const SizedBox(height: 40),
            ],
          ),
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
            TextFormField(controller: row.purpose, decoration: const InputDecoration(labelText: 'Purpose / Frequency')),
          ],
        ),
      ),
    );
  }

  Widget _buildDocSection(String label, List<String> urls) {
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
