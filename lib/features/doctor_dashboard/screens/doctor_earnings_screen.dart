import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

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
  EarningsRange _selectedRange = EarningsRange.month;
  EarningsStatus _selectedStatus = EarningsStatus.all;

  @override
  void initState() {
    super.initState();
    _earningsFuture = _loadEarnings();
  }

  Future<List<EarningsEntry>> _loadEarnings() async {
    await Future.delayed(const Duration(milliseconds: 900));
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
      EarningsEntry(
        id: '2',
        patientName: 'Mike Chen',
        type: 'Voice',
        date: now.subtract(const Duration(days: 2)),
        amount: 300,
        status: EarningsStatus.completed,
      ),
      EarningsEntry(
        id: '3',
        patientName: 'Emily Davis',
        type: 'Video',
        date: now.subtract(const Duration(days: 4)),
        amount: 500,
        status: EarningsStatus.pending,
      ),
      EarningsEntry(
        id: '4',
        patientName: 'Robert Wilson',
        type: 'Video',
        date: now.subtract(const Duration(days: 7)),
        amount: 500,
        status: EarningsStatus.completed,
      ),
      EarningsEntry(
        id: '5',
        patientName: 'Lisa Anderson',
        type: 'Voice',
        date: now.subtract(const Duration(days: 12)),
        amount: 300,
        status: EarningsStatus.completed,
      ),
      EarningsEntry(
        id: '6',
        patientName: 'James Brown',
        type: 'Video',
        date: now.subtract(const Duration(days: 18)),
        amount: 500,
        status: EarningsStatus.pending,
      ),
      EarningsEntry(
        id: '7',
        patientName: 'Ava Patel',
        type: 'Video',
        date: now.subtract(const Duration(days: 24)),
        amount: 600,
        status: EarningsStatus.completed,
      ),
      EarningsEntry(
        id: '8',
        patientName: 'Oliver Smith',
        type: 'Voice',
        date: now.subtract(const Duration(days: 31)),
        amount: 300,
        status: EarningsStatus.completed,
      ),
      EarningsEntry(
        id: '9',
        patientName: 'Sophia Lee',
        type: 'Video',
        date: now.subtract(const Duration(days: 40)),
        amount: 500,
        status: EarningsStatus.completed,
      ),
    ];
  }

  List<EarningsEntry> _applyFilters(List<EarningsEntry> entries) {
    final now = DateTime.now();
    DateTime? startDate;
    if (_selectedRange == EarningsRange.week) {
      startDate = now.subtract(const Duration(days: 7));
    } else if (_selectedRange == EarningsRange.month) {
      startDate = now.subtract(const Duration(days: 30));
    }

    return entries.where((entry) {
      final matchesRange =
          startDate == null || entry.date.isAfter(startDate);
      final matchesStatus = _selectedStatus == EarningsStatus.all ||
          entry.status == _selectedStatus;
      return matchesRange && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<List<EarningsEntry>>(
        future: _earningsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Unable to load earnings',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _earningsFuture = _loadEarnings();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final entries = _applyFilters(snapshot.data ?? []);
          final totals = _calculateTotals(entries);

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(),
                    const SizedBox(height: 20),
                    _buildSummaryCards(constraints.maxWidth, totals),
                    const SizedBox(height: 24),
                    Text(
                      'Recent Earnings',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (entries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'No earnings found for the selected filters.',
                          style: GoogleFonts.roboto(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: entries
                            .map((entry) => _buildEarningCard(entry))
                            .toList(),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<String, dynamic> _calculateTotals(List<EarningsEntry> entries) {
    int total = 0;
    int completed = 0;
    int pending = 0;
    for (final entry in entries) {
      total += entry.amount;
      if (entry.status == EarningsStatus.completed) {
        completed += entry.amount;
      } else {
        pending += entry.amount;
      }
    }
    final average = entries.isEmpty ? 0 : (total / entries.length).round();
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'count': entries.length,
      'average': average,
    };
  }

  Widget _buildFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildRangeChip('This Week', EarningsRange.week),
            _buildRangeChip('This Month', EarningsRange.month),
            _buildRangeChip('All Time', EarningsRange.all),
            _buildStatusChip('All', EarningsStatus.all),
            _buildStatusChip('Completed', EarningsStatus.completed),
            _buildStatusChip('Pending', EarningsStatus.pending),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeChip(String label, EarningsRange range) {
    final selected = _selectedRange == range;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        if (!value) return;
        setState(() {
          _selectedRange = range;
        });
      },
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.roboto(
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.primaryBlue : AppColors.textGrey,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primaryBlue : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStatusChip(String label, EarningsStatus status) {
    final selected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (value) {
        if (!value) return;
        setState(() {
          _selectedStatus = status;
        });
      },
      selectedColor: Colors.green.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.roboto(
        fontWeight: FontWeight.w600,
        color: selected ? Colors.green : AppColors.textGrey,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildSummaryCards(
    double maxWidth,
    Map<String, dynamic> totals,
  ) {
    final columns = maxWidth >= 900
        ? 4
        : maxWidth >= 600
            ? 2
            : 1;
    final spacing = 12.0;
    final itemWidth = (maxWidth - (columns - 1) * spacing) / columns;
    final cards = [
      _SummaryCardData(
        title: 'Total Earnings',
        value: '₹${totals['total']}',
        color: const Color(0xFF4C6FFF),
      ),
      _SummaryCardData(
        title: 'Completed',
        value: '₹${totals['completed']}',
        color: const Color(0xFF00C853),
      ),
      _SummaryCardData(
        title: 'Pending',
        value: '₹${totals['pending']}',
        color: const Color(0xFFFFAB00),
      ),
      _SummaryCardData(
        title: 'Avg / Consult',
        value: '₹${totals['average']}',
        color: const Color(0xFF7C3AED),
      ),
    ];

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: cards
          .map(
            (card) => SizedBox(
              width: itemWidth,
              child: _buildSummaryCard(card),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSummaryCard(_SummaryCardData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: data.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningCard(EarningsEntry entry) {
    final statusColor = entry.status == EarningsStatus.completed
        ? const Color(0xFF00C853)
        : const Color(0xFFFFAB00);
    final statusLabel =
        entry.status == EarningsStatus.completed ? 'Completed' : 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              entry.type == 'Video'
                  ? Icons.videocam_outlined
                  : Icons.phone_outlined,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.patientName,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.type} • ${_formatDate(entry.date)}',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${entry.amount}',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }
}

class _SummaryCardData {
  final String title;
  final String value;
  final Color color;

  _SummaryCardData({
    required this.title,
    required this.value,
    required this.color,
  });
}
