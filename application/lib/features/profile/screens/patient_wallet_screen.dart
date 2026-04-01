import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/refund_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/services/auth_service.dart';

class PatientWalletScreen extends StatefulWidget {
  const PatientWalletScreen({super.key});

  @override
  State<PatientWalletScreen> createState() => _PatientWalletScreenState();
}

class _PatientWalletScreenState extends State<PatientWalletScreen> {
  late Razorpay _razorpay;
  final TextEditingController _amountController = TextEditingController();
  // callRequestId -> refund status ('pending' | 'approved' | 'rejected')
  Map<String, String> _refundStatusMap = {};

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileService>(context, listen: false).fetchWalletHistory();
      _loadRefundStatuses();
    });
  }

  Future<void> _loadRefundStatuses() async {
    final token = await AuthService().getToken();
    if (token == null) return;
    final refunds = await RefundService().fetchMyRefundRequests(token);
    final map = <String, String>{};
    for (final r in refunds) {
      final callRequestId = r['callRequestId']?.toString();
      final status = r['status']?.toString();
      if (callRequestId != null && status != null) {
        map[callRequestId] = status;
      }
    }
    if (mounted) setState(() => _refundStatusMap = map);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? colorScheme.surface : const Color(0xFFF6F8FB);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'My Wallet',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
          ),
        ],
      ),
      body: Consumer<ProfileService>(
        builder: (context, profileService, child) {
          final balance = profileService.currentUser?.walletBalance ?? 0.0;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BalanceCard(amount: balance),
                const SizedBox(height: 14),
                _RechargeCard(
                  amountController: _amountController,
                  isLoading: profileService.isLoading,
                  onRecharge: _openCheckout,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Wallet History',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'View All',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (profileService.walletHistory.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'No transactions yet',
                        style: GoogleFonts.roboto(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ...profileService.walletHistory.map((transaction) {
                    final isCredit = transaction.type == 'credit';
                    final doctorName =
                        transaction.metadata?['doctorName'] as String?;
                    final callRequestId =
                        transaction.metadata?['callRequestId'] as String?;
                    final doctorId = transaction.metadata?['doctorId'] as String?;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TransactionCard(
                        title: transaction.description,
                        subtitle1: doctorName,
                        subtitle2: _formatDate(transaction.timestamp),
                        amountText:
                            '${isCredit ? '+' : '-'}₹${transaction.amount.toStringAsFixed(0)}',
                        amountColor: isCredit ? Colors.green : Colors.red,
                        icon: isCredit
                            ? Icons.account_balance_wallet_outlined
                            : Icons.receipt_long_outlined,
                        refundWidget: (!isCredit &&
                                callRequestId != null &&
                                doctorId != null)
                            ? _buildRefundWidget(
                                transaction: transaction,
                                callRequestId: callRequestId,
                                doctorId: doctorId,
                                doctorName: doctorName ?? '',
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                const SizedBox(height: 18),
                _SupportCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  // UI widgets (no behavior changes)
  Widget _BalanceCard({required double amount}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: Theme.of(context).brightness == Brightness.light
            ? AppColors.premiumGradient
            : AppColors.darkPremiumGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
            blurRadius: 18,
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '₹ ${amount.toStringAsFixed(2)}',
            style: GoogleFonts.roboto(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _RechargeCard({
    required TextEditingController amountController,
    required bool isLoading,
    required VoidCallback onRecharge,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Amount',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
            ),
            child: TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '500.00',
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                hintStyle: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withOpacity(0.35),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: isLoading ? null : onRecharge,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Recharge Now',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _TransactionCard({
    required String title,
    required String? subtitle1,
    required String subtitle2,
    required String amountText,
    required Color amountColor,
    required IconData icon,
    required Widget? refundWidget,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle1 != null && subtitle1!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle1!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      subtitle2,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amountText,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: amountColor,
                ),
              ),
            ],
          ),
          if (refundWidget != null) ...[
            const SizedBox(height: 10),
            refundWidget,
          ],
        ],
      ),
    );
  }

  Widget _SupportCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help?',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Our support team is\navailable 24/7 for\nany wallet related\nissues.',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text(
                      'Contact Support',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.support_agent_rounded,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.15),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Force IST (UTC+5:30)
    // Add 5 hours and 30 minutes to the UTC time to get IST
    final istDate = date.toUtc().add(const Duration(hours: 5, minutes: 30));
    return DateFormat('dd/MM/yyyy hh:mm a').format(istDate);
  }

  Widget _buildRefundWidget({
    required WalletTransaction transaction,
    required String callRequestId,
    required String doctorId,
    required String doctorName,
  }) {
    final status = _refundStatusMap[callRequestId];

    if (status == 'pending') {
      return _refundBadge(Icons.hourglass_top_rounded, 'Refund Request Sent', Colors.orange);
    } else if (status == 'approved') {
      return _refundBadge(Icons.check_circle_outline, 'Refund Approved', Colors.green);
    } else if (status == 'rejected') {
      return _refundBadge(Icons.cancel_outlined, 'Refund Rejected', Colors.red);
    }

    // No refund yet — show button
    return OutlinedButton.icon(
      onPressed: () => _showRefundDialog(
        transaction: transaction,
        callRequestId: callRequestId,
        doctorId: doctorId,
        doctorName: doctorName,
      ),
      icon: const Icon(Icons.undo, size: 16, color: Colors.orange),
      label: Text(
        'Request Refund',
        style: GoogleFonts.roboto(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        side: const BorderSide(color: Colors.orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _refundBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.roboto(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showRefundDialog({
    required WalletTransaction transaction,
    required String callRequestId,
    required String doctorId,
    required String doctorName,
  }) {
    final reasonController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Request Refund', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: ₹${transaction.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
              if (doctorName.isNotEmpty)
                Text('Doctor: $doctorName',
                    style: GoogleFonts.roboto(color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reason for refund...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (reasonController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a reason')),
                        );
                        return;
                      }
                      setDialogState(() => isSubmitting = true);
                      final token = await AuthService().getToken();
                      final profileService = Provider.of<ProfileService>(context, listen: false);
                      final patientName = profileService.currentUser?.fullName ?? '';
                      if (token == null) return;
                      final result = await RefundService().submitRefundRequest(
                        token: token,
                        callRequestId: callRequestId,
                        doctorId: doctorId,
                        amount: transaction.amount,
                        reason: reasonController.text.trim(),
                        patientName: patientName,
                        doctorName: doctorName,
                      );
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (result['success'] == true) _loadRefundStatuses();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['success'] == true
                              ? 'Refund request submitted successfully'
                              : result['error'] ?? 'Failed to submit'),
                          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
