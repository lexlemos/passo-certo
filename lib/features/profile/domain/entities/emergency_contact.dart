class EmergencyContact {
  final String name;
  final String phoneNumber;

  static final phoneValidationRegex = RegExp(r'^\(?[1-9]{2}\)?\s?9?[0-9]{4}\-?[0-9]{4}$');
  static final phoneExtractionRegex = RegExp(r'\(?[1-9]{2}\)?\s?9?[0-9]{4}\-?[0-9]{4}');

  const EmergencyContact({
    required this.name,
    required this.phoneNumber,
  });

  factory EmergencyContact.fromSingleString(String input) {
    final inputText = input.trim();
    String name = inputText;
    String phone = '';

    final match = phoneExtractionRegex.firstMatch(inputText);
    if (match != null) {
      phone = match.group(0)!;
      name = inputText.replaceAll(phone, '').trim();

      // Limpa caracteres extras como parênteses ou traços residuais no nome
      name = name.replaceAll(RegExp(r'[()\- ]+$'), '').trim();
      if (name.isEmpty) {
        name = 'Contato de Emergência';
      }
    } else {
      // Sem telefone detectado: retorna phone vazio para que o ValidateEmergencyContactUseCase
      // produza a mensagem de erro correta. Nunca injetar números fictícios em dados de emergência.
      name = inputText;
      phone = '';
    }

    return EmergencyContact(name: name, phoneNumber: phone);
  }

  bool get isValid =>
      name.trim().isNotEmpty &&
      phoneValidationRegex.hasMatch(phoneNumber);
}
