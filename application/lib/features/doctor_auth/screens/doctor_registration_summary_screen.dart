import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../services/doctor_auth_service.dart';

class DoctorRegistrationSummaryScreen extends StatefulWidget {
  const DoctorRegistrationSummaryScreen({super.key});

  @override
  State<DoctorRegistrationSummaryScreen> createState() =>
      _DoctorRegistrationSummaryScreenState();
}

class _DoctorRegistrationSummaryScreenState
    extends State<DoctorRegistrationSummaryScreen> {
  bool _isLoading = false;
  bool _termsAccepted = false;
  final _service = DoctorAuthService();

  Future<void> _handleSubmit() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms and Conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _service.submitRegistration();
      if (success && mounted) {
        // Navigate to verification pending screen
        context.go('/doctor/verification-pending');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting registration: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _service.registrationData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Review & Submit',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Contact Information'),
              _buildInfoRow('Phone', data.phoneNumber ?? 'Not provided'),
              _buildInfoRow('Email', data.email ?? 'Not provided'),

              const SizedBox(height: 24),
              _buildSectionHeader('Personal Information'),
              _buildInfoRow('Full Name', data.fullName ?? 'Not provided'),
              _buildInfoRow('ID Number', data.idNumber ?? 'Not provided'),

              const SizedBox(height: 24),
              _buildSectionHeader('Professional Details'),
              _buildInfoRow(
                'License Number',
                data.medicalRegistrationNumber ?? 'Not provided',
              ),
              _buildInfoRow(
                'Specialization',
                data.specialization ?? 'Not provided',
              ),
              _buildInfoRow('Experience', '${data.experienceYears ?? 0} Years'),
              _buildInfoRow(
                'Affiliation',
                data.hospitalAffiliation ?? 'Not provided',
              ),

              const SizedBox(height: 24),
              _buildSectionHeader('Documents'),
              if (data.documentPaths.isEmpty)
                Text(
                  'No documents uploaded',
                  style: GoogleFonts.roboto(color: AppColors.textGrey),
                )
              else
                ...data.documentPaths.map((path) {
                  final name = path.split('/').last;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.roboto(
                              color: AppColors.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      activeColor: AppColors.primaryBlue,
                      onChanged: (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: GoogleFonts.roboto(
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: GoogleFonts.roboto(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showTermsBottomSheet(context, initialTab: 0),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: GoogleFonts.roboto(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => _showTermsBottomSheet(context, initialTab: 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: Theme.of(context).brightness == Brightness.light
                      ? AppColors.premiumGradient
                      : AppColors.darkPremiumGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Submit Registration',
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
    );
  }

  void _showTermsBottomSheet(BuildContext context, {int initialTab = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TermsBottomSheet(initialTab: initialTab),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsBottomSheet extends StatefulWidget {
  final int initialTab;
  const _TermsBottomSheet({required this.initialTab});

  @override
  State<_TermsBottomSheet> createState() => _TermsBottomSheetState();
}

class _TermsBottomSheetState extends State<_TermsBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Legal Documents',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryBlue,
              unselectedLabelColor: AppColors.textGrey,
              indicatorColor: AppColors.primaryBlue,
              tabs: const [
                Tab(text: 'Terms of Service'),
                Tab(text: 'Privacy Policy'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTermsOfService(scrollController),
                  _buildPrivacyPolicy(scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsOfService(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Terms of Service'),
          _subtitle('Last updated: 16 March 2026'),
          const SizedBox(height: 16),
          _heading('1. Acceptance of Terms'),
          _body('By accessing and using the Care4Elder website and services, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use our services.'),
          _heading('2. Description of Services'),
          _body('Care4Elder provides technology-enabled elder care services including but not limited to emergency response, nursing care, physiotherapy, doctor visits, hospital-at-home care, caregiver services, and medical equipment rental. Service availability may vary by location.'),
          _heading('3. User Responsibilities'),
          _body('You agree to:'),
          _bullet('Provide accurate and complete information when using our services'),
          _bullet('Use our services only for lawful purposes'),
          _bullet('Not interfere with the proper functioning of our website'),
          _bullet('Keep your account credentials secure, if applicable'),
          _heading('4. Service Availability'),
          _body('While we strive to provide uninterrupted services, Care4Elder does not guarantee that our website or services will be available at all times. We reserve the right to modify, suspend, or discontinue any part of our services at any time.'),
          _heading('5. Payment & Subscriptions'),
          _body('Certain services require payment through our subscription plans. All fees are as listed on our pricing page and are subject to change with prior notice. Refund policies apply as per the specific plan terms.'),
          _heading('6. Limitation of Liability'),
          _body('Care4Elder shall not be liable for any indirect, incidental, special, or consequential damages arising out of or in connection with the use of our services. Our total liability shall not exceed the amount paid by you for the specific service in question.'),
          _heading('7. Intellectual Property'),
          _body('All content on the Care4Elder website, including text, graphics, logos, and software, is the property of Care4Elder and is protected by applicable intellectual property laws. Unauthorized use is prohibited.'),
          _heading('8. Governing Law'),
          _body('These Terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in Asansol, West Bengal.'),
          _heading('9. Contact Us'),
          _body('For questions regarding these Terms of Service, please contact us at:'),
          _body('Care4Elder'),
          _body('Email: connect.us@care4elder.com'),
          _body('Phone: 0341-3543415'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPrivacyPolicy(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Privacy Policy'),
          _subtitle('Last updated: 16 March 2026'),
          const SizedBox(height: 16),
          _heading('1. Information We Collect'),
          _body('We collect personal information that you voluntarily provide when using our services, including your name, email address, phone number, location, and any messages you submit through our contact or franchise inquiry forms.'),
          _body('We may also automatically collect certain technical information such as your IP address, browser type, device information, and usage data when you visit our website.'),
          _heading('2. How We Use Your Information'),
          _body('We use the information we collect to:'),
          _bullet('Provide, maintain, and improve our elder care services'),
          _bullet('Respond to your inquiries and fulfill your requests'),
          _bullet('Send you service-related communications'),
          _bullet('Process franchise applications'),
          _bullet('Comply with legal obligations'),
          _heading('3. Information Sharing'),
          _body('We do not sell, trade, or rent your personal information to third parties. We may share your information with trusted service providers who assist us in operating our website and services, subject to confidentiality agreements.'),
          _heading('4. Data Security'),
          _body('We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.'),
          _heading('5. Your Rights'),
          _body('You have the right to access, correct, or delete your personal information. You may also opt out of receiving marketing communications from us at any time by contacting us at connect.us@care4elder.com.'),
          _heading('6. Cookies'),
          _body('Our website may use cookies and similar tracking technologies to enhance your browsing experience. You can control cookie preferences through your browser settings.'),
          _heading('7. Contact Us'),
          _body('If you have any questions about this Privacy Policy, please contact us at:'),
          _body('Care4Elder'),
          _body('Email: connect.us@care4elder.com'),
          _body('Phone: 0341-3543415'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
        ),
      );

  Widget _subtitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: GoogleFonts.roboto(fontSize: 12, color: AppColors.textGrey),
        ),
      );

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      );

  Widget _body(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textDark, height: 1.5),
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textDark)),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.roboto(fontSize: 14, color: AppColors.textDark, height: 1.5),
              ),
            ),
          ],
        ),
      );
}