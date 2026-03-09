import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';

class DoctorShell extends StatefulWidget {
  final Widget child;

  const DoctorShell({super.key, required this.child});

  @override
  State<DoctorShell> createState() => _DoctorShellState();
}

class _DoctorShellState extends State<DoctorShell> {
  int _currentIndexFromLocation() {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/doctor/records')) {
      return 1;
    }
    if (location.startsWith('/doctor/history')) {
      return 2;
    }
    if (location.startsWith('/doctor/profile')) {
      return 3;
    }
    return 0;
  }

  Future<void> _handleBack() async {
    final currentIndex = _currentIndexFromLocation();
    if (currentIndex != 0) {
      context.go('/doctor/home');
      return;
    }
    final shouldExit = await _showExitDialog();
    if (shouldExit == true) {
      _exitApp();
    }
  }

  Future<bool?> _showExitDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Do you want to exit the app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  void _exitApp() {
    if (Platform.isAndroid || Platform.isIOS) {
      SystemNavigator.pop();
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/doctor/home');
        break;
      case 1:
        context.go('/doctor/records');
        break;
      case 2:
        context.go('/doctor/history');
        break;
      case 3:
        context.go('/doctor/profile');
        break;
    }
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int currentIndex,
    bool isDark,
  ) {
    final isSelected = currentIndex == index;
    final themeColor = isDark ? const Color(0xFF2196F3) : const Color(0xFF1565C0);

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? themeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white38 : AppColors.textGrey),
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

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndexFromLocation();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _handleBack();
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(context, 0, Icons.home, Icons.home_outlined, 'Home', currentIndex, isDark),
              _buildNavItem(context, 1, Icons.description, Icons.description_outlined, 'Records', currentIndex, isDark),
              _buildNavItem(context, 2, Icons.history, Icons.history, 'History', currentIndex, isDark),
              _buildNavItem(context, 3, Icons.person, Icons.person_outline, 'Profile', currentIndex, isDark),
            ],
          ),
        ),
      ),
    );
  }
}
