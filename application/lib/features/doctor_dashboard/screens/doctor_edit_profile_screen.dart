import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../services/doctor_profile_service.dart';

class DoctorEditProfileScreen extends StatefulWidget {
  const DoctorEditProfileScreen({super.key});

  @override
  State<DoctorEditProfileScreen> createState() => _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _aboutController = TextEditingController();
  final _hospitalController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  PlatformFile? _pickedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _qualificationsController.dispose();
    _experienceController.dispose();
    _aboutController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await DoctorProfileService().getProfile();
      if (mounted) {
        setState(() {
          _nameController.text = profile.name;
          _specialtyController.text = profile.specialty;
          _emailController.text = profile.email;
          
          // Remove +91 or 91 prefix for display if present
          String phone = profile.phone;
          if (phone.startsWith('+91')) {
            phone = phone.substring(3);
          } else if (phone.startsWith('91') && phone.length > 10) {
            phone = phone.substring(2);
          }
          _phoneController.text = phone;
          
          _qualificationsController.text = profile.qualifications;
          _experienceController.text = profile.experience;
          _aboutController.text = profile.about;
          _hospitalController.text = profile.hospitalAffiliation;
          _currentImageUrl = profile.profileImage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image size must be less than 5MB')),
            );
          }
          return;
        }

        setState(() {
          _pickedImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final currentProfile = DoctorProfileService().currentProfile;
      String? uploadedImageUrl = _currentImageUrl;
      if (_pickedImage != null) {
        uploadedImageUrl = await DoctorProfileService().uploadProfileImage(
          _pickedImage!,
        );
      }
      final updatedProfile = currentProfile.copyWith(
        name: _nameController.text.trim(),
        specialty: _specialtyController.text.trim(),
        email: _emailController.text.trim(),
        phone: '+91${_phoneController.text.trim()}',
        qualifications: _qualificationsController.text.trim(),
        experience: _experienceController.text.trim(),
        about: _aboutController.text.trim(),
        hospitalAffiliation: _hospitalController.text.trim(),
        profileImage: uploadedImageUrl,
      );

      await DoctorProfileService().updateProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        context.pop(); // Return to profile screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) => v?.isEmpty == true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _specialtyController,
                      label: 'Specialty',
                      icon: Icons.medical_services_outlined,
                      validator: (v) => v?.isEmpty == true ? 'Specialty is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v?.isEmpty == true) return 'Email is required';
                        if (!v!.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      prefixText: '+91 ',
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v?.isEmpty == true) return 'Phone is required';
                        if (v!.length != 10) return 'Phone must be 10 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _qualificationsController,
                      label: 'Qualifications',
                      icon: Icons.school_outlined,
                      validator: (v) => v?.isEmpty == true ? 'Qualifications are required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _experienceController,
                      label: 'Experience (Years)',
                      icon: Icons.work_outline,
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty == true ? 'Experience is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _hospitalController,
                      label: 'Hospital/Clinic Address',
                      icon: Icons.local_hospital_outlined,
                      validator: (v) => v?.isEmpty == true ? 'Hospital Affiliation is required' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _aboutController,
                      label: 'About',
                      icon: Icons.info_outline,
                      maxLines: 4,
                      validator: (v) => v?.isEmpty == true ? 'About section is required' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePicker() {
    Widget imageContent;

    if (_pickedImage != null && _pickedImage!.bytes != null) {
      imageContent = Image.memory(
        _pickedImage!.bytes!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: _currentImageUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => const Icon(
          Icons.person,
          size: 60,
          color: AppColors.primaryBlue,
        ),
      );
    } else {
      imageContent = const Icon(
        Icons.person,
        size: 60,
        color: AppColors.primaryBlue,
      );
    }

    return Center(
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              color: const Color(0xFFE3F2FD),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: imageContent,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: AppColors.primaryBlue,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: _pickImage,
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        style: GoogleFonts.roboto(
          color: AppColors.textDark,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(color: Colors.grey),
          prefixIcon: Icon(icon, color: AppColors.primaryBlue),
          prefixText: prefixText,
          prefixStyle: GoogleFonts.roboto(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
