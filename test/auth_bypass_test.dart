import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/auth/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AuthService OTP Bypass Tests', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
      // Reset bypass flag before each test to match the default (false)
      authService.enableDevOtpBypass = false;
    });

    test('Bypass disabled by default', () async {
      // Re-initialize to check default state
      final service = AuthService();
      expect(service.enableDevOtpBypass, false);
    });

    test('Bypass enabled allows any 6-digit code', () async {
      authService.enableDevOtpBypass = true;
      const phone = '1234567890';

      // Attempt verification without sending OTP first
      // Normal flow would throw "No OTP found"
      // Bypass should allow it
      bool verified = await authService.verifyOtp(phone, '000000');
      expect(verified, true);

      verified = await authService.verifyOtp(phone, '111111');
      expect(verified, true);
    });

    test('Bypass still respects length check', () async {
      authService.enableDevOtpBypass = true;
      const phone = '1234567890';

      // Should fail/fallthrough to normal logic if not 6 digits
      // Normal logic throws "No OTP found"
      try {
        await authService.verifyOtp(phone, '123');
        fail('Should have failed due to normal logic (no OTP found)');
      } catch (e) {
        expect(e.toString(), contains('No OTP found'));
      }
    });

    test('Disabling bypass restores normal logic', () async {
      authService.enableDevOtpBypass = true;
      authService.enableDevOtpBypass = false; // Disable it back
      const phone = '1234567890';

      try {
        await authService.verifyOtp(phone, '111111');
        fail('Should have failed with normal logic');
      } catch (e) {
        expect(e.toString(), contains('No OTP found'));
      }
    });
  });
}
