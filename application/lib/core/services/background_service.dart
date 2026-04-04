import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'hotword_service.dart';
import '../../features/emergency/services/sos_service.dart';
import '../../core/constants/api_constants.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/doctor_auth/services/doctor_auth_service.dart';

const bool kEnableVoiceSos = false;

/// One fall event must not run [_triggerFallSOS] twice (Kotlin sets pending + servicePipe).
bool _backgroundFallSosHandling = false;

class BackgroundServiceHelper {
  static const String backgroundServiceEnabledKey = 'background_protection_enabled';
  static const String adminPollingOnlyKey = 'admin_notifications_polling_only_enabled';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // Distinct id so OEMs/Android cannot keep an old low-importance channel under a reused id.
    const AndroidNotificationChannel sosTriggerChannel = AndroidNotificationChannel(
      'sos_fall_alert_tray',
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
      importance: Importance.low, // Low so it stays in drawer without sound
      enableVibration: false,
      playSound: false,
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
        final service = FlutterBackgroundService();
        final payload = response.payload;
        if (payload != null &&
            payload.startsWith('admin_notifications|route=')) {
          final route = payload.substring('admin_notifications|route='.length);
          service.invoke('openAdminNotifications', {'route': route});
          return;
        }

        if (response.actionId == 'cancel_sos') {
          service.invoke('cancelSosAction');
          return;
        }

        // SOS: tapped notification body or "Open SOS" action.
        if (response.actionId == 'open_sos' ||
            (response.actionId == null && (payload == null || payload.isEmpty))) {
          service.invoke('openSos', {'trigger': 'notification'});
        }
      },
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(sosTriggerChannel);
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'admin_notifications_channel',
        'Admin Notifications',
        description: 'Notifications sent by admin broadcasts',
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      ),
    );

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'sos_background_channel',
        initialNotificationTitle: 'Care4Elder Protection Active',
        initialNotificationContent: 'Background protection active',
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
    }
    // Always persist enabled state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(backgroundServiceEnabledKey, true);
    await prefs.setBool(adminPollingOnlyKey, false);
    // Start the native fall detection foreground service
    try {
      const channel = MethodChannel('com.care4elder.app/fall_service_control');
      await channel.invokeMethod('startFallService');
    } catch (e) {
      if (kDebugMode) print('BackgroundServiceHelper: startFallService error: $e');
    }
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('stopService');
    }
    // Always persist disabled state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(backgroundServiceEnabledKey, false);
    await prefs.setBool(adminPollingOnlyKey, false);
    // Stop native fall detection service
    try {
      const channel = MethodChannel('com.care4elder.app/fall_service_control');
      await channel.invokeMethod('stopFallService');
    } catch (e) {
      if (kDebugMode) print('BackgroundServiceHelper: stopFallService error: $e');
    }
  }

  /// Start background service for admin notification polling.
  /// If the user already turned **Background protection** on in settings, prefs are **not**
  /// changed (main() calls this every launch — it must not flip the toggle off).
  static Future<void> startAdminNotificationsPolling() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      await prefs.reload();
    } catch (_) {}
    var protectionEnabled = prefs.getBool(backgroundServiceEnabledKey) ?? false;

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }

    // After the engine starts, prefs may reflect a user action; never clobber ON with OFF here.
    protectionEnabled = prefs.getBool(backgroundServiceEnabledKey) ?? false;

    if (protectionEnabled) {
      // Keep fall detection + full foreground copy; admin polling still runs in onStart.
      await prefs.setBool(adminPollingOnlyKey, false);
      try {
        const channel = MethodChannel('com.care4elder.app/fall_service_control');
        await channel.invokeMethod('startFallService');
      } catch (e) {
        if (kDebugMode) {
          print('BackgroundServiceHelper: startFallService after protection prefs: $e');
        }
      }
      return;
    }

    // Admin-only mode: do not write [backgroundServiceEnabledKey] here — that was wiping ON
    // when this method ran with a stale false (e.g. after resume / multi-call). OFF is only
    // set by [disableBackgroundProtectionKeepAdminPolling] and [stopService].
    await prefs.setBool(adminPollingOnlyKey, true);
  }

  /// Disable background protection (fall detection) but KEEP admin polling running.
  static Future<void> disableBackgroundProtectionKeepAdminPolling() async {
    // Mark protection off, admin polling on
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(backgroundServiceEnabledKey, false);
    await prefs.setBool(adminPollingOnlyKey, true);

    // Stop native fall detection only
    try {
      const channel = MethodChannel('com.care4elder.app/fall_service_control');
      await channel.invokeMethod('stopFallService');
    } catch (e) {
      if (kDebugMode) {
        print('BackgroundServiceHelper: stopFallService error: $e');
      }
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

  // Register MethodChannel so Kotlin BackgroundFallService can call us directly
  // This is the RELIABLE path — no polling needed
  const MethodChannel fallChannel = MethodChannel('com.care4elder.app/fall_callback');
  fallChannel.setMethodCallHandler((call) async {
    if (call.method == 'fall_detected') {
      print('Background: fall_detected via MethodChannel — triggering SOS');
      _triggerFallSOS(service);
    }
  });

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
    final prefs = await SharedPreferences.getInstance();
    final adminOnly =
        prefs.getBool(BackgroundServiceHelper.adminPollingOnlyKey) ?? false;
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title:
          adminOnly ? 'Care4Elder Notifications Active' : 'Care4Elder Protection Active',
      content: adminOnly
          ? 'Admin notification polling is active'
          : 'Background protection active',
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

  Timer? adminPollingTimer;
  final adminPrefs = await SharedPreferences.getInstance();
  List<String> seenAdminNotificationIds =
      adminPrefs.getStringList('admin_notif_seen_ids') ?? <String>[];

  service.on('stopService').listen((event) {
    adminPollingTimer?.cancel();
    service.stopSelf();
  });

  Future<void> pollAdminOnce() async {
    try {
      final patientToken = await AuthService().getToken();
      final doctorToken =
          patientToken == null ? await DoctorAuthService().getDoctorToken() : null;

      final token = patientToken ?? doctorToken;
      if (token == null) return;

      final route =
          patientToken != null ? '/patient/notifications' : '/doctor/notifications';

      final url =
          '${ApiConstants.baseUrl}/notifications?page=1&limit=20&filter=unread';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> notificationsJson = data['notifications'] ?? [];

      final List<String> newIds = [];
      for (final n in notificationsJson) {
        if (n is! Map<String, dynamic>) continue;
        final id = n['_id']?.toString() ?? n['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        if (seenAdminNotificationIds.contains(id)) continue;

        final title = n['title']?.toString() ?? 'Notification';
        final body = n['body']?.toString() ?? '';

        final notifId = id.hashCode & 0x7fffffff;

        await flutterLocalNotificationsPlugin.show(
          notifId,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'admin_notifications_channel',
              'Admin Notifications',
              channelDescription: 'Notifications sent by admin broadcasts',
              importance: Importance.max,
              priority: Priority.high,
              playSound: false,
              enableVibration: false,
              icon: '@mipmap/ic_launcher',
              autoCancel: true,
              showWhen: true,
              actions: const [
                AndroidNotificationAction(
                  'open_admin_notifications',
                  'Open',
                  showsUserInterface: true,
                  cancelNotification: false,
                ),
              ],
            ),
          ),
          payload: 'admin_notifications|route=$route',
        );

        newIds.add(id);
      }

      if (newIds.isNotEmpty) {
        seenAdminNotificationIds = [
          ...seenAdminNotificationIds,
          ...newIds,
        ];
        if (seenAdminNotificationIds.length > 50) {
          seenAdminNotificationIds = seenAdminNotificationIds
              .sublist(seenAdminNotificationIds.length - 50);
        }
        await adminPrefs.setStringList(
          'admin_notif_seen_ids',
          seenAdminNotificationIds,
        );
      }
    } catch (_) {
      // Keep background alive; ignore polling errors.
    }
  }

  // Run once immediately, then keep polling.
  await pollAdminOnce();

  // Poll admin notifications and show them in Android notification drawer
  // while the background service is alive (so app-closed also works).
  adminPollingTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
    await pollAdminOnce();
  });

  String currentTitle = "Care4Elder Protection Active";
  String currentContent = "Background protection active";

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
        'title': 'Care4Elder Protection Active',
        'content': 'Background protection active',
      });
      // Notify main app to redirect if open
      service.invoke('sosCancelled');
    } catch (e) {
      print('Background: Failed to cancel SOS: $e');
    }
  });

  if (kEnableVoiceSos) {
    final hotwordService = HotwordService();
    hotwordService.setBackgroundService(service);
    hotwordService.onTrigger = () async {
      print('Background: Voice SOS Triggered!');
      showSosTriggerNotification('Voice Command Detected', 'SOS triggered via voice. Tap to manage or cancel.');
      try {
        await SOSService().startSOS(relaxedLocationForBackground: true);
        service.invoke('openSos', {'trigger': 'voice'});
        service.invoke('updateNotification', {
          'title': 'SOS Alert Active',
          'content': 'Sharing live location with emergency contacts...',
        });
      } catch (e) {
        print('Background Voice SOS failed: $e');
      }
    };
    try {
      hotwordService.stop();
      await hotwordService.start();
    } catch (e) {
      print('Background: HotwordService start failed: $e');
    }
  }

  // Fall detection is started natively by Care4ElderBackgroundService.
  // Listen for fallDetected event from Kotlin via servicePipe (primary path).
  service.on('fallDetected').listen((event) async {
    print('Background: fallDetected event from Kotlin!');
    await _triggerFallSOS(service);
  });

  // Poll for fall_detected_pending flag every 1 second (backup if servicePipe missed).
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    try {
      if (_backgroundFallSosHandling) return;
      // Force reload from disk — bypass in-memory cache
      await SharedPreferences.getInstance().then((p) => p.reload());
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getBool('fall_detected_pending') ?? false;
      if (pending) {
        print('Background: fall_detected_pending flag found — triggering SOS');
        await _triggerFallSOS(service);
      }
    } catch (e) {
      print('Background: fall pending poll error: $e');
    }
  });
  // Periodic update to notification or state - every 2 hours to avoid spam
  Timer.periodic(const Duration(hours: 2), (timer) async {
    try {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          // Only update title/content if they changed, don't re-assert foreground status
          service.setForegroundNotificationInfo(
            title: currentTitle,
            content: currentContent,
          );
        }
      }
      // Check if hotword service is still running
      if (kEnableVoiceSos) {
        final hs = HotwordService();
        if (!hs.isListening) {
          await hs.start();
        }
      }
    } catch (e) {
      print('Background: Periodic timer error: $e');
    }
  });
}

