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
          price: data.fee.toInt(),
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
    final totalCount = _filteredItems.length;
    final totalEarnings = _filteredItems.fold<int>(
      0,
      (sum, item) => sum + item.price,
    );
    return HistoryStats(
      totalCount: totalCount,
      totalEarnings: totalEarnings,
      rating: 4.9,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Status',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
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
                        color: AppColors.textDark,
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
                        color: AppColors.textDark,
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
                              foregroundColor: AppColors.textDark,
                              side: BorderSide(color: Colors.grey.shade300),
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
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _syncSelectionWithFilters();
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Apply Filters'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                    Text(
                      'Consultation History',
                      style: GoogleFonts.roboto(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _toggleSearch,
                          icon: const Icon(Icons.search, color: Colors.black54),
                          tooltip: 'Search',
                        ),
                        IconButton(
                          onPressed: _showFilterSheet,
                          icon: const Icon(
                            Icons.filter_list,
                            color: Colors.black54,
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
                    decoration: InputDecoration(
                      hintText: 'Search patients, notes, or type',
                      hintStyle: GoogleFonts.roboto(
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _searchController.clear(),
                            ),
                      filled: true,
                      fillColor: Colors.white,
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
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadHistory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (_filteredItems.isEmpty)
                  Center(
                    child: Text(
                      'No history matches your search or filters.',
                      style: GoogleFonts.roboto(
                        color: AppColors.textGrey,
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.12),
      backgroundColor: Colors.white,
      labelStyle: GoogleFonts.roboto(
        fontWeight: FontWeight.w600,
        color: selected ? AppColors.primaryBlue : AppColors.textGrey,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(
        color: selected ? AppColors.primaryBlue : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color valueColor,
    bool showStar = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.roboto(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
                if (showStar) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.star, color: Color(0xFFFFAB00), size: 20),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(ConsultationHistoryItem item) {
    final isSelected = _selectedItem?.id == item.id;
    final statusColor = item.status == HistoryStatus.completed
        ? const Color(0xFF2E7D32)
        : const Color(0xFFD32F2F);
    final statusBg = item.status == HistoryStatus.completed
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isSelected
            ? Border.all(color: AppColors.primaryBlue, width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: item.image.isNotEmpty
                  ? NetworkImage(item.image)
                  : const AssetImage('assets/images/logo.png') as ImageProvider,
              backgroundColor: Colors.grey[200],
              onBackgroundImageError: (exception, stackTrace) {},
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        item.type == 'Video'
                            ? Icons.videocam_outlined
                            : Icons.phone_outlined,
                        size: 16,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.type} • ${item.duration}',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(item.date),
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status.label,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  item.price == 0 ? '-' : '₹${item.price}',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(ConsultationHistoryItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Patient', item.name),
          const SizedBox(height: 10),
          _buildDetailRow('Type', item.type),
          const SizedBox(height: 10),
          _buildDetailRow('Duration', item.duration),
          const SizedBox(height: 10),
          _buildDetailRow('Date', _formatDate(item.date)),
          const SizedBox(height: 10),
          _buildDetailRow('Status', item.status.label),
          const SizedBox(height: 10),
          _buildDetailRow('Notes', item.notes),
          const SizedBox(height: 10),
          _buildDetailRow('Prescription', item.prescription),
          const SizedBox(height: 10),
          _buildDetailRow('Follow-up', item.followUp),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            title,
            style: GoogleFonts.roboto(
              color: AppColors.textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
