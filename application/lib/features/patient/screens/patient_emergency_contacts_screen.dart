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

  _ContactEntry();

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    customRelationController.dispose();
  }
}

class _PatientEmergencyContactsScreenState
    extends State<PatientEmergencyContactsScreen> {
  final List<_ContactEntry> _contacts = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
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
    _addContact(); // Add initial contact
  }

  @override
  void dispose() {
    for (var contact in _contacts) {
      contact.dispose();
    }
    super.dispose();
  }

  void _addContact() {
    final index = _contacts.length;
    _contacts.add(_ContactEntry());
    _listKey.currentState?.insertItem(index);
    setState(() {}); // Ensure UI updates if needed
  }

  void _removeContact(int index) {
    if (_contacts.length <= 1) return; // Prevent removing the last contact

    final removedItem = _contacts.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildContactItem(removedItem, index, animation),
    );

    // Force rebuild to update "Contact X" numbering for remaining items
    setState(() {});

    Future.delayed(const Duration(milliseconds: 500), () {
      removedItem.dispose();
    });
  }

  Future<bool> _showTermsDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Terms & Conditions',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The relative/guardian acknowledges that:',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'They are voluntarily taking full responsibility for the patient.',
                  ),
                  _buildBulletPoint(
                    'Any medical expenses, treatments, or additional costs (current or future) will be borne by the verified relative/guardian.',
                  ),
                  _buildBulletPoint(
                    'The registered mobile number is verified and belongs to the responsible relative/guardian.',
                  ),
                  _buildBulletPoint(
                    'They understand and agree that all financial liabilities related to the patient rest solely with them.',
                  ),
                  _buildBulletPoint(
                    'The application and its providers are not responsible for any medical outcomes or expenses.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By accepting these Terms & Conditions, the relative/guardian provides their consent and confirmation of the above.',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: const Text(
                  'Accept & Proceed',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, height: 1.5)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.roboto(fontSize: 14, height: 1.5),
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
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
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

      await prefs.setString('emergency_relatives', jsonEncode(contactsData));

      // Save to Backend
      await AuthService().updateRelatives(contactsData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Relatives saved. Sending OTP...'),
            backgroundColor: Colors.green,
          ),
        );

        // Initiate OTP for the first contact (as primary verification)
        final firstContactPhone = contactsData[0]['phone']!;
        // We send OTP (Mock/Static) to simulate the process
        await AuthService().sendOtp(firstContactPhone);

        // Navigate to OTP verification
        if (mounted) {
          context.push('/patient/contacts/otp', extra: firstContactPhone);
        }
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: contacts.length,
                  separatorBuilder: (ctx, i) => const Divider(),
                  itemBuilder: (ctx, i) {
                    final contact = contacts[i];
                    final phone = contact.phones.first.number;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryBlue.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : '?'),
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(phone),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: AppColors.textDark),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Emergency Relative',
          style: GoogleFonts.roboto(
            color: AppColors.textDark,
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
                    icon: const Icon(
                      Icons.contacts_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    label: Text(
                      'Import from Contacts',
                      style: GoogleFonts.roboto(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primaryBlue.withValues(
                        alpha: 0.1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  initialItemCount: _contacts.length,
                  padding: const EdgeInsets.all(24),
                  itemBuilder: (context, index, animation) {
                    // Ensure index is valid for _contacts
                    if (index >= _contacts.length) {
                      return const SizedBox.shrink();
                    }
                    return _buildContactItem(
                      _contacts[index],
                      index,
                      animation,
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
                    icon: const Icon(Icons.add, color: AppColors.primaryBlue),
                    label: Text(
                      'Add Another Relative',
                      style: GoogleFonts.roboto(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Save Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
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
                            'Save & Verify',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) ...[
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Relative ${index + 1}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
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
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: contact.nameController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
              decoration: InputDecoration(
                hintText: 'Enter full name',
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: AppColors.textGrey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
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
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: contact.selectedRelation,
              hint: const Text('Select relation'),
              validator: (value) =>
                  value == null ? 'Please select a relation' : null,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              items: _relations.map((relation) {
                return DropdownMenuItem(value: relation, child: Text(relation));
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
                decoration: InputDecoration(
                  hintText: 'Enter relationship type',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
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
                color: AppColors.textDark,
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
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.textGrey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
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
