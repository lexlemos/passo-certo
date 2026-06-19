import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_card.dart';
import '../bloc/profile_navigation_bloc.dart';
import 'profile_section_header.dart';
import 'profile_switch_row.dart';

class AccessibilitySettingsSection extends StatelessWidget {
  const AccessibilitySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<ProfileNavigationBloc, ProfileNavigationState>(
      builder: (context, state) {
        return BaseCard(
          semanticLabel: "Seção de Necessidades Visuais",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileSectionHeader(
                icon: Icons.visibility,
                title: 'Necessidades Visuais',
                color: AppTheme.mintGreen,
              ),
              const SizedBox(height: 16),
              ProfileSwitchRow(
                title: 'Navegação por Voz',
                subtitle: 'Instruções de rota faladas passo a passo.',
                value: state.voiceNavigation,
                onChanged: (val) {
                  context
                      .read<ProfileNavigationBloc>()
                      .add(ToggleVoiceNavigationEvent(value: val));
                },
              ),
              const Divider(height: 32),
              ProfileSwitchRow(
                title: 'Alto Contraste',
                subtitle: 'Aumenta o contraste visual da interface.',
                value: state.highContrast,
                onChanged: (val) {
                  context
                      .read<ProfileNavigationBloc>()
                      .add(ToggleHighContrastEvent(value: val));
                },
              ),
              const Divider(height: 32),
              Text(
                'Tamanho do Texto',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: state.textSize,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.scaffoldBackgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Padrão', 'Pequeno', 'Médio', 'Grande', 'Extra Grande']
                    .map((size) => DropdownMenuItem(value: size, child: Text(size)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    context
                        .read<ProfileNavigationBloc>()
                        .add(ChangeTextSizeEvent(value: val));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
