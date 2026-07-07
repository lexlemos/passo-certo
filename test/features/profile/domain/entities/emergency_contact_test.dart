import 'package:flutter_test/flutter_test.dart';
import 'package:passo_certo/features/profile/domain/entities/emergency_contact.dart';

void main() {
  group('EmergencyContact Entity Tests', () {
    test('should parse name and phone correctly when both are present in the input string', () {
      final contact = EmergencyContact.fromSingleString('Maria Souza (79) 99999-9999');

      expect(contact.name, equals('Maria Souza'));
      expect(contact.phoneNumber, equals('(79) 99999-9999'));
      expect(contact.isValid, isTrue);
    });

    test('should return empty phoneNumber and fail validation when no phone matches in the input string', () {
      final contact = EmergencyContact.fromSingleString('Maria Souza');

      expect(contact.name, equals('Maria Souza'));
      expect(contact.phoneNumber, equals(''));
      expect(contact.isValid, isFalse);
    });

    test('should be invalid when name is empty or white space', () {
      const contact = EmergencyContact(name: '   ', phoneNumber: '(79) 99999-9999');

      expect(contact.isValid, isFalse);
    });

    test('should be invalid when phone number format does not match Brazilian standards', () {
      const contact1 = EmergencyContact(name: 'Maria', phoneNumber: '99999-9999');
      const contact2 = EmergencyContact(name: 'Maria', phoneNumber: 'abc-12345-6789');

      expect(contact1.isValid, isFalse);
      expect(contact2.isValid, isFalse);
    });
  });
}
