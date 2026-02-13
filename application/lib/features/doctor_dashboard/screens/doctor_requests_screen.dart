import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class DoctorRequestsScreen extends StatefulWidget {
  const DoctorRequestsScreen({super.key});

  @override
  State<DoctorRequestsScreen> createState() => _DoctorRequestsScreenState();
}

class _DoctorRequestsScreenState extends State<DoctorRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<ConsultationRequest> _requests;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _requests = [
      ConsultationRequest(
        id: '1',
        name: 'Sarah Johnson',
        type: 'Video Call',
        time: '10:30 AM',
        symptom:
            'Experiencing recurring headaches and dizziness for the past 3 days',
        image: 'assets/images/patient_female_1.png',
        status: RequestStatus.pending,
      ),
      ConsultationRequest(
        id: '2',
        name: 'Mike Chen',
        type: 'Voice Call',
        time: '11:00 AM',
        symptom: 'Follow-up consultation for blood pressure medication',
        image: 'assets/images/patient_male_1.png',
        status: RequestStatus.pending,
      ),
      ConsultationRequest(
        id: '3',
        name: 'Emily Davis',
        type: 'Video Call',
        time: '11:30 AM',
        symptom: 'Skin rash on arms, itchy and spreading',
        image: 'assets/images/patient_female_2.png',
        status: RequestStatus.pending,
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _requests
        .where((req) => req.status == RequestStatus.pending)
        .length;
    final acceptedCount = _requests
        .where((req) => req.status == RequestStatus.accepted)
        .length;
    final rejectedCount = _requests
        .where((req) => req.status == RequestStatus.rejected)
        .length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
        elevation: 0,
        title: Text(
          'Consultation Requests',
          style: GoogleFonts.roboto(
            color: isDark ? Colors.white : AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: isDark ? Colors.white10 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkPremiumGradient
                      : AppColors.premiumGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.white38 : AppColors.textGrey,
                labelStyle: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
                unselectedLabelStyle: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
                tabs: [
                  Tab(
                    child: FittedBox(
                      child: Text(
                        'Pending ($pendingCount)',
                        style: GoogleFonts.roboto(
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: FittedBox(
                      child: Text(
                        'Accepted ($acceptedCount)',
                        style: GoogleFonts.roboto(
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                  Tab(
                    child: FittedBox(
                      child: Text(
                        'Rejected ($rejectedCount)',
                        style: GoogleFonts.roboto(
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(RequestStatus.pending),
                _buildRequestsList(RequestStatus.accepted),
                _buildRequestsList(RequestStatus.rejected),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(RequestStatus status) {
    final filtered = _requests.where((req) => req.status == status).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          status == RequestStatus.pending
              ? 'No pending requests'
              : status == RequestStatus.accepted
              ? 'No accepted requests'
              : 'No rejected requests',
          style: GoogleFonts.roboto(
            color: isDark ? Colors.white38 : AppColors.textGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      key: PageStorageKey<String>('doctor-requests-$status'),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(filtered[index]);
      },
    );
  }

  void _updateStatus(ConsultationRequest request, RequestStatus status) {
    setState(() {
      final index = _requests.indexWhere((item) => item.id == request.id);
      if (index != -1) {
        _requests[index] = _requests[index].copyWith(status: status);
      }
    });
  }

  Widget _buildRequestCard(ConsultationRequest req) {
    final isVideo = req.type == 'Video Call';
    final statusLabel = _statusLabel(req.status);
    final statusColor = _statusColor(req.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          final extra = {
            'id': req.id,
            'name': req.name,
            'type': req.type,
            'time': req.time,
            'symptom': req.symptom,
            'image': req.image,
          };
          context.push('/doctor/request-details/${req.id}', extra: extra);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isDark ? Border.all(color: Colors.white.withOpacity(0.05)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                    backgroundImage: AssetImage(req.image),
                    onBackgroundImageError: (exception, stackTrace) {},
                    child: Icon(Icons.person,
                        color: isDark ? Colors.white24 : Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              req.name,
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppColors.textDark,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusLabel,
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isVideo
                                      ? Icons.videocam_outlined
                                      : Icons.phone_outlined,
                                  size: 16,
                                  color: isDark ? Colors.white38 : AppColors.textGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  req.type,
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: isDark ? Colors.white38 : AppColors.textGrey,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: isDark ? Colors.white38 : AppColors.textGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  req.time,
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: isDark ? Colors.white38 : AppColors.textGrey,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                req.symptom,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : AppColors.textGrey,
                  height: 1.4,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButtons(req),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ConsultationRequest request) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (request.status == RequestStatus.pending) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkPremiumGradient
                    : AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(12),
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
                  _updateStatus(request, RequestStatus.accepted);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request accepted')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Accept',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _updateStatus(request, RequestStatus.rejected);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request rejected')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Reject',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (request.status == RequestStatus.accepted) {
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkPremiumGradient
                    : AppColors.premiumGradient,
                borderRadius: BorderRadius.circular(12),
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
                  context.push('/doctor/call/${request.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Start Call',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _updateStatus(request, RequestStatus.rejected);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request rejected')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Reject',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.darkPremiumGradient
                  : AppColors.premiumGradient,
              borderRadius: BorderRadius.circular(12),
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
                _updateStatus(request, RequestStatus.accepted);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Request accepted')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Accept',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _statusLabel(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.rejected:
        return 'rejected';
    }
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.green;
      case RequestStatus.rejected:
        return Colors.red;
    }
  }
}

enum RequestStatus { pending, accepted, rejected }

class ConsultationRequest {
  final String id;
  final String name;
  final String type;
  final String time;
  final String symptom;
  final String image;
  final RequestStatus status;

  ConsultationRequest({
    required this.id,
    required this.name,
    required this.type,
    required this.time,
    required this.symptom,
    required this.image,
    required this.status,
  });

  ConsultationRequest copyWith({RequestStatus? status}) {
    return ConsultationRequest(
      id: id,
      name: name,
      type: type,
      time: time,
      symptom: symptom,
      image: image,
      status: status ?? this.status,
    );
  }
}
