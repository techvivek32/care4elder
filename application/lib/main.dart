import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'core/services/profile_service.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileService()),
      ],
      child: AnimatedBuilder(
        animation: SettingsService(),
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Care4Elder',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: SettingsService().themeMode,
            routerConfig: router,
            builder: (context, child) {
              if (child == null) {
                return const SizedBox.shrink();
              }
              return BackNavigationHandler(child: child);
            },
          );
        },
      ),
    );
  }
}

class BackNavigationHandler extends StatelessWidget {
  final Widget child;

  const BackNavigationHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
          return;
        }
        final shouldExit = await _showExitDialog(context);
        if (shouldExit == true) {
          _exitApp();
        }
      },
      child: child,
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
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
}
