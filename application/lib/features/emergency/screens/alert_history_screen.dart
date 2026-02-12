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
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
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
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<CancellationReason>(
                    dropdownColor: colorScheme.surface,
                    style: GoogleFonts.roboto(color: colorScheme.onSurface),
                    value: _selectedReason,
                    decoration: InputDecoration(
                      labelText: 'Cancellation Reason',
                      labelStyle: GoogleFonts.roboto(color: colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<CancellationReason>(
                        value: null,
                        child: Text(
                          'All Reasons',
                          style: GoogleFonts.roboto(color: colorScheme.onSurface),
                        ),
                      ),
                      ...CancellationReason.values.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(
                            reason.label,
                            style: GoogleFonts.roboto(color: colorScheme.onSurface),
                          ),
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
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alert History',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: GoogleFonts.roboto(color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search logs...',
                hintStyle: GoogleFonts.roboto(color: colorScheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                        color: colorScheme.onSurfaceVariant,
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
                        elevation: 0,
                        color: colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        child: ExpansionTile(
                          shape: const RoundedRectangleBorder(side: BorderSide.none),
                          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                          iconColor: colorScheme.primary,
                          collapsedIconColor: colorScheme.onSurfaceVariant,
                          title: Text(
                            log.reason.label,
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'MMM d, yyyy h:mm a',
                            ).format(log.timestamp),
                            style: GoogleFonts.roboto(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.error.withOpacity(0.1),
                            child: Icon(
                              Icons.history,
                              color: colorScheme.error,
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
                                  Divider(color: colorScheme.outlineVariant),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Original Alert Details',
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.originalAlertDetails.toString(),
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: colorScheme.onSurface,
                                    ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
