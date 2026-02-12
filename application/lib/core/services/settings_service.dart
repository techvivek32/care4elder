import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;

  SettingsService._internal() {
    _loadSettings();
    fetchGlobalSettings();
  }

  ThemeMode _themeMode = ThemeMode.light;
  bool _notificationsEnabled = true;
  String _language = 'English';
  bool _isLoading = true;
  
  double _standardCommission = 0;
  double _emergencyCommission = 0;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  String get language => _language;
  bool get isLoading => _isLoading;
  
  double get standardCommission => _standardCommission;
  double get emergencyCommission => _emergencyCommission;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _language = prefs.getString('language') ?? 'English';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGlobalSettings() async {
    try {
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/settings'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _standardCommission = (data['standardCommission'] ?? 0).toDouble();
        _emergencyCommission = (data['emergencyCommission'] ?? 0).toDouble();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching global settings: $e');
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', isDark);
  }

  Future<void> setNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<void> setLanguage(String language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', language);
  }
}
