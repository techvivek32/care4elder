import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/call_request_service.dart';
import '../../doctor_auth/services/doctor_auth_service.dart';
import 'doctor_history_detail_screen.dart';
import 'package:intl/intl.dart';

class DoctorRecordsScreen extends StatefulWidget {
  const DoctorRecordsScreen({super.key});

  @override
  State<DoctorRecordsScreen> createState() => _DoctorRecordsScreenState();
}

class _DoctorRecordsScreenState extends State<DoctorRecordsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<CallRequestData> _records = [];
  final CallRequestService _callService = CallRequestService();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
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
      
      // Deduplicate patients: Group by patientId and keep the most recent record
      final Map<String, CallRequestData> uniquePatients = {};
      for (var record in history) {
        // Skip if patientId is missing or empty
        if (record.patientId.isEmpty) continue;

        if (!uniquePatients.containsKey(record.patientId)) {
          uniquePatients[record.patientId] = record;
        } else {
          // Keep the latest record for this patient
          if (record.createdAt.isAfter(uniquePatients[record.patientId]!.createdAt)) {
            uniquePatients[record.patientId] = record;
          }
        }
      }
      
      _records = uniquePatients.values.toList();
      // Sort by most recent first
      _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        elevation: 0,
        title: Text(
          'Patient Records',
          style: GoogleFonts.roboto(
            color: isDark ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.roboto(
                      color: isDark ? Colors.white70 : AppColors.textDark,
                    ),
                  ),
                )
              : _records.isEmpty
                  ? Center(
                      child: Text(
                        'No records found',
                        style: GoogleFonts.roboto(
                          color: isDark ? Colors.white38 : AppColors.textGrey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return _buildRecordCard(record);
                      },
                    ),
    );
  }

  Widget _buildRecordCard(CallRequestData record) {
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(record.createdAt);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        if (mounted) {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) =>
                      DoctorHistoryDetailScreen(callRequest: record),
                ),
              )
              .then((_) => _loadRecords());
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
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isDark ? Colors.white : AppColors.primaryBlue).withOpacity(0.03),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isDark ? AppColors.darkPremiumGradient : AppColors.premiumGradient,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? AppColors.primaryBlue : AppColors.primaryBlue).withOpacity(0.2),
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
                    child: record.patientProfile.isNotEmpty
                        ? Image.network(
                            record.patientProfile,
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
                    Text(
                      record.patientName,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textDark,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isDark ? Colors.white54 : AppColors.textGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : AppColors.primaryBlue).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark ? Colors.white54 : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
