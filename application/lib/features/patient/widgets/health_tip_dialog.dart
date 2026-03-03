import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/health_tip_service.dart';
import '../../../core/theme/app_colors.dart';

void showHealthTipDetail(BuildContext context, HealthTip tip) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: isDark ? Colors.yellow.shade600 : AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tip.title,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            tip.description,
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: isDark ? Colors.white70 : AppColors.textGrey,
              height: 1.6,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'CLOSE',
              style: GoogleFonts.roboto(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      );
    },
  );
}
