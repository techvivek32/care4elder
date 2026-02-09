import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class DoctorAvailabilityScreen extends StatefulWidget {
  const DoctorAvailabilityScreen({super.key});

  @override
  State<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState extends State<DoctorAvailabilityScreen> {
  bool _vacationMode = false;
  String _selectedTimezone = 'Asia/Kolkata (GMT+05:30)';

  // Mock data structure for availability
  final Map<String, DaySchedule> _schedule = {
    'Monday': DaySchedule(
      isOpen: true,
      slots: [
        TimeSlot(start: '09:00 AM', end: '05:00 PM'),
        TimeSlot(start: '02:00 PM', end: '06:00 PM'),
      ],
    ),
    'Tuesday': DaySchedule(
      isOpen: true,
      slots: [TimeSlot(start: '09:00 AM', end: '05:00 PM')],
    ),
    'Wednesday': DaySchedule(
      isOpen: true,
      slots: [TimeSlot(start: '09:00 AM', end: '05:00 PM')],
    ),
    'Thursday': DaySchedule(
      isOpen: true,
      slots: [TimeSlot(start: '09:00 AM', end: '05:00 PM')],
    ),
    'Friday': DaySchedule(
      isOpen: true,
      slots: [TimeSlot(start: '09:00 AM', end: '05:00 PM')],
    ),
    'Saturday': DaySchedule(
      isOpen: true,
      slots: [TimeSlot(start: '09:00 AM', end: '05:00 PM')],
    ),
    'Sunday': DaySchedule(isOpen: false, slots: []),
  };

  final List<String> _daysOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: Text(
          'Availability',
          style: GoogleFonts.roboto(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vacation Mode
                  Container(
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vacation Mode',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pause all consultations',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _vacationMode,
                          onChanged: (value) {
                            setState(() {
                              _vacationMode = value;
                            });
                          },
                          activeThumbColor: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Timezone Selector
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                    child: Row(
                      children: [
                        const Icon(Icons.public, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timezone',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedTimezone,
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  color: AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Mock timezone selection
                            setState(() {
                              if (_selectedTimezone.contains('Kolkata')) {
                                _selectedTimezone =
                                    'America/New_York (GMT-04:00)';
                              } else {
                                _selectedTimezone = 'Asia/Kolkata (GMT+05:30)';
                              }
                            });
                          },
                          child: Text(
                            'Change',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 12),
                    child: Text(
                      'WORKING HOURS',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // Days List
                  ..._daysOrder.map((day) => _buildDayCard(day)),
                ],
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Changes saved successfully')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day) {
    final schedule = _schedule[day]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                day,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              Switch(
                value: schedule.isOpen,
                onChanged: (value) {
                  setState(() {
                    schedule.isOpen = value;
                  });
                },
                activeThumbColor: AppColors.primaryBlue,
              ),
            ],
          ),

          if (schedule.isOpen) ...[
            const SizedBox(height: 20),
            // Time Slots
            ...schedule.slots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    _buildTimeChip(slot.start, slot, true),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'to',
                        style: GoogleFonts.roboto(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _buildTimeChip(slot.end, slot, false),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          schedule.slots.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }),

            // Add Slot Button
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  schedule.slots.add(
                    TimeSlot(start: '09:00 AM', end: '05:00 PM'),
                  );
                });
              },
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'Add Time Slot',
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                backgroundColor: const Color(0xFFF1F5F9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectTime(TimeSlot slot, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        final localizations = MaterialLocalizations.of(context);
        final formatted = localizations.formatTimeOfDay(picked);
        if (isStart) {
          slot.start = formatted;
        } else {
          slot.end = formatted;
        }
      });
    }
  }

  Widget _buildTimeChip(String time, TimeSlot slot, bool isStart) {
    return InkWell(
      onTap: () => _selectTime(slot, isStart),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(
              time,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class DaySchedule {
  bool isOpen;
  final List<TimeSlot> slots;

  DaySchedule({required this.isOpen, required this.slots});
}

class TimeSlot {
  String start;
  String end;

  TimeSlot({required this.start, required this.end});
}
