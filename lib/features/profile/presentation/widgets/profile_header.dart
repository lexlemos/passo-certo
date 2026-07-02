import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const CircleAvatar(
          radius: 48,
          backgroundColor: Color(0xFF2C3E50),
          child: Icon(Icons.person, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          'Perfil de Acessibilidade',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: const Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Personalize sua experiência para garantir uma\nnavegação segura e autônoma.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
