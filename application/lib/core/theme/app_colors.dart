import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF041E34); // Premium Dark Blue
  static const Color secondaryBlue = Color(0xFF020C15); // Deeper Dark Blue
  static const Color lightBlue = Color(0xFF1A3A5A); // Premium Highlight
  static const Color darkModeBlue = Color(0xFF1565C0); // Rich Blue for Dark Mode (not sky blue)
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);
  static const Color error = Color(0xFFD32F2F);
  
  // Premium Glossy Gradient (Light Mode) - Refined for "Glossy Blue" feel
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2196F3), // Vibrant Sky Blue Highlight
      Color(0xFF1565C0), // Rich Cobalt Blue
      Color(0xFF041E34), // Deep Navy Shadow
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Premium Glossy Gradient (Dark Mode)
  static const LinearGradient darkPremiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1565C0), // Rich cobalt
      Color(0xFF0D47A1), // Deep blue
      Color(0xFF041E34), // Very dark navy
    ],
    stops: [0.0, 0.6, 1.0],
  );

  // Legacy Gradient (Optional, keeping for compatibility if needed)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF041E34),
      Color(0xFF020C15),
    ],
  );
}
