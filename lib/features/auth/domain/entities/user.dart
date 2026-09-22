import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String role;
  final String name;
  final String email;
  final String? phone;
  final String? emergencyPhone;
  final bool isBlind;
  final bool reducedMobility;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.emergencyPhone,
    required this.isBlind,
    required this.reducedMobility,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? role,
    String? name,
    String? email,
    String? phone,
    String? emergencyPhone,
    bool? isBlind,
    bool? reducedMobility,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      isBlind: isBlind ?? this.isBlind,
      reducedMobility: reducedMobility ?? this.reducedMobility,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    role,
    name,
    email,
    phone,
    emergencyPhone,
    isBlind,
    reducedMobility,
    createdAt,
  ];
}
