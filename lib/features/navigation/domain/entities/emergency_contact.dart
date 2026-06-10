class EmergencyContact {
  final String name;
  final String phoneNumber;

  const EmergencyContact({
    required this.name,
    required this.phoneNumber,
  });

  bool get isValid =>
      name.trim().isNotEmpty &&
      RegExp(r'^\(?[1-9]{2}\)?\s?9?[0-9]{4}\-?[0-9]{4}$').hasMatch(phoneNumber);
}
