import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color secondaryBlue = Color(0xFF0055DD);
  static const Color lightBlue = Color(0xFF4DA6FF);
  static const Color white = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGrey = Color(0xFF757575);
  static const Color error = Color(0xFFD32F2F);
  
  // Gradient for the patient screen background
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF007AFF), // Vibrant Blue
      Color(0xFF0055DD), // Slightly darker blue
    ],
  );
}
