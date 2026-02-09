import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phone Number Validation', () {
    test('Valid 10-digit number returns null (success)', () {
      final result = validatePhone('1234567890');
      expect(result, null);
    });

    test('Empty input returns error', () {
      final result = validatePhone('');
      expect(result, 'Please enter phone number');
    });

    test('Less than 10 digits returns error', () {
      final result = validatePhone('123456789');
      expect(result, 'Enter valid 10-digit number');
    });

    test('More than 10 digits (if formatter fails) returns error', () {
      final result = validatePhone('12345678901');
      expect(result, 'Enter valid 10-digit number');
    });
  });
}

String? validatePhone(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter phone number';
  }
  if (value.length != 10) {
    return 'Enter valid 10-digit number';
  }
  return null;
}
