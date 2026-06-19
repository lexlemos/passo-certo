import '../entities/emergency_contact.dart';

class ValidateEmergencyContactUseCase {
  /// Retorna uma mensagem de erro se o contato for inválido, ou nulo se for válido.
  String? call(EmergencyContact contact) {
    if (contact.name.trim().isEmpty) {
      return 'O nome do contato de emergência é obrigatório.';
    }

    final phoneRegex = RegExp(r'^\(?[1-9]{2}\)?\s?9?[0-9]{4}\-?[0-9]{4}$');
    if (!phoneRegex.hasMatch(contact.phoneNumber)) {
      return 'Telefone inválido. Utilize o formato (DD) 9XXXX-XXXX.';
    }

    return null;
  }
}
