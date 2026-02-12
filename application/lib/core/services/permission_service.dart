import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  static const String _permissionsRequestedKey = 'all_permissions_requested_v1';

  Future<bool> hasRequestedPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsRequestedKey) ?? false;
  }

  Future<void> setPermissionsRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsRequestedKey, true);
  }

  Future<void> requestAllPermissions() async {
    // List of all permissions used in the app as per AndroidManifest.xml
    final List<Permission> permissions = [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.phone,
      Permission.contacts,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.storage,
      Permission.sensors,
      // For newer Android versions
      Permission.photos,
      Permission.videos,
      Permission.audio,
      Permission.notification,
    ];

    // Request all permissions at once
    await permissions.request();
    
    // Mark as requested so we don't bother the user every time they open the app
    // though the system dialog won't show again if already granted/denied permanently
    await setPermissionsRequested();
  }
}
