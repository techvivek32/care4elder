import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'hotword_service.dart';

class BackgroundServiceHelper {
  static const String backgroundServiceEnabledKey = 'background_service_enabled';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Setup notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sos_background_channel',
      'SOS Background Protection',
      description: 'Keeps you safe even when the app is closed',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

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
  DartPluginRegistrant.ensureInitialized();

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

  // Start Voice Listening in Background
  final hotwordService = HotwordService();
  // Ensure we stop any existing listener before starting
  hotwordService.stop();
  await hotwordService.start();

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