Future<void> _triggerFallSOS(ServiceInstance service) async {
  if (_backgroundFallSosHandling) {
    print('Background: _triggerFallSOS skipped (already handling same fall)');
    return;
  }
  _backgroundFallSosHandling = true;

  try {
    // Clear pending immediately so the 1s poll cannot double-fire with servicePipe for one fall.
    try {
      final prefsClear = await SharedPreferences.getInstance();
      await prefsClear.reload();
      await prefsClear.remove('fall_detected_pending');
      await prefsClear.remove('fall_detected_time');
    } catch (e) {
      print('Background: clear fall_detected_pending error: $e');
    }

    final alreadyActive = await SOSService().isSosActive();
    if (alreadyActive) {
      print('Background: SOS already active — skipping duplicate fall trigger');
      return;
    }

    // Minimized path: [SosTrayNotifier] already posted id 999 — skip duplicate sound/vibration.
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final nativeTrayShown = prefs.getBool('native_sos_tray_for_fall') ?? false;
    if (nativeTrayShown) {
      await prefs.remove('native_sos_tray_for_fall');
    } else {
      await showSosTriggerNotification(
        'Fall Detected',
        'A fall was detected. Tap to open SOS or tap Cancel SOS to stop.',
      );
    }
    try {
      await SOSService().startSOS(relaxedLocationForBackground: true);
      service.invoke('updateNotification', {
        'title': 'SOS Alert Active',
        'content': 'Sharing live location with emergency contacts...',
      });
    } catch (e) {
      print('Background Fall SOS failed: $e');
    }
    // Always deep-link main UI so user is on SOS when they return (and 10s dialog can run if API failed).
    service.invoke('openSos', {'trigger': 'fall'});
  } finally {
    _backgroundFallSosHandling = false;
  }
}

/// High-priority SOS alert in the Android notification drawer (fall / voice).
/// Call only after [BackgroundServiceHelper.initializeService] (e.g. from main isolate or background).
Future<void> showSosTriggerNotification(String title, String content) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'sos_fall_alert_tray',
    'SOS Alerts',
    channelDescription: 'Triggered when a fall or voice command is detected',
    importance: Importance.max,
    priority: Priority.high,
    ticker: 'SOS Triggered',
    ongoing: true,
    autoCancel: false,
    playSound: true,
    enableVibration: true,
    color: Colors.red,
    icon: '@mipmap/ic_launcher',
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        'open_sos',
        'Open SOS',
        showsUserInterface: true,
        cancelNotification: false,
      ),
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
    999,
    title,
    content,
    platformChannelSpecifics,
  );
}
