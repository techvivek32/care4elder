import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Intercepts system back so the user is not dropped out of the patient flow.
/// When the router cannot [pop], navigates to [fallbackRoute].
class PatientSafeBackScope extends StatelessWidget {
  const PatientSafeBackScope({
    super.key,
    required this.child,
    required this.fallbackRoute,
  });

  final Widget child;
  final String fallbackRoute;

  void _handlePop(BuildContext context) {
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(fallbackRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handlePop(context);
      },
      child: child,
    );
  }
}
