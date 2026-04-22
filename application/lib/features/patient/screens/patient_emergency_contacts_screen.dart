import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  Future<void> _removeContact(int index) async {
    if (_contacts.length <= 1) {
      // Only one contact left — confirm before clearing it
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove Contact'),
          content: const Text(
              'This is your only emergency contact. Are you sure you want to remove it?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      final removedItem = _contacts.removeAt(index);
      removedItem.dispose();
      // Always keep at least one empty entry so the form is never blank
      if (_contacts.isEmpty) {
        _contacts.add(_ContactEntry());
      }
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
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: Theme.of(context).brightness == Brightness.light
                      ? AppColors.premiumGradient
                      : AppColors.darkPremiumGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Accept & Proceed',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
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
      List<Map<String, String>> contactsData = _contacts.map((c) {
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

      // Ensure the intended contact receives the OTP: backend targets relatives[0]
      final int verifyIndex = _contacts.indexOf(contactToVerify);
      if (verifyIndex > 0) {
        final selectedMap = contactsData[verifyIndex];
        contactsData.removeAt(verifyIndex);
        contactsData = [selectedMap, ...contactsData];
      }

      // Save relatives and trigger server-side OTP to the selected phone
      await AuthService().updateRelatives(contactsData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to selected relative'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );

        // Navigate to OTP verification and pass contactsData for local persistence after success
        final from = GoRouterState.of(context).uri.queryParameters['from'];
        final otpRoute = (from != null && from.isNotEmpty)
            ? '/patient/contacts/otp?from=${Uri.encodeComponent(from)}'
            : '/patient/contacts/otp';

        context.push(
          otpRoute,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? colorScheme.surface : const Color(0xFFF6F8FB);
    final profile = context.watch<ProfileService>().currentUser;
    final avatarUrl = profile?.profilePictureUrl.trim().isNotEmpty == true
        ? profile!.profilePictureUrl
        : null;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                children: [
                  _TopHeaderBar(
                    title: 'Emergency Contacts',
                    avatarUrl: avatarUrl,
                    onBack: () {
                      final from =
                          GoRouterState.of(context).uri.queryParameters['from'];
                      final fallbackRoute = (from != null && from.isNotEmpty)
                          ? from
                          : '/patient/permissions';
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(fallbackRoute);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  _PillLabel(text: 'SAFETY PROFILE'),
                  const SizedBox(height: 14),
                  Text(
                    'Who should we call in an emergency?',
                    style: GoogleFonts.roboto(
                      fontSize: 30,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ensure your safety by linking a trusted relative. '
                    'We will only contact them during critical health alerts.',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ImportButton(
                    enabled: !_isLoading,
                    onTap: _importFromContacts,
                  ),
                  const SizedBox(height: 22),
                  // Form fields (reuse existing builder)
                  ...List.generate(_contacts.length, (index) {
                    return _buildContactItem(
                      _contacts[index],
                      index,
                      const AlwaysStoppedAnimation(1.0),
                    );
                  }),
                  const SizedBox(height: 4),
                  _AddAnotherButton(
                    onTap: _addContact,
                  ),
                  const SizedBox(height: 18),
                  _PrivacyGuaranteeBanner(),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: BoxDecoration(
                    color: pageBg,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveAndVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Save and Verify',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.check_circle_outline, size: 18),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldBg = isDark ? colorScheme.surface : Colors.white;
    final fieldBorder = colorScheme.outline.withOpacity(isDark ? 0.22 : 0.10);
    final iconMuted = colorScheme.onSurface.withOpacity(0.45);

    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) ...[
              const SizedBox(height: 4),
            ],

            // Contact header row with remove button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  index == 0 ? 'PRIMARY CONTACT' : 'CONTACT ${index + 1}',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: colorScheme.primary.withOpacity(0.75),
                  ),
                ),
                InkWell(
                  onTap: () => _removeContact(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline,
                            size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Remove',
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Name Field
            Text(
              'RELATIVE NAME',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: colorScheme.onSurface.withOpacity(0.55),
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
                hintText: 'Full legal name',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: iconMuted,
                ),
                filled: true,
                fillColor: fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
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
              'RELATION',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: colorScheme.onSurface.withOpacity(0.55),
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
                fillColor: fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
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
                  fillColor: fieldBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: fieldBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
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
              'MOBILE NUMBER',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: colorScheme.onSurface.withOpacity(0.55),
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
                hintText: '+1 (555) 000-0000',
                hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: iconMuted,
                ),
                filled: true,
                fillColor: fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: fieldBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
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

class _TopHeaderBar extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final VoidCallback onBack;

  const _TopHeaderBar({
    required this.title,
    required this.avatarUrl,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = Theme.of(context).brightness == Brightness.dark
        ? colorScheme.primary
        : const Color(0xFF1565C0);
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(Icons.arrow_back_ios_new,
                color: colorScheme.onSurface, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/patient/profile'),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline.withOpacity(0.25)),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.surfaceContainerHighest,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person, color: colorScheme.onSurface, size: 18)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PillLabel extends StatelessWidget {
  final String text;
  const _PillLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFFEAF0FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
          color: colorScheme.onSurface.withOpacity(0.55),
        ),
      ),
    );
  }
}

class _ImportButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ImportButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? colorScheme.surfaceContainerHighest
        : const Color(0xFFF1F4FA);
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contacts_outlined,
                size: 18, color: colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              'Import from Contacts',
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAnotherButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAnotherButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline,
                color: colorScheme.primary, size: 18),
            const SizedBox(width: 10),
            Text(
              'Add Another Relative',
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyGuaranteeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1E6CD6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Guarantee',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emergency contacts are encrypted\nand only accessible to verified\nmedical responders when an SOS is\ntriggered.',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              Icons.shield_outlined,
              size: 96,
              color: Colors.white.withOpacity(0.16),
            ),
          ),
        ],
      ),
    );
  }
}
