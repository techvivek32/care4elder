import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../services/doctor_profile_service.dart';
import '../services/withdrawal_service.dart';

enum EarningsRange { week, month, all }

enum EarningsStatus { all, completed, pending }

class EarningsEntry {
  final String id;
  final String patientName;
  final String type;
  final DateTime date;
  final int amount;
  final EarningsStatus status;

  EarningsEntry({
    required this.id,
    required this.patientName,
    required this.type,
    required this.date,
    required this.amount,
    required this.status,
  });
}

class DoctorEarningsScreen extends StatefulWidget {
  const DoctorEarningsScreen({super.key});

  @override
  State<DoctorEarningsScreen> createState() => _DoctorEarningsScreenState();
}

class _DoctorEarningsScreenState extends State<DoctorEarningsScreen> {
  late Future<List<EarningsEntry>> _earningsFuture;
  late Future<List<WithdrawalRequestModel>> _withdrawalsFuture;
  EarningsRange _selectedRange = EarningsRange.month;
  EarningsStatus _selectedStatus = EarningsStatus.all;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _earningsFuture = _loadEarnings();
    _withdrawalsFuture = WithdrawalService().getWithdrawalRequests();
  }

  Future<void> _refreshData() async {
    setState(() {
      _earningsFuture = _loadEarnings();
      _withdrawalsFuture = WithdrawalService().getWithdrawalRequests();
    });
    await DoctorProfileService().getProfile();
  }

  Future<List<EarningsEntry>> _loadEarnings() async {
    // This should ideally fetch from an API, but for now we'll keep the mock data 
    // or adapt it to show real history if an API exists. 
    // For now, let's keep the mock earnings list but show real wallet balance.
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      EarningsEntry(
        id: '1',
        patientName: 'Sarah Johnson',
        type: 'Video',
        date: now.subtract(const Duration(days: 1)),
        amount: 500,
        status: EarningsStatus.completed,
      ),
      // ... keeping some mock data for the list
    ];
  }

  void _showWithdrawDialog() {
    final profile = DoctorProfileService().currentProfile;
    final amountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Withdraw Request', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Balance: ₹${profile.walletBalance.toStringAsFixed(2)}', 
              style: GoogleFonts.roboto(color: AppColors.primaryBlue, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount to Withdraw',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                return;
              }
              if (amount > profile.walletBalance) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance')));
                return;
              }

              Navigator.pop(context);
              setState(() => _isSubmitting = true);
              try {
                await WithdrawalService().createWithdrawalRequest(amount);
                await _refreshData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal request submitted successfully')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } finally {
                if (mounted) {
                  setState(() => _isSubmitting = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DoctorProfileService(),
      builder: (context, _) {
        final profile = DoctorProfileService().currentProfile;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              'Earnings',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textDark),
          ),
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Earnings Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryBlue, Color(0xFF1E88E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Earnings',
                          style: GoogleFonts.roboto(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${profile.walletBalance.toStringAsFixed(2)}',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _showWithdrawDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isSubmitting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Withdraw Request', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Withdrawal Requests',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<WithdrawalRequestModel>>(
                    future: _withdrawalsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading requests: ${snapshot.error}'));
                      }
                      final withdrawals = snapshot.data ?? [];
                      if (withdrawals.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('No withdrawal requests yet.', 
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(color: AppColors.textGrey)),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: withdrawals.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final req = withdrawals[index];
                          return _buildWithdrawalCard(req);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Recent Consultations',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Mock consultation earnings list
                  FutureBuilder<List<EarningsEntry>>(
                    future: _earningsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final entries = snapshot.data ?? [];
                      return Column(
                        children: entries.map((e) => _buildEarningCard(e)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildWithdrawalCard(WithdrawalRequestModel req) {
    Color statusColor;
    switch (req.status) {
      case 'pending': statusColor = Colors.orange; break;
      case 'approved': statusColor = Colors.blue; break;
      case 'declined': statusColor = Colors.red; break;
      case 'credited': statusColor = Colors.green; break;
      default: statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              req.status == 'credited' ? Icons.check_circle_outline : Icons.account_balance_wallet_outlined,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${req.amount.toStringAsFixed(0)}',
                      style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        req.status.toUpperCase(),
                        style: GoogleFonts.roboto(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(req.createdAt),
                  style: GoogleFonts.roboto(color: AppColors.textGrey, fontSize: 12),
                ),
                if (req.status == 'declined' && req.rejectionReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Reason: ${req.rejectionReason}',
                      style: GoogleFonts.roboto(color: Colors.red, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningCard(EarningsEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.videocam_outlined,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.patientName,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '₹${entry.amount}',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(entry.date),
                      style: GoogleFonts.roboto(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      entry.type,
                      style: GoogleFonts.roboto(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
