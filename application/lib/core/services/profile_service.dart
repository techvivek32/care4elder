import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../features/auth/services/auth_service.dart';

class UserProfile {
  String id;
  String fullName;
  String email;
  String phoneNumber;
  String profilePictureUrl;
  DateTime? dateOfBirth;
  String location;
  String bloodGroup;
  String allergies;
  double walletBalance;
  List<EmergencyContact> emergencyContacts;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.profilePictureUrl,
    this.dateOfBirth,
    required this.location,
    required this.bloodGroup,
    required this.allergies,
    this.walletBalance = 0.0,
    this.emergencyContacts = const [],
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profilePictureUrl,
    DateTime? dateOfBirth,
    String? location,
    String? bloodGroup,
    String? allergies,
    double? walletBalance,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      location: location ?? this.location,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      walletBalance: walletBalance ?? this.walletBalance,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone'] ?? '',
      profilePictureUrl: json['profilePictureUrl'] ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      location: json['location'] ?? '',
      bloodGroup: json['bloodGroup'] ?? '',
      allergies: json['allergies'] ?? '',
      walletBalance: (json['walletBalance'] as num?)?.toDouble() ?? 0.0,
      emergencyContacts: (json['emergencyContacts'] as List?)
              ?.map((e) => EmergencyContact.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': fullName,
      'email': email,
      'phone': phoneNumber,
      'profilePictureUrl': profilePictureUrl,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'location': location,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'emergencyContacts': emergencyContacts.map((e) => e.toJson()).toList(),
    };
  }
}

class EmergencyContact {
  final String name;
  final String relation;
  final String phone;

  EmergencyContact({
    required this.name,
    required this.relation,
    required this.phone,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] ?? '',
      relation: json['relation'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relation': relation,
      'phone': phone,
    };
  }
}

class WalletTransaction {
  final String id;
  final String type; // 'credit' or 'debit'
  final double amount;
  final String description;
  final DateTime timestamp;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.timestamp,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'credit',
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['createdAt']),
    );
  }
}

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal() {
    fetchProfile(); // Initial fetch
    fetchConfig();
  }

  UserProfile? _currentUser;
  List<WalletTransaction> _walletHistory = [];
  bool _isLoading = false;
  String? _error;
  String? _razorpayKeyId;

  // Mock list of known relatives (simulating data from other parts of the app)
  // TODO: Fetch this from backend if needed
  final List<Map<String, String>> knownRelatives = [
    {'name': 'Jane Doe', 'relation': 'Wife', 'phone': '9876543210'},
    {'name': 'Mike Doe', 'relation': 'Son', 'phone': '9876543211'},
  ];

  UserProfile? get currentUser => _currentUser;
  List<WalletTransaction> get walletHistory => _walletHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get razorpayKeyId => _razorpayKeyId;

  // Fetch app configuration
  Future<void> fetchConfig() async {
    try {
      // Note: Config endpoint might not require auth, or use default public access
      final response = await http.get(Uri.parse('${ApiConstants.baseUrl.replaceAll('/api', '')}/api/config'));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _razorpayKeyId = data['razorpayKeyId'];
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fetch Config Exception: $e');
      }
    }
  }

  // Fetch profile from backend
  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final patientId = await authService.getPatientId();
      final token = await authService.getToken();

      if (patientId == null || token == null) {
        // If no user is logged in, we can't fetch profile
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/patients/$patientId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserProfile.fromJson(data);
      } else {
        _error = 'Failed to fetch profile: ${response.statusCode}';
        if (kDebugMode) {
          print('Fetch Profile Error: ${response.body}');
        }
      }
    } catch (e) {
      _error = 'Failed to fetch profile: $e';
      if (kDebugMode) {
        print('Fetch Profile Exception: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWalletHistory() async {
    // Don't set global loading here to avoid full screen loaders, just quiet update or local loading if needed
    // But for now, we'll use the service state
    
    try {
      final authService = AuthService();
      final patientId = await authService.getPatientId();
      final token = await authService.getToken();

      if (patientId == null || token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/patients/$patientId/wallet/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _walletHistory = data.map((json) => WalletTransaction.fromJson(json)).toList();
        notifyListeners();
      } else {
        if (kDebugMode) {
           print('Fetch Wallet History Error: ${response.body}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Fetch Wallet History Exception: $e');
      }
    }
  }

  // Update profile in backend
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final patientId = await authService.getPatientId();
      final token = await authService.getToken();

      if (patientId == null || token == null) {
        _error = 'User not authenticated';
        return false;
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/patients/$patientId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedProfile.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = UserProfile.fromJson(data);
        return true;
      } else {
        _error = 'Failed to update profile: ${response.statusCode}';
        if (kDebugMode) {
          print('Update Profile Error: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      _error = 'Failed to update profile: $e';
      if (kDebugMode) {
        print('Update Profile Exception: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Recharge Wallet
  Future<bool> rechargeWallet(String paymentId, double amount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final patientId = await authService.getPatientId();
      final token = await authService.getToken();

      if (patientId == null || token == null) {
        _error = 'User not authenticated';
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/patients/$patientId/wallet'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'paymentId': paymentId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local balance
          if (_currentUser != null) {
            _currentUser = _currentUser!.copyWith(
              walletBalance: (data['newBalance'] as num).toDouble(),
            );
          }
          return true;
        }
      }

      _error = 'Failed to recharge wallet: ${response.statusCode}';
      if (kDebugMode) {
        print('Recharge Error: ${response.body}');
      }
      return false;
    } catch (e) {
      _error = 'Failed to recharge wallet: $e';
      if (kDebugMode) {
        print('Recharge Exception: $e');
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deductFromWallet(double amount) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final patientId = await authService.getPatientId();
      final token = await authService.getToken();

      if (patientId == null || token == null) {
        _error = 'User not authenticated';
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/patients/$patientId/wallet/deduct'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Update local balance
          if (_currentUser != null) {
            _currentUser = _currentUser!.copyWith(
              walletBalance: (data['newBalance'] as num).toDouble(),
            );
          }
          return true;
        }
      }

      final errorData = jsonDecode(response.body);
      _error = errorData['error'] ?? 'Failed to deduct from wallet';
      return false;
    } catch (e) {
      _error = 'Failed to deduct from wallet: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
