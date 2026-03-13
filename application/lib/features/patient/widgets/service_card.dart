import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String route;

  const ServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Use brighter colors in dark mode
    Color displayIconColor;
    if (isDark) {
      if (iconColor == Colors.orange) {
        displayIconColor = Colors.orange.shade300;
      } else if (iconColor == Colors.green) {
        displayIconColor = Colors.green.shade300;
      } else if (iconColor == AppColors.primaryBlue) {
        displayIconColor = Colors.blue.shade300;
      } else if (iconColor == AppColors.error) {
        displayIconColor = Colors.red.shade300;
      } else {
        displayIconColor = iconColor;
      }
    } else {
      displayIconColor = iconColor;
    }

    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: displayIconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: displayIconColor, size: 28),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: isDark ? Colors.white70 : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
