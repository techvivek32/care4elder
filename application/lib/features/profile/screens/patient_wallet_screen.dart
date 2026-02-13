import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
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

    // Fetch history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileService>(context, listen: false).fetchWalletHistory();
    });
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Wallet',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
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
                          gradient: Theme.of(context).brightness == Brightness.light
                              ? AppColors.premiumGradient
                              : AppColors.darkPremiumGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
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
                                color: Colors.white.withOpacity(0.9),
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
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 200,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            prefixText: '₹ ',
                            prefixStyle: GoogleFonts.roboto(
                              color: colorScheme.onSurface,
                            ),
                            hintStyle: GoogleFonts.roboto(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      
                      // History Header
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Wallet History',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // History List
                      if (profileService.walletHistory.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No transactions yet',
                              style: GoogleFonts.roboto(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: profileService.walletHistory.length,
                          itemBuilder: (context, index) {
                            final transaction = profileService.walletHistory[index];
                            final isCredit = transaction.type == 'credit';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isCredit 
                                          ? Colors.green.withOpacity(0.1) 
                                          : Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCredit 
                                          ? Icons.add_rounded 
                                          : Icons.remove_rounded,
                                      color: isCredit 
                                          ? Colors.green 
                                          : Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          transaction.description,
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(transaction.timestamp),
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isCredit ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              
              // Recharge Button at Bottom
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                child: Container(
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
                    onPressed: _openCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: profileService.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        'Recharge Now',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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

  String _formatDate(DateTime date) {
    // Force IST (UTC+5:30)
    // Add 5 hours and 30 minutes to the UTC time to get IST
    final istDate = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd/MM/yyyy hh:mm a').format(istDate);
  }
}
