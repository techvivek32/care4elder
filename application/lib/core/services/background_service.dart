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
      importance: Importance.max, // Max importance for maximum visibility
      enableVibration: true,
      playSound: true,
      showBadge: true,
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

  // Initialize notifications for the background isolate
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Ensure notification is shown immediately on start
  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: 'CareSafe Protection Active',
      content: 'Voice SOS is listening for "Help"',
    );
  }

  // Initialize dotenv for background isolate
  try {
    await dotenv.load(fileName: ".env");
    print("Background: .env loaded successfully");
  } catch (e) {
    print("Background: .env load failed: $e");
  }

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    
    service.on('setAsForeground').listen((event) async {
      await service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  String currentTitle = "CareSafe Protection Active";
  String currentContent = "Voice SOS is listening for \"Help\"";

  // Handle updates to the foreground notification
  service.on('updateNotification').listen((event) async {
    if (service is AndroidServiceInstance) {
      final title = event?['title'] as String?;
      final content = event?['content'] as String?;
      if (title != null && content != null) {
        currentTitle = title;
        currentContent = content;
        
        // Force immediate update
        service.setForegroundNotificationInfo(
          title: title,
          content: content,
        );

        // FALLBACK: Also use local notifications directly to ensure drawer visibility
        await flutterLocalNotificationsPlugin.show(
          888, // Must match foregroundServiceNotificationId
          title,
          content,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'sos_background_channel',
              'SOS Background Protection',
              importance: Importance.max,
              priority: Priority.max,
              ongoing: true,
              autoCancel: false,
              showWhen: true,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );

        // Explicitly re-assert foreground status to ensure drawer visibility
        await service.setAsForegroundService();
      }
    }
  });

  service.on('cancelSosAction').listen((event) async {
    try {
      await SOSService().stopSOS(
        cancellationReason: 'User cancelled from notification',
        cancellationComments: 'SOS cancelled via background notification action'
      );
      // Reset notification
      service.invoke('updateNotification', {
        'title': 'CareSafe Protection Active',
        'content': 'Voice SOS is listening for "Help"',
      });
      // Notify main app to redirect if open
      service.invoke('sosCancelled');
    } catch (e) {
      print('Background: Failed to cancel SOS: $e');
    }
  });

  // Start Voice Listening in Background
  final hotwordService = HotwordService();
  hotwordService.setBackgroundService(service);
  
  // Custom trigger for Voice SOS
  hotwordService.onTrigger = () async {
    print('Background: Voice SOS Triggered!');
    _showSosNotification('Voice Command Detected', 'SOS triggered via voice. Tap to manage or cancel.');
    try {
      await SOSService().startSOS();
      service.invoke('openSos', {'trigger': 'voice'});
      
      // Update background notification to show location sharing
      service.invoke('updateNotification', {
        'title': 'SOS Alert Active',
        'content': 'Sharing live location with emergency contacts...',
      });
    } catch (e) {
      print('Background Voice SOS failed: $e');
    }
  };
  
  try {
    // Ensure we stop any existing listener before starting
    hotwordService.stop();
    await hotwordService.start();
  } catch (e) {
    print('Background: HotwordService start failed: $e');
  }

  // Start Fall Detection in Background
  final fallDetectionService = FallDetectionService();
  fallDetectionService.startMonitoring(() async {
    print('Background: Fall Detected!');
    _showSosNotification('Fall Detected', 'A fall was detected. SOS alert sent to emergency contacts.');
    try {
      await SOSService().startSOS();
      service.invoke('openSos', {'trigger': 'fall'});
      
      // Update background notification to show location sharing
      service.invoke('updateNotification', {
        'title': 'SOS Alert Active',
        'content': 'Sharing live location with emergency contacts...',
      });
    } catch (e) {
      print('Background Fall SOS failed: $e');
    }
  });

  // Periodic update to notification or state
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    try {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Re-assert foreground status to keep notification visible
          await service.setAsForegroundService();
          
          service.setForegroundNotificationInfo(
            title: currentTitle,
            content: currentContent,
          );

          // Periodically refresh local notification to ensure it stays in drawer
          await flutterLocalNotificationsPlugin.show(
            888,
            currentTitle,
            currentContent,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'sos_background_channel',
                'SOS Background Protection',
                importance: Importance.max,
                priority: Priority.max,
                ongoing: true,
                autoCancel: false,
                silent: true, // Don't buzz every 10 seconds
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      }
      // Check if hotword service is still running
      if (!hotwordService.isListening) {
        await hotwordService.start();
      }
    } catch (e) {
      print('Background: Periodic timer error: $e');
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
