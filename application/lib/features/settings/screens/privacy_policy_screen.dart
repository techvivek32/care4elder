import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.light
                ? AppColors.premiumGradient
                : AppColors.darkPremiumGradient,
          ),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, 'Privacy Policy'),
            const SizedBox(height: 8),
            _buildSubtext(context, 'Last updated: 26 February 2026'),
            const SizedBox(height: 32),
            
            _buildSection(
              context,
              '1. Information We Collect',
              'We collect personal information that you voluntarily provide when using our services, including your name, email address, phone number, location, and any messages you submit through our contact or franchise inquiry forms.\n\nWe may also automatically collect certain technical information such as your IP address, browser type, device information, and usage data when you visit our website.',
            ),
            
            _buildSection(
              context,
              '2. How We Use Your Information',
              'We use the information we collect to:\n\n• Provide, maintain, and improve our elder care services\n• Respond to your inquiries and fulfill your requests\n• Send you service-related communications\n• Process franchise applications\n• Comply with legal obligations',
            ),
            
            _buildSection(
              context,
              '3. Information Sharing',
              'We do not sell, trade, or rent your personal information to third parties. We may share your information with trusted service providers who assist us in operating our website and services, subject to confidentiality agreements.',
            ),
            
            _buildSection(
              context,
              '4. Data Security',
              'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.',
            ),
            
            _buildSection(
              context,
              '5. Your Rights',
              'You have the right to access, correct, or delete your personal information. You may also opt out of receiving marketing communications from us at any time by contacting us at connect.us@care4elder.com.',
            ),
            
            _buildSection(
              context,
              '6. Cookies',
              'Our website may use cookies and similar tracking technologies to enhance your browsing experience. You can control cookie preferences through your browser settings.',
            ),
            
            _buildSection(
              context,
              '7. Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\nCare4Elder\nEmail: connect.us@care4elder.com\nPhone: 0341-3543415',
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF041E34)
            : Colors.white,
      ),
    );
  }

  Widget _buildSubtext(BuildContext context, String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        fontSize: 14,
        color: Theme.of(context).textTheme.bodySmall?.color,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF041E34)
                  : Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.roboto(
              fontSize: 15,
              height: 1.6,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
