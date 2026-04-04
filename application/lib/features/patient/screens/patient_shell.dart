import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/background_service.dart';
import '../../../core/widgets/patient_navigation.dart';
import '../../emergency/services/fall_detection_service.dart';
import '../../emergency/services/sos_service.dart';

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
  bool _handlingBack = false;

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

  void _onFallDetected() async {
    final alreadyActive = await SOSService().isSosActive();
    if (!alreadyActive) {
      await showSosTriggerNotification(
        'Fall Detected',
        'A fall was detected. Tap to open SOS or tap Cancel SOS to stop.',
      );
    }
    if (mounted) {
      context.go('/patient/sos?autoStart=true&trigger=fall');
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
    if (_handlingBack) return;
    _handlingBack = true;
    try {
      await _handleBackImpl();
    } finally {
      _handlingBack = false;
    }
  }

  Future<void> _handleBackImpl() async {
    final path = GoRouterState.of(context).uri.path;

    // Profile sub-routes (settings, wallet, etc.): go back one level first
    if (path.startsWith('/patient/profile/') && path != '/patient/profile') {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/patient/profile');
      }
      return;
    }

    // Doctor detail (from consultation): return to consultation list
    if (RegExp(r'^/patient/doctor/[^/]+$').hasMatch(path)) {
      context.go('/patient/consultation');
      return;
    }

    // Help & support (opened from menu): return to home
    if (path.startsWith('/patient/help-support')) {
      context.go('/patient/dashboard');
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

  /// Android: [BackButtonListener] must return `true` immediately so the shell is not popped.
  /// Do not also use [PopScope] on Android — OEM/Oplus often delivers both paths and the second
  /// invocation could run after [go] to home, showing the exit dialog or needing extra presses.
  Future<bool> _onRootBackButton() {
    if (mounted) {
      unawaited(_handleBack());
    }
    return Future<bool>.value(true);
  }

  bool get _androidUsesBackButtonListener =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

    final scaffold = Scaffold(
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
    );

    // Android: single handler only (BackButtonListener). iOS/web/desktop: PopScope.
    if (_androidUsesBackButtonListener) {
      return BackButtonListener(
        onBackButtonPressed: _onRootBackButton,
        child: scaffold,
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        await _handleBack();
      },
      child: scaffold,
    );
  }
}
