import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart' as bg;
import 'core/theme/app_theme.dart';
import 'core/services/settings_service.dart';
import 'core/services/profile_service.dart';
import 'core/services/hotword_service.dart';
import 'core/services/background_service.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    print('APP_ERROR: ${details.exceptionAsString()}');
    if (details.stack != null) {
      print('APP_STACK: ${details.stack}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    print('APP_ERROR: $error');
    print('APP_STACK: $stack');
    return true;
  };
  ErrorWidget.builder = (details) {
    final message = kDebugMode
        ? details.exceptionAsString()
        : 'Something went wrong. Please restart the app.';
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) print("Warning: .env file not found or failed to load: $e");
  }
  
  // Initialize background service helper
  try {
    await BackgroundServiceHelper.initializeService();
  } catch (e) {
    if (kDebugMode) print("Background Service Init Error: $e");
  }
  
  // Listen for background service events
  final service = bg.FlutterBackgroundService();
  service.on('openSos').listen((event) {
    if (event != null && event['trigger'] != null) {
      router.go('/patient/sos?autoStart=true&trigger=${event['trigger']}');
    }
  });

  service.on('sosCancelled').listen((event) {
    // If the user cancels from notification, take them to the records/home screen
    // or keep them where they are but show a message. 
    // Usually, opening the app on cancellation is desired.
    router.go('/patient/records'); 
  });
  
  // HotwordService should ONLY be started if user is a Patient and logged in.
  // It checks internal storage itself, but we can delay it or wrap in try-catch.
  try {
    HotwordService().start();
  } catch (e) {
    if (kDebugMode) print("Hotword Service Start Error: $e");
  }
  
  // Initialize profiles and config
  final profileService = ProfileService();
  profileService.fetchProfile();
  profileService.fetchConfig();

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
