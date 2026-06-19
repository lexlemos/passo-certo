import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: AppTheme.spaceBlue,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.person, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text('Perfil de Acessibilidade', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(
          'Personalize sua experiência para garantir uma\nnavegação segura e autônoma.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
