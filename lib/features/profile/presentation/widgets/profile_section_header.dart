import 'package:flutter/material.dart';

class ProfileSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const ProfileSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
