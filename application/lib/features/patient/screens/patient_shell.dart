import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/patient_navigation.dart';
import '../../emergency/services/fall_detection_service.dart';

class PatientShell extends StatefulWidget {
  final Widget child;
  final FallDetectionService? fallDetectionService;

  const PatientShell({
    super.key,
    required this.child,
    this.fallDetectionService,
  });

  @override
  State<PatientShell> createState() => _PatientShellState();
}

class _PatientShellState extends State<PatientShell> {
  late final FallDetectionService _fallDetectionService;

  @override
  void initState() {
    super.initState();
    _fallDetectionService =
        widget.fallDetectionService ?? FallDetectionService();
    _fallDetectionService.startMonitoring(_onFallDetected);
  }

  @override
  void dispose() {
    _fallDetectionService.stopMonitoring();
    super.dispose();
  }

  void _onFallDetected() {
    // Navigate to SOS screen with auto-start enabled
    if (mounted) {
      context.go('/patient/sos?autoStart=true');
    }
  }

  int _currentIndexFromLocation() {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/patient/consultation') ||
        location.startsWith('/patient/doctor')) {
      return 1;
    }
    if (location.startsWith('/patient/sos')) {
      return 2;
    }
    if (location.startsWith('/patient/records')) {
      return 3;
    }
    if (location.startsWith('/patient/profile')) {
      return 4;
    }
    return 0;
  }

  Future<void> _handleBack() async {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
      return;
    }
    final currentIndex = _currentIndexFromLocation();
    if (currentIndex != 0) {
      context.go('/patient/dashboard');
      return;
    }
    final shouldExit = await _showExitDialog();
    if (shouldExit == true) {
      _exitApp();
    }
  }

  Future<bool?> _showExitDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Exit App',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: Text(
            'Do you want to exit the app?',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Exit',
                style: TextStyle(color: colorScheme.error),
              ),
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

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndexFromLocation();

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
        bottomNavigationBar: PatientBottomNavBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/patient/dashboard');
                break;
              case 1:
                context.go('/patient/consultation');
                break;
              case 2:
                context.go('/patient/sos');
                break;
              case 3:
                context.go('/patient/records');
                break;
              case 4:
                context.go('/patient/profile');
                break;
            }
          },
        ),
      ),
    );
  }
}
