import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/call_request_service.dart';
import '../../doctor_auth/services/doctor_auth_service.dart';
import 'doctor_history_detail_screen.dart';

class DoctorHistoryScreen extends StatefulWidget {
  const DoctorHistoryScreen({super.key});

  @override
  State<DoctorHistoryScreen> createState() => _DoctorHistoryScreenState();
}

class _DoctorHistoryScreenState extends State<DoctorHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<ConsultationHistoryItem> _allItems = [];
  HistoryStatusFilter _statusFilter = HistoryStatusFilter.all;
  HistoryTypeFilter _typeFilter = HistoryTypeFilter.all;
  HistoryDateFilter _dateFilter = HistoryDateFilter.all;
  ConsultationHistoryItem? _selectedItem;
  final CallRequestService _callService = CallRequestService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _syncSelectionWithFilters();
      });
    });
    _loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final token = await DoctorAuthService().getDoctorToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final history = await _callService.getDoctorHistory(token: token);
      
      _allItems = history.map((data) {
        return ConsultationHistoryItem(
          id: data.id,
          name: data.patientName,
          type: data.consultationType == 'consultation' ? 'Video' : 'Voice',
          duration: '${(data.duration / 60).ceil()} min',
          date: data.createdAt,
          status: data.status == 'completed' ? HistoryStatus.completed : HistoryStatus.cancelled,
          price: data.baseFee > 0 ? data.baseFee.toInt() : data.fee.toInt(),
          image: data.patientProfile.isNotEmpty ? data.patientProfile : '',
          notes: data.report,
          prescription: '',
          followUp: '',
          originalData: data,
        );
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<ConsultationHistoryItem> get _filteredItems {
    final search = _searchController.text.trim().toLowerCase();
    return _allItems.where((item) {
      final matchesSearch =
          search.isEmpty ||
          item.name.toLowerCase().contains(search) ||
          item.notes.toLowerCase().contains(search) ||
          item.type.toLowerCase().contains(search);
      final matchesStatus =
          _statusFilter == HistoryStatusFilter.all ||
          (_statusFilter == HistoryStatusFilter.completed &&
              item.status == HistoryStatus.completed) ||
          (_statusFilter == HistoryStatusFilter.cancelled &&
              item.status == HistoryStatus.cancelled);
      final matchesType =
          _typeFilter == HistoryTypeFilter.all ||
          (_typeFilter == HistoryTypeFilter.video && item.type == 'Video') ||
          (_typeFilter == HistoryTypeFilter.voice && item.type == 'Voice');
      final matchesDate =
          _dateFilter == HistoryDateFilter.all ||
          (_dateFilter == HistoryDateFilter.last7 &&
              item.date.isAfter(
                DateTime.now().subtract(const Duration(days: 7)),
              )) ||
          (_dateFilter == HistoryDateFilter.last30 &&
              item.date.isAfter(
                DateTime.now().subtract(const Duration(days: 30)),
              )) ||
          (_dateFilter == HistoryDateFilter.thisYear &&
              item.date.year == DateTime.now().year);
      return matchesSearch && matchesStatus && matchesType && matchesDate;
    }).toList();
  }

  void _syncSelectionWithFilters() {
    final filtered = _filteredItems;
    if (filtered.isEmpty) {
      _selectedItem = null;
      return;
    }
    if (_selectedItem == null ||
        !filtered.any((item) => item.id == _selectedItem!.id)) {
      _selectedItem = filtered.first;
    }
  }

  HistoryStats get _stats {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    
    // Calculate This Month's completed consultations
    final thisMonthCount = _allItems.where((item) => 
      item.status == HistoryStatus.completed && 
      item.date.isAfter(firstDayOfMonth)
    ).length;

    // Calculate total earnings from all completed consultations
    final totalEarnings = _allItems.where((item) => 
      item.status == HistoryStatus.completed
    ).fold<int>(
      0,
      (sum, item) => sum + item.price,
    );

    // Calculate average rating from all completed consultations that have a rating
    final ratedItems = _allItems.where((item) => 
      item.originalData?.rating != null && 
      item.originalData!.rating! > 0
    ).toList();
    
    double averageRating = 4.9; // Default if no ratings
    if (ratedItems.isNotEmpty) {
      final totalRating = ratedItems.fold<double>(
        0,
        (sum, item) => sum + item.originalData!.rating!,
      );
      averageRating = totalRating / ratedItems.length;
    }

    return HistoryStats(
      totalCount: thisMonthCount,
      totalEarnings: totalEarnings,
      rating: averageRating,
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchController.clear();
      }
      _syncSelectionWithFilters();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.darkBackground
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter History',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Status',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: HistoryStatusFilter.values.map((value) {
                        return _buildFilterChip(
                          label: value.label,
                          selected: _statusFilter == value,
                          onTap: () {
                            setSheetState(() => _statusFilter = value);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Type',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: HistoryTypeFilter.values.map((value) {
                        return _buildFilterChip(
                          label: value.label,
                          selected: _typeFilter == value,
                          onTap: () {
                            setSheetState(() => _typeFilter = value);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Date Range',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: HistoryDateFilter.values.map((value) {
                        return _buildFilterChip(
                          label: value.label,
                          selected: _dateFilter == value,
                          onTap: () {
                            setSheetState(() => _dateFilter = value);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _statusFilter = HistoryStatusFilter.all;
                                _typeFilter = HistoryTypeFilter.all;
                                _dateFilter = HistoryDateFilter.all;
                                _syncSelectionWithFilters();
                              });
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isDark ? Colors.white : AppColors.textDark,
                              side: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: isDark
                                  ? AppColors.darkPremiumGradient
                                  : AppColors.premiumGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _syncSelectionWithFilters();
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Consultation History',
                        style: GoogleFonts.roboto(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleSearch,
                          icon: Icon(Icons.search,
                              color: isDark ? Colors.white70 : Colors.black54),
                          tooltip: 'Search',
                        ),
                        IconButton(
                          onPressed: _showFilterSheet,
                          icon: Icon(
                            Icons.filter_list,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          tooltip: 'Filter',
                        ),
                      ],
                    ),
                  ],
                ),
                if (_showSearch) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: GoogleFonts.roboto(
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search patients, notes, or type',
                      hintStyle: GoogleFonts.roboto(
                        color: isDark ? Colors.white38 : AppColors.textGrey,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(Icons.search,
                          color: isDark ? Colors.white70 : Colors.black54),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54),
                              onPressed: () => _searchController.clear(),
                            ),
                      filled: true,
                      fillColor: isDark ? AppColors.darkCardBackground : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCard(
                      label: 'This Month',
                      value: '${stats.totalCount}',
                      valueColor: const Color(0xFF4C6FFF),
                    ),
                    _buildStatCard(
                      label: 'Earnings',
                      value: '₹${stats.totalEarnings}',
                      valueColor: const Color(0xFF00C853),
                    ),
                    _buildStatCard(
                      label: 'Rating',
                      value: stats.rating.toStringAsFixed(1),
                      valueColor: const Color(0xFFFFAB00),
                      showStar: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.roboto(
                            color: isDark ? Colors.white : AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 120,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? AppColors.darkPremiumGradient
                                : AppColors.premiumGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton(
                            onPressed: _loadHistory,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_filteredItems.isEmpty)
                  Center(
                    child: Text(
                      'No history matches your search or filters.',
                      style: GoogleFonts.roboto(
                        color: isDark ? Colors.white70 : AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _buildHistoryCard(item);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? (isDark ? AppColors.darkPremiumGradient : AppColors.premiumGradient)
              : null,
          color: selected
              ? null
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : AppColors.textDark),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color valueColor,
    bool showStar = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : AppColors.primaryBlue.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: isDark ? Colors.white38 : AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showStar) ...[
                  const Icon(Icons.star, color: Color(0xFFFFAB00), size: 16),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [valueColor, valueColor.withOpacity(0.3)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ConsultationHistoryItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedDate =
        '${item.date.day} ${_getMonth(item.date.month)} ${item.date.year}';

    return InkWell(
      onTap: () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DoctorHistoryDetailScreen(
                callRequest: item.originalData!,
              ),
            ),
          ).then((_) => _loadHistory());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : AppColors.primaryBlue.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : AppColors.primaryBlue.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        (item.status == HistoryStatus.completed
                                ? Colors.green
                                : Colors.red)
                            .withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isDark ? AppColors.darkPremiumGradient : AppColors.premiumGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkCardBackground : Colors.white,
                        ),
                        child: ClipOval(
                          child: item.image.isNotEmpty
                              ? Image.network(
                                  item.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
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
                                item.name,
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textDark,
                                ),
                              ),
                              Text(
                                '₹${item.price}',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                item.type == 'Video'
                                    ? Icons.videocam
                                    : Icons.call,
                                size: 14,
                                color: isDark ? Colors.white54 : AppColors.textGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.type} • ${item.duration}',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: isDark ? Colors.white54 : AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formattedDate,
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : AppColors.textGrey,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (item.status == HistoryStatus.completed
                                          ? Colors.green
                                          : Colors.red)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.status == HistoryStatus.completed
                                      ? 'Completed'
                                      : 'Cancelled',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: item.status == HistoryStatus.completed
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class ConsultationHistoryItem {
  final String id;
  final String name;
  final String type;
  final String duration;
  final DateTime date;
  final HistoryStatus status;
  final int price;
  final String image;
  final String notes;
  final String prescription;
  final String followUp;
  final CallRequestData? originalData;

  ConsultationHistoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.duration,
    required this.date,
    required this.status,
    required this.price,
    required this.image,
    required this.notes,
    required this.prescription,
    required this.followUp,
    this.originalData,
  });
}

class HistoryStats {
  final int totalCount;
  final int totalEarnings;
  final double rating;

  HistoryStats({
    required this.totalCount,
    required this.totalEarnings,
    required this.rating,
  });
}

enum HistoryStatus { completed, cancelled }

extension HistoryStatusLabel on HistoryStatus {
  String get label {
    switch (this) {
      case HistoryStatus.completed:
        return 'Completed';
      case HistoryStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum HistoryStatusFilter { all, completed, cancelled }

extension HistoryStatusFilterLabel on HistoryStatusFilter {
  String get label {
    switch (this) {
      case HistoryStatusFilter.all:
        return 'All';
      case HistoryStatusFilter.completed:
        return 'Completed';
      case HistoryStatusFilter.cancelled:
        return 'Cancelled';
    }
  }
}

enum HistoryTypeFilter { all, video, voice }

extension HistoryTypeFilterLabel on HistoryTypeFilter {
  String get label {
    switch (this) {
      case HistoryTypeFilter.all:
        return 'All';
      case HistoryTypeFilter.video:
        return 'Video';
      case HistoryTypeFilter.voice:
        return 'Voice';
    }
  }
}

enum HistoryDateFilter { all, last7, last30, thisYear }

extension HistoryDateFilterLabel on HistoryDateFilter {
  String get label {
    switch (this) {
      case HistoryDateFilter.all:
        return 'All Time';
      case HistoryDateFilter.last7:
        return 'Last 7 Days';
      case HistoryDateFilter.last30:
        return 'Last 30 Days';
      case HistoryDateFilter.thisYear:
        return 'This Year';
    }
  }
}
