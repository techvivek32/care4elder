import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PatientBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PatientBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      surfaceTintColor: Colors.white,
      height: 80,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildNavItem(
              0,
              Icons.home_rounded,
              Icons.home_outlined,
              'Home',
            ),
          ),
          Expanded(
            child: _buildNavItem(
              1,
              Icons.monitor_heart,
              Icons.monitor_heart_outlined,
              'Consult',
            ),
          ),
          Expanded(
            child: _buildNavItem(
              2,
              Icons.sos_rounded,
              Icons.sos_outlined,
              'SOS',
              activeColor: const Color(0xFFFF3B30),
              isEmergency: true,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              3,
              Icons.description,
              Icons.description_outlined,
              'Records',
            ),
          ),
          Expanded(
            child: _buildNavItem(
              4,
              Icons.person,
              Icons.person_outline,
              'Profile',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label, {
    Color? activeColor,
    bool isEmergency = false,
  }) {
    final isSelected = currentIndex == index;
    final themeColor = activeColor ?? AppColors.primaryBlue;

    return Semantics(
      button: true,
      label: isEmergency ? 'Emergency SOS' : label,
      hint: 'Navigate to $label tab',
      selected: isSelected,
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: isSelected
                    ? const EdgeInsets.all(10)
                    : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isSelected
                      ? themeColor.withValues(alpha: 0.2)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected
                      ? themeColor
                      : (isEmergency
                            ? themeColor.withValues(alpha: 0.7)
                            : AppColors.textGrey),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? themeColor
                      : (isEmergency
                            ? themeColor.withValues(alpha: 0.7)
                            : AppColors.textGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PatientSOSButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PatientSOSButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFF0000), // Red #FF0000
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0000).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: 'SOS',
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.error_outline_rounded,
          size: 24, // 24dp icon
          color: Colors.white,
        ),
      ),
    );
  }
}
