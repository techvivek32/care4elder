import 'package:flutter/material.dart';

class UserProfile {
  String id;
  String fullName;
  String email;
  String phoneNumber;
  String profilePictureUrl;
  DateTime dateOfBirth;
  String location;
  String bloodGroup;
  String allergies;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.profilePictureUrl,
    required this.dateOfBirth,
    required this.location,
    required this.bloodGroup,
    required this.allergies,
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
    );
  }
}

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal() {
    fetchProfile(); // Initial fetch
  }

  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Mock list of known relatives (simulating data from other parts of the app)
  final List<Map<String, String>> knownRelatives = [
    {'name': 'Jane Doe', 'relation': 'Wife', 'phone': '9876543210'},
    {'name': 'Mike Doe', 'relation': 'Son', 'phone': '9876543211'},
  ];

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Simulate API call to fetch profile
  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate delay
      // Mock data if not already set
      _currentUser ??= UserProfile(
        id: '1',
        fullName: 'John Doe',
        email: 'john.doe@example.com',
        phoneNumber: '+91 98765 43210',
        profilePictureUrl: '',
        dateOfBirth: DateTime(1950, 5, 15),
        location: 'Mumbai, India',
        bloodGroup: 'O+',
        allergies: 'Peanuts, Penicillin',
      );
    } catch (e) {
      _error = 'Failed to fetch profile';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simulate API call to update profile
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate delay
      _currentUser = updatedProfile;
      return true;
    } catch (e) {
      _error = 'Failed to update profile';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
