import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'hotword_service.dart';
import '../../features/emergency/services/fall_detection_service.dart';
import '../../features/emergency/services/sos_service.dart';

class BackgroundServiceHelper {
  static const String backgroundServiceEnabledKey = 'background_service_enabled';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // SOS Trigger Channel (High Importance with Sound & Actions)
    const AndroidNotificationChannel sosTriggerChannel = AndroidNotificationChannel(
      'sos_trigger_channel',
      'SOS Alerts',
      description: 'Triggered when a fall or voice command is detected',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Setup notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sos_background_channel',
      'SOS Background Protection',
      description: 'Keeps you safe even when the app is closed',
      importance: Importance.low,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.actionId == 'cancel_sos') {
          // Handle cancellation in the main isolate if app is running
          // or via the service if it's not
          final service = FlutterBackgroundService();
          service.invoke('cancelSosAction');
        }
      },
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(sosTriggerChannel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'sos_background_channel',
        initialNotificationTitle: 'CareSafe Protection Active',
        initialNotificationContent: 'Voice SOS is listening for "Help"',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<bool> isServiceRunning() async {
    return await FlutterBackgroundService().isRunning();
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(backgroundServiceEnabledKey, true);
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(backgroundServiceEnabledKey, false);
    }
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // Initialize dotenv for background isolate
  try {
    await dotenv.load(fileName: ".env");
    print("Background: .env loaded successfully");
  } catch (e) {
    print("Background: .env load failed: $e");
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('cancelSosAction').listen((event) async {
    try {
      await SOSService().stopSOS(
        cancellationReason: 'User cancelled from notification',
        cancellationComments: 'SOS cancelled via background notification action'
      );
      // Notify main app to redirect if open
      service.invoke('sosCancelled');
    } catch (e) {
      print('Background: Failed to cancel SOS: $e');
    }
  });

  // Start Voice Listening in Background
  final hotwordService = HotwordService();
  hotwordService.setBackgroundService(service);
  // Ensure we stop any existing listener before starting
  hotwordService.stop();
  
  // Custom trigger for Voice SOS
  hotwordService.onTrigger = () async {
    print('Background: Voice SOS Triggered!');
    _showSosNotification('Voice Command Detected', 'SOS triggered via voice. Tap to manage or cancel.');
    try {
      await SOSService().startSOS();
      service.invoke('openSos', {'trigger': 'voice'});
    } catch (e) {
      print('Background Voice SOS failed: $e');
    }
  };
  
  await hotwordService.start();

  // Start Fall Detection in Background
  final fallDetectionService = FallDetectionService();
  fallDetectionService.startMonitoring(() async {
    print('Background: Fall Detected!');
    _showSosNotification('Fall Detected', 'A fall was detected. SOS alert sent to emergency contacts.');
    try {
      await SOSService().startSOS();
      service.invoke('openSos', {'trigger': 'fall'});
    } catch (e) {
      print('Background Fall SOS failed: $e');
    }
  });

  // Periodic update to notification or state
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "CareSafe Protection Active",
          content: "Listening for \"Help\" or \"Bachao\"",
        );
      }
    }
    // Check if hotword service is still running
    if (!hotwordService.isListening) {
      await hotwordService.start();
    }
  });
}

Future<void> _showSosNotification(String title, String content) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'sos_trigger_channel',
    'SOS Alerts',
    channelDescription: 'Triggered when a fall or voice command is detected',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'SOS Triggered',
    ongoing: true, // Keep it ongoing until cancelled
    autoCancel: false, // Don't cancel when tapped
    playSound: true,
    enableVibration: true,
    color: Colors.red,
    icon: '@mipmap/ic_launcher',
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        'cancel_sos',
        'Cancel SOS',
        showsUserInterface: true,
        cancelNotification: true,
      ),
    ],
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    999, // Unique ID for SOS trigger notification
    title,
    content,
    platformChannelSpecifics,
  );
}
