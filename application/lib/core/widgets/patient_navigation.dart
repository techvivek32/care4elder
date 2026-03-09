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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: isDark ? const Color(0xFF01080E) : Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.1),
      surfaceTintColor: Colors.transparent,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(
            context,
            0,
            Icons.home_rounded,
            Icons.home_outlined,
            'Home',
            currentIndex,
            isDark,
          ),
          _buildNavItem(
            context,
            1,
            Icons.monitor_heart,
            Icons.monitor_heart_outlined,
            'Consult',
            currentIndex,
            isDark,
          ),
          _buildNavItem(
            context,
            2,
            Icons.emergency_rounded,
            Icons.emergency_outlined,
            'SOS',
            currentIndex,
            isDark,
            activeColor: const Color(0xFFFF3B30),
            isEmergency: true,
          ),
          _buildNavItem(
            context,
            3,
            Icons.description,
            Icons.description_outlined,
            'Records',
            currentIndex,
            isDark,
          ),
          _buildNavItem(
            context,
            4,
            Icons.person,
            Icons.person_outline,
            'Profile',
            currentIndex,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int currentIndex,
    bool isDark, {
    Color? activeColor,
    bool isEmergency = false,
  }) {
    final isSelected = currentIndex == index;
    final themeColor = isDark ? const Color(0xFF2196F3) : const Color(0xFF1565C0);

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isEmergency ? activeColor : themeColor)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white38 : const Color(0xFF757575)),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
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
            color: const Color(0xFFFF0000).withOpacity(0.3),
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
