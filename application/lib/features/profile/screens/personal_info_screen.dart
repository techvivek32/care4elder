import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/profile_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _dobController;
  DateTime? _selectedDob;

  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _dobController = TextEditingController();
    
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Initialize with cached data if available
    _updateControllers(_profileService.currentUser);
    
    // Fetch fresh data
    await _profileService.fetchProfile();
    if (mounted) {
      _updateControllers(_profileService.currentUser);
    }
  }

  void _updateControllers(UserProfile? user) {
    setState(() {
      _nameController.text = user?.fullName ?? '';
      _emailController.text = user?.email ?? '';
      _phoneController.text = user?.phoneNumber ?? '';
      _locationController.text = user?.location ?? '';
      _selectedDob = user?.dateOfBirth;
      _dobController.text = _selectedDob != null
          ? DateFormat('yyyy-MM-dd').format(_selectedDob!)
          : '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final imageUrl = await _profileService.uploadProfileImage(file);

        if (imageUrl != null) {
          final updatedProfile = _profileService.currentUser?.copyWith(
            profilePictureUrl: imageUrl,
          );

          if (updatedProfile != null) {
            final success = await _profileService.updateProfile(updatedProfile);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Profile picture updated successfully'
                        : 'Failed to update profile picture',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            }
          }
        } else {
          if (mounted && _profileService.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_profileService.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = _profileService.currentUser?.copyWith(
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        location: _locationController.text,
        dateOfBirth: _selectedDob,
      );

      if (updatedProfile != null) {
        final success = await _profileService.updateProfile(updatedProfile);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Profile updated successfully'
                    : 'Failed to update profile',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
          if (success) Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Personal Info',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: _profileService,
            builder: (context, child) {
              if (_profileService.isLoading) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }
              return TextButton(
                onPressed: _saveProfile,
                child: Text(
                  'Save',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ListenableBuilder(
                listenable: _profileService,
                builder: (context, child) {
                  return Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: Theme.of(context).brightness == Brightness.light
                                ? AppColors.premiumGradient
                                : AppColors.darkPremiumGradient,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: _profileService.currentUser?.profilePictureUrl
                                        .isNotEmpty ==
                                    true
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.network(
                                      _profileService.currentUser!.profilePictureUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        if (_profileService.isLoading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _profileService.isLoading ? null : _pickProfileImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: Theme.of(context).brightness == Brightness.light
                                    ? AppColors.premiumGradient
                                    : AppColors.darkPremiumGradient,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              _buildTextField(
                context,
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) =>
                    value?.isEmpty == true ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value?.isEmpty == true ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length != 10) {
                    return 'Phone number must be exactly 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                controller: _dobController,
                label: 'Date of Birth',
                icon: Icons.calendar_today_outlined,
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) => value?.isEmpty == true
                    ? 'Please select your date of birth'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                context,
                controller: _locationController,
                label: 'Location',
                icon: Icons.location_on_outlined,
                validator: (value) => value?.isEmpty == true
                    ? 'Please enter your location'
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      inputFormatters: inputFormatters,
      style: GoogleFonts.roboto(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: colorScheme.onSurface.withOpacity(0.4)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
      ),
    );
  }
}
