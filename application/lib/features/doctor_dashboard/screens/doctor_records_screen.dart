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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Patient Records',
          style: GoogleFonts.roboto(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _records.isEmpty
                  ? const Center(child: Text('No records found'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return _buildRecordCard(record);
                      },
                    ),
    );
  }

  Widget _buildRecordCard(CallRequestData record) {
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(record.createdAt);
    
    return InkWell(
      onTap: () async {
        if (mounted) {
           Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DoctorHistoryDetailScreen(callRequest: record),
            ),
          ).then((_) => _loadRecords());
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBlue.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              backgroundImage: record.patientProfile.isNotEmpty
                  ? NetworkImage(record.patientProfile)
                  : const AssetImage('assets/images/logo.png') as ImageProvider,
              onBackgroundImageError: (_, __) {},
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.patientName,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}
