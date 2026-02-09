import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../services/emergency_audit_service.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});

  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  final EmergencyAuditService _auditService = EmergencyAuditService();
  String _searchQuery = '';
  CancellationReason? _selectedReason;
  late List<CancellationLog> _filteredLogs;

  @override
  void initState() {
    super.initState();
    _updateFilteredLogs();
    _auditService.addListener(_updateFilteredLogs);
  }

  @override
  void dispose() {
    _auditService.removeListener(_updateFilteredLogs);
    super.dispose();
  }

  void _updateFilteredLogs() {
    setState(() {
      _filteredLogs = _auditService.filterLogs(
        searchQuery: _searchQuery,
        reason: _selectedReason,
      );
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter History',
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<CancellationReason>(
                    initialValue: _selectedReason,
                    decoration: InputDecoration(
                      labelText: 'Cancellation Reason',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<CancellationReason>(
                        value: null,
                        child: Text('All Reasons'),
                      ),
                      ...CancellationReason.values.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(reason.label),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setSheetState(() => _selectedReason = value);
                      setState(() => _selectedReason = value);
                      _updateFilteredLogs();
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alert History',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
                _updateFilteredLogs();
              },
            ),
          ),
          Expanded(
            child: _filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      'No logs found',
                      style: GoogleFonts.roboto(
                        color: AppColors.textGrey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ExpansionTile(
                          title: Text(
                            log.reason.label,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'MMM d, yyyy h:mm a',
                            ).format(log.timestamp),
                            style: GoogleFonts.roboto(
                              color: AppColors.textGrey,
                              fontSize: 12,
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.error.withValues(
                              alpha: 0.1,
                            ),
                            child: const Icon(
                              Icons.history,
                              color: AppColors.error,
                              size: 20,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow('User ID', log.userId),
                                  const SizedBox(height: 8),
                                  _buildDetailRow('Log ID', log.id),
                                  if (log.comments != null &&
                                      log.comments!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _buildDetailRow('Comments', log.comments!),
                                  ],
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Original Alert Details',
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppColors.textGrey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.originalAlertDetails.toString(),
                                    style: GoogleFonts.roboto(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(color: AppColors.textDark, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
