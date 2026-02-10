import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/theme/app_colors.dart';

class PatientWalletScreen extends StatefulWidget {
  const PatientWalletScreen({super.key});

  @override
  State<PatientWalletScreen> createState() => _PatientWalletScreenState();
}

class _PatientWalletScreenState extends State<PatientWalletScreen> {
  late Razorpay _razorpay;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
    _amountController.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Payment success - call backend to update wallet
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid amount')),
        );
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment Successful! Updating wallet...')),
    );

    final success = await profileService.rechargeWallet(
      response.paymentId ?? '',
      amount,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet updated successfully!')),
        );
        _amountController.clear();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update wallet: ${profileService.error}')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  void _openCheckout() {
    final amountText = _amountController.text;
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final profileService = Provider.of<ProfileService>(context, listen: false);
    final user = profileService.currentUser;
    final keyId = profileService.razorpayKeyId;

    if (keyId == null || keyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment configuration missing. Please try again later.')),
      );
      profileService.fetchConfig();
      return;
    }

    var options = {
      'key': keyId,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'Care4Elder',
      'description': 'Wallet Recharge',
      'prefill': {
        'contact': user?.phoneNumber ?? '',
        'email': user?.email ?? '',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Wallet',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<ProfileService>(
        builder: (context, profileService, child) {
          final balance = profileService.currentUser?.walletBalance ?? 0.0;
          
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Balance Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E3192).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Balance',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹',
                                  style: GoogleFonts.roboto(
                                    fontSize: 48,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  balance.toStringAsFixed(2),
                                  style: GoogleFonts.roboto(
                                    fontSize: 48,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Amount Input
                      Text(
                        'Enter Amount',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            prefixText: '₹ ',
                            hintStyle: GoogleFonts.roboto(
                              color: Colors.grey[400],
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Recharge Button at Bottom
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _openCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: profileService.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        'Recharge',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
