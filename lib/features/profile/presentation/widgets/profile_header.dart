import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.darkBlue,
          child: Icon(Icons.person, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 16),
        Text(
          'Perfil de Acessibilidade',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: AppColors.darkBlue,
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
