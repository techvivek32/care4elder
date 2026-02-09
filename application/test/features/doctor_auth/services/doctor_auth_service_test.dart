import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/doctor_auth/services/doctor_auth_service.dart';

void main() {
  late DoctorAuthService service;

  setUp(() {
    service = DoctorAuthService();
    // Reset singleton state if possible or just use the instance
    // Since it's a singleton, we might need to be careful with state between tests
  });

  group('DoctorAuthService Tests', () {
    test('sendOtp should return true for phone mock', () async {
      final result = await service.sendOtp('1234567890', isEmail: false);
      expect(result, isTrue);
      final verifyResult = await service.verifyOtp('123456', isEmail: false);
      expect(verifyResult['success'], isTrue);
    });

    test('verifyOtp should fail for incorrect OTP', () async {
      await service.sendOtp('1234567890', isEmail: false);
      final result = await service.verifyOtp('000000', isEmail: false);
      expect(result['success'], isFalse);
    });

    test('updateRegistrationData should update fields correctly', () {
      service.updateRegistrationData(
        fullName: 'Dr. Test',
        specialization: 'Cardiologist',
        experienceYears: '10',
      );

      expect(service.registrationData.fullName, 'Dr. Test');
      expect(service.registrationData.specialization, 'Cardiologist');
      expect(service.registrationData.experienceYears, '10');
    });
  });
}
