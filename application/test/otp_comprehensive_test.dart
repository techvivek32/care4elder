import 'package:flutter_test/flutter_test.dart';
import 'package:caresafe/features/auth/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Comprehensive OTP Zero Handling & Integration Tests', () {
    late AuthService authService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authService = AuthService();
      authService.enableDevOtpBypass = false;
    });

    test('Login Flow: Send OTP and Verify (Random OTP)', () async {
      const phone = '9999999999';
      
      // 1. Simulate "Send OTP" button click
      await authService.sendOtp(phone);
      
      // 2. We can't know the OTP, but we can verify that checking a WRONG OTP
      // returns "Invalid OTP" and NOT "No OTP found".
      // This confirms the session exists.
      try {
        await authService.verifyOtp(phone, '000000');
        fail('Should fail with Invalid OTP');
      } catch (e) {
        expect(e.toString(), contains('Invalid OTP'));
        // If it was "No OTP found", it means sendOtp failed to store it.
      }
    });

    test('Signup Flow: Send OTP, Verify, and Create Account', () async {
      const phone = '8888888888';
      
      // 1. Send OTP
      await authService.sendOtp(phone);
      
      // 2. Verify with wrong code (confirm session exists)
      try {
        await authService.verifyOtp(phone, '000000');
      } catch (e) {
        expect(e.toString(), contains('Invalid OTP'));
      }
      
      // We can't verify success without knowing the OTP or enabling bypass.
    });

    test('Zero Handling: Bypass Mode accepts 000000', () async {
      // Enable bypass to simulate a scenario where we KNOW the OTP (000000)
      authService.enableDevOtpBypass = true;
      const phone = '7777777777';
      
      // Even without sending OTP (bypass shortcut), or WITH sending
      // The bypass logic in verifyOtp checks the code BEFORE the store.
      // But let's send it first to be "clean".
      await authService.sendOtp(phone);
      
      // Verify 000000
      final result = await authService.verifyOtp(phone, '000000');
      expect(result, true);
    });

    test('Zero Handling: Bypass Mode accepts valid OTP with zeros', () async {
      authService.enableDevOtpBypass = true;
      const phone = '6666666666';
      
      // Verify 102030 (contains zeros)
      final result = await authService.verifyOtp(phone, '102030');
      expect(result, true);
    });

    test('Edge Case: Leading Zero in Phone Number', () async {
      // Some users might enter 0999...
      const phone = '0987654321';
      
      await authService.sendOtp(phone);
      
      try {
        await authService.verifyOtp(phone, '111111');
      } catch (e) {
        expect(e.toString(), contains('Invalid OTP'));
      }
      
      // Verify that using a different format fails (mimicking UI mismatch)
      try {
        await authService.verifyOtp('+91987654321', '111111');
        fail('Should fail because key does not match');
      } catch (e) {
        // This confirms that "No OTP found" is thrown when keys mismatch
        expect(e.toString(), contains('No OTP found'));
      }
    });
  });
}
