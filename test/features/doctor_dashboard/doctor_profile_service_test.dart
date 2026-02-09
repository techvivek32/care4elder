import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/doctor_dashboard/services/doctor_profile_service.dart';

void main() {
  group('DoctorProfileService', () {
    test('should return default profile data initially', () async {
      final service = DoctorProfileService();
      final profile = await service.getProfile();

      expect(profile.name, 'Dr. John Smith');
      expect(profile.specialty, 'Cardiologist');
    });

    test('should update profile data', () async {
      final service = DoctorProfileService();
      final currentProfile = await service.getProfile();

      final updatedProfile = currentProfile.copyWith(
        name: 'Dr. Jane Doe',
        specialty: 'Neurologist',
      );

      final success = await service.updateProfile(updatedProfile);
      expect(success, true);

      final newProfile = await service.getProfile();
      expect(newProfile.name, 'Dr. Jane Doe');
      expect(newProfile.specialty, 'Neurologist');
    });

    test('should fail validation for empty name', () async {
      final service = DoctorProfileService();
      final currentProfile = await service.getProfile();

      final invalidProfile = currentProfile.copyWith(name: '');

      expect(() => service.updateProfile(invalidProfile), throwsException);
    });
  });
}
