import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.role,
    required super.name,
    required super.email,
    super.phone,
    super.emergencyPhone,
    required super.isBlind,
    required super.reducedMobility,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'authenticated',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      emergencyPhone: json['emergency_phone'] as String?,
      isBlind: json['is_blind'] == true,
      reducedMobility: json['reduced_mobility'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'name': name,
      'email': email,
      'phone': phone,
      'emergency_phone': emergencyPhone,
      'is_blind': isBlind,
      'reduced_mobility': reducedMobility,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      role: user.role,
      name: user.name,
      email: user.email,
      phone: user.phone,
      emergencyPhone: user.emergencyPhone,
      isBlind: user.isBlind,
      reducedMobility: user.reducedMobility,
      createdAt: user.createdAt,
    );
  }
}
