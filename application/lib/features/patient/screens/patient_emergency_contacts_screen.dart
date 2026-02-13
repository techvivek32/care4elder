import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/services/profile_service.dart';

class PatientEmergencyContactsScreen extends StatefulWidget {
  const PatientEmergencyContactsScreen({super.key});

  @override
  State<PatientEmergencyContactsScreen> createState() =>
      _PatientEmergencyContactsScreenState();
}

class _ContactEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController customRelationController =
      TextEditingController();
  String? selectedRelation;
  bool isNew;

  _ContactEntry({this.isNew = true});

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    customRelationController.dispose();
  }
}

class _PatientEmergencyContactsScreenState
    extends State<PatientEmergencyContactsScreen> {
  final List<_ContactEntry> _contacts = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<String> _relations = [
    'Father',
    'Mother',
    'Son',
    'Daughter',
    'Brother',
    'Wife',
    'Husband',
    'Friend',
    'Other',
    'Custom',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedContacts();
  }

  Future<void> _loadSavedContacts() async {
    setState(() => _isLoading = true);
    try {
      final profileService = ProfileService();
      // Ensure we have the latest profile data
      await profileService.fetchProfile();

      final currentUser = profileService.currentUser;
      if (currentUser != null && currentUser.emergencyContacts.isNotEmpty) {
        setState(() {
          _contacts.clear();
          for (var contact in currentUser.emergencyContacts) {
            final entry = _ContactEntry(isNew: false);
            entry.nameController.text = contact.name;
            entry.phoneController.text = contact.phone;

            if (_relations.contains(contact.relation)) {
              entry.selectedRelation = contact.relation;
            } else if (contact.relation.isNotEmpty) {
              entry.selectedRelation = 'Custom';
              entry.customRelationController.text = contact.relation;
            }
            _contacts.add(entry);
          }
        });
      } else {
        // Fallback to SharedPreferences if backend has no data
        final prefs = await SharedPreferences.getInstance();
        final String? savedData = prefs.getString('emergency_relatives');
        if (savedData != null) {
          final List<dynamic> decoded = jsonDecode(savedData);
          setState(() {
            _contacts.clear();
            for (var item in decoded) {
              final entry = _ContactEntry(isNew: false);
              entry.nameController.text = item['name'] ?? '';
              entry.phoneController.text = item['phone'] ?? '';
              String relation = item['relation'] ?? '';

              if (_relations.contains(relation)) {
                entry.selectedRelation = relation;
              } else if (relation.isNotEmpty) {
                entry.selectedRelation = 'Custom';
                entry.customRelationController.text = relation;
              }
              _contacts.add(entry);
            }
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading saved contacts: $e');
    } finally {
      if (_contacts.isEmpty) {
        _addContact();
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    for (var contact in _contacts) {
      contact.dispose();
    }
    super.dispose();
  }

  void _addContact() {
    setState(() {
      _contacts.add(_ContactEntry());
    });
  }

  void _removeContact(int index) {
    if (_contacts.length <= 1) return; // Prevent removing the last contact

    setState(() {
      final removedItem = _contacts.removeAt(index);
      removedItem.dispose();
    });
  }

  Future<bool> _showTermsDialog() async {
    final colorScheme = Theme.of(context).colorScheme;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: colorScheme.surface,
            title: Text(
              'Terms & Conditions',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'By proceeding with this application, the patient’s relative/guardian confirms that they fully accept responsibility for the patient’s medical care and related decisions.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The relative/guardian acknowledges that:',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'They are voluntarily taking full responsibility for the patient.',
                    colorScheme,
                  ),
                  _buildBulletPoint(
                    'Any medical expenses, treatments, or additional costs (current or future) will be borne by the verified relative/guardian.',
                    colorScheme,
                  ),
                  _buildBulletPoint(
                    'The registered mobile number is verified and belongs to the responsible relative/guardian.',
                    colorScheme,
                  ),
                  _buildBulletPoint(
                    'They understand and agree that all financial liabilities related to the patient rest solely with them.',
                    colorScheme,
                  ),
                  _buildBulletPoint(
                    'The application and its providers are not responsible for any medical outcomes or expenses.',
                    colorScheme,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By accepting these Terms & Conditions, the relative/guardian provides their consent and confirmation of the above.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: TextStyle(color: colorScheme.primary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                ),
                child: Text(
                  'Accept & Proceed',
                  style: TextStyle(color: colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildBulletPoint(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14, height: 1.5, color: colorScheme.onSurface)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.roboto(fontSize: 14, height: 1.5, color: colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndVerify() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Please fix the errors above');
      return;
    }

    // Show Terms & Conditions
    final accepted = await _showTermsDialog();
    if (!accepted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, String>> contactsData = _contacts.map((c) {
        String relation = c.selectedRelation ?? '';
        if (relation == 'Custom') {
          relation = c.customRelationController.text.trim();
        }
        return {
          'name': c.nameController.text.trim(),
          'relation': relation,
          'phone': c.phoneController.text.trim(),
        };
      }).toList();

      // Initiate OTP for the contact that needs verification
      // If there are new contacts, verify the last added one. 
      // Otherwise, verify the first contact.
      final contactToVerify = _contacts.lastWhere(
        (c) => c.isNew,
        orElse: () => _contacts.first,
      );
      final phoneToVerify = contactToVerify.phoneController.text.trim();

      // We send OTP (Mock/Static) to simulate the process
      await AuthService().sendOtp(phoneToVerify);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sending OTP for verification...'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );

        // Navigate to OTP verification and pass contactsData to be saved AFTER verification
        context.push(
          '/patient/contacts/otp',
          extra: {
            'phone': phoneToVerify,
            'contactsData': contactsData,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _importRelative(Map<String, String> relative) {
    // Check if this relative is already added (by phone)
    bool exists = _contacts.any(
      (c) => c.phoneController.text == relative['phone'],
    );
    if (exists) {
      _showError('This relative is already in the list.');
      return;
    }

    // If the first contact is empty (and only one exists), fill it. Otherwise add new.
    _ContactEntry target;
    if (_contacts.length == 1 &&
        _contacts[0].nameController.text.isEmpty &&
        _contacts[0].phoneController.text.isEmpty) {
      target = _contacts[0];
    } else {
      _addContact();
      target = _contacts.last;
    }

    target.nameController.text = relative['name'] ?? '';
    target.phoneController.text = relative['phone'] ?? '';

    // Handle relation mapping if needed
    if (_relations.contains(relative['relation'])) {
      target.selectedRelation = relative['relation'];
    } else {
      target.selectedRelation = 'Custom';
      target.customRelationController.text = relative['relation'] ?? '';
    }

    setState(() {});
  }

  Future<void> _importFromContacts() async {
    if (kIsWeb) {
      _showError('Contacts import is not supported on web.');
      return;
    }

    if (await FlutterContacts.requestPermission()) {
      setState(() => _isLoading = true);
      try {
        List<Contact> contacts = await FlutterContacts.getContacts(
          withProperties: true,
          withPhoto: false,
        );

        // Filter out contacts without phone numbers
        contacts = contacts.where((c) => c.phones.isNotEmpty).toList();

        if (mounted) {
          setState(() => _isLoading = false);
          _showContactsPicker(contacts);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Failed to load contacts: $e');
        }
      }
    } else {
      _showError('Contacts permission denied.');
    }
  }

  void _showContactsPicker(List<Contact> contacts) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Select from Contacts',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: contacts.length,
                  separatorBuilder: (ctx, i) => Divider(color: colorScheme.outlineVariant),
                  itemBuilder: (ctx, i) {
                    final contact = contacts[i];
                    final phone = contact.phones.first.number;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: Theme.of(context).brightness == Brightness.light
                              ? AppColors.premiumGradient
                              : AppColors.darkPremiumGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        contact.displayName,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        phone,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _importRelative({
                          'name': contact.displayName,
                          'phone': phone.replaceAll(RegExp(r'\D'), ''),
                          'relation': 'Other',
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: Theme.of(context).brightness == Brightness.light
                  ? AppColors.premiumGradient
                  : AppColors.darkPremiumGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue
                          : const Color(0xFF041E34))
                      .withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Emergency Relative',
          style: GoogleFonts.roboto(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Import from Contacts Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _isLoading ? null : _importFromContacts,
                    icon: Icon(
                      Icons.contacts_outlined,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'Import from Contacts',
                      style: GoogleFonts.roboto(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: colorScheme.primary.withOpacity(
                        0.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    return _buildContactItem(
                      _contacts[index],
                      index,
                      const AlwaysStoppedAnimation(1.0),
                    );
                  },
                ),
              ),

              // Add Another Relative Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addContact,
                    icon: Icon(Icons.add, color: colorScheme.primary),
                    label: Text(
                      'Add Another Relative',
                      style: GoogleFonts.roboto(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Save and Verify Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: Theme.of(context).brightness == Brightness.light
                        ? AppColors.premiumGradient
                        : AppColors.darkPremiumGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Save and Verify',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              // Skip Button (Removed/Disabled as per request, just showing text maybe or nothing)
              // Request said "remove or disable". I will remove it to be cleaner.
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(
    _ContactEntry contact,
    int index,
    Animation<double> animation,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) ...[
              Divider(height: 32, color: colorScheme.outlineVariant),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Relative ${index + 1}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeContact(index),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Name Field
            Text(
              'Relative Name',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: contact.nameController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Enter full name',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                filled: true,
                fillColor: colorScheme.surface,
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
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Relation Dropdown
            Text(
              'Relation',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: contact.selectedRelation,
              hint: Text('Select relation', style: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5))),
              validator: (value) =>
                  value == null ? 'Please select a relation' : null,
              dropdownColor: colorScheme.surface,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surface,
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
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: _relations.map((relation) {
                return DropdownMenuItem(
                  value: relation,
                  child: Text(relation, style: TextStyle(color: colorScheme.onSurface)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  contact.selectedRelation = value;
                });
              },
            ),

            // Custom Relation Field
            if (contact.selectedRelation == 'Custom') ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: contact.customRelationController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please specify relationship'
                    : null,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Enter relationship type',
                  hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  filled: true,
                  fillColor: colorScheme.surface,
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
                    borderSide: BorderSide(color: colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Phone Number Field
            Text(
              'Mobile Number',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: contact.phoneController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: TextStyle(color: colorScheme.onSurface),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                if (value.length != 10) return 'Must be 10 digits';

                // Duplicate check
                int matchCount = 0;
                for (var c in _contacts) {
                  if (c.phoneController.text.trim() == value.trim()) {
                    matchCount++;
                  }
                }
                if (matchCount > 1) return 'Duplicate phone number';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                filled: true,
                fillColor: colorScheme.surface,
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
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
