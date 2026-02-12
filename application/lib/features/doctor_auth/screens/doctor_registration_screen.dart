import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../services/doctor_auth_service.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() =>
      _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedSpecialization;
  bool _lockEmail = false;
  bool _lockPhone = false;

  // File states
  PlatformFile? _medicalCertificateFile;
  PlatformFile? _idProofFile;
  bool _isUploadingMedical = false;
  bool _isUploadingId = false;

  bool _isLoading = false;

  final List<String> _specializations = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Orthopedist',
    'Pediatrician',
    'Neurologist',
    'Psychiatrist',
    'Gynecologist',
  ];

  @override
  void initState() {
    super.initState();
    final data = DoctorAuthService().registrationData;
    if (data.email != null) {
      _emailController.text = data.email!;
      _lockEmail = data.email!.isNotEmpty;
    }
    if (data.phoneNumber != null) {
      _phoneController.text = data.phoneNumber!;
      _lockPhone = data.phoneNumber!.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    _hospitalController.dispose();
    _idNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isMedical) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png'],
        withData: true, // Needed for preview if we want to show image bytes
      );

      if (result != null) {
        final file = result.files.first;

        // Validate file size (max 5MB)
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File size must be less than 5MB')),
            );
          }
          return;
        }

        setState(() {
          if (isMedical) {
            _isUploadingMedical = true;
          } else {
            _isUploadingId = true;
          }
        });

        // Simulate upload delay
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          if (isMedical) {
            _medicalCertificateFile = file;
            _isUploadingMedical = false;
          } else {
            _idProofFile = file;
            _isUploadingId = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
      setState(() {
        _isUploadingMedical = false;
        _isUploadingId = false;
      });
    }
  }

  void _removeFile(bool isMedical) {
    setState(() {
      if (isMedical) {
        _medicalCertificateFile = null;
      } else {
        _idProofFile = null;
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      if (_medicalCertificateFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload your Medical Certificate'),
          ),
        );
        return;
      }
      if (_idProofFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload your ID Proof')),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // Simulate processing delay
        await Future.delayed(const Duration(seconds: 1));

        // Prepare documents list
        final documents = <PlatformFile>[];
        if (_medicalCertificateFile != null) {
          documents.add(_medicalCertificateFile!);
        }
        if (_idProofFile != null) {
          documents.add(_idProofFile!);
        }

        // Legacy paths (keeping for backward compatibility or if needed by UI elsewhere)
        final paths = <String>[];
        if (kIsWeb) {
          if (_medicalCertificateFile != null) {
            paths.add(_medicalCertificateFile!.name);
          }
          if (_idProofFile != null) {
            paths.add(_idProofFile!.name);
          }
        } else {
          if (_medicalCertificateFile?.path != null) {
            paths.add(_medicalCertificateFile!.path!);
          }
          if (_idProofFile?.path != null) {
            paths.add(_idProofFile!.path!);
          }
        }

        DoctorAuthService().updateRegistrationData(
          fullName: _fullNameController.text,
          password: _passwordController.text,
          medicalRegistrationNumber: _licenseController.text,
          idNumber: _idNumberController.text,
          specialization: _selectedSpecialization,
          experienceYears: _experienceController.text,
          hospitalAffiliation: _hospitalController.text,
          // Also update contact info in case it was modified
          email: _emailController.text.isNotEmpty
              ? _emailController.text
              : null,
          phoneNumber: _phoneController.text.isNotEmpty
              ? _phoneController.text
              : null,
          documentPaths: paths,
          documents: documents,
        );

        if (mounted) {
          context.push('/doctor/summary');
        }
      } catch (e, stackTrace) {
        debugPrint('Error submitting form: $e');
        debugPrint(stackTrace.toString());
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error processing data: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Doctor Registration',
          style: GoogleFonts.roboto(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Personal Information'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Dr. John Doe',
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your full name'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'doctor@example.com',
                  keyboardType: TextInputType.emailAddress,
                  readOnly: _lockEmail,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '+919876543210',
                  keyboardType: TextInputType.phone,
                  readOnly: _lockPhone,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your phone number'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _idNumberController,
                  label: 'ID Number',
                  hint: 'e.g. 1234567890',
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your ID number'
                      : null,
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Account Security'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm your password',
                  obscureText: true,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Professional Credentials'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _licenseController,
                  label: 'Medical License Number',
                  hint: 'e.g. MCI-12345',
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter license number'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration('Specialization'),
                  initialValue: _selectedSpecialization,
                  items: _specializations.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedSpecialization = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a specialization' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _experienceController,
                  label: 'Years of Experience',
                  hint: 'e.g. 5',
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter years of experience'
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _hospitalController,
                  label: 'Hospital/Clinic Address',
                  hint: 'e.g. City General Hospital',
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter affiliation'
                      : null,
                ),
                const SizedBox(height: 24),

                _buildSectionLabel('Documents'),
                const SizedBox(height: 8),
                Text(
                  'Please upload clear copies of the following documents',
                  style: GoogleFonts.roboto(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                // Medical Certificate Upload
                _buildUploadCard(
                  title: 'Medical Certificate',
                  file: _medicalCertificateFile,
                  isUploading: _isUploadingMedical,
                  onTap: () => _pickFile(true),
                  onRemove: () => _removeFile(true),
                ),

                const SizedBox(height: 16),

                // ID Proof Upload
                _buildUploadCard(
                  title: 'ID Proof',
                  file: _idProofFile,
                  isUploading: _isUploadingId,
                  onTap: () => _pickFile(false),
                  onRemove: () => _removeFile(false),
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Submit for Verification',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required PlatformFile? file,
    required bool isUploading,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: file != null
                    ? AppColors.primaryBlue
                    : Colors.grey.shade300,
                style: BorderStyle.solid,
                width: file != null ? 1.5 : 1,
              ),
              boxShadow: [
                if (file == null)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: isUploading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : file != null
                ? Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.name,
                              style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(file.size / 1024).toStringAsFixed(1)} KB',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: onRemove,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 32,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click to upload',
                        style: GoogleFonts.roboto(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'PDF, JPG, PNG (Max 5MB)',
                        style: GoogleFonts.roboto(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, hint: hint).copyWith(counterText: ''),
      validator: validator,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      readOnly: readOnly,
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      labelStyle: GoogleFonts.roboto(color: AppColors.textGrey),
      hintStyle: GoogleFonts.roboto(
        color: AppColors.textGrey.withOpacity(0.5),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }
}
