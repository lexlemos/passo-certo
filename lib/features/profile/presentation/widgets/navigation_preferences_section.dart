import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_card.dart';
import '../bloc/profile_navigation_bloc.dart';
import 'profile_section_header.dart';
import 'profile_switch_row.dart';

class NavigationPreferencesSection extends StatelessWidget {
  const NavigationPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileNavigationBloc, ProfileNavigationState>(
      builder: (context, state) {
        return Column(
          children: [
            // Necessidades Físicas
            BaseCard(
              semanticLabel: "Seção de Necessidades Físicas",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfileSectionHeader(
                    icon: Icons.accessible,
                    title: 'Necessidades Físicas',
                    color: AppTheme.mintGreen,
                  ),
                  const SizedBox(height: 16),
                  ProfileSwitchRow(
                    title: 'Evitar Escadas',
                    subtitle: 'Prioriza rotas com rampas ou elevadores.',
                    value: state.avoidStairs,
                    onChanged: (val) {
                      context
                          .read<ProfileNavigationBloc>()
                          .add(ToggleAvoidStairsEvent(value: val));
                    },
                  ),
                  const Divider(height: 32),
                  ProfileSwitchRow(
                    title: 'Tempo Extra em Cruzamentos',
                    subtitle: 'Calcula rotas assumindo um ritmo de caminhada menor.',
                    value: state.extraCrossingTime,
                    onChanged: (val) {
                      context
                          .read<ProfileNavigationBloc>()
                          .add(ToggleExtraCrossingTimeEvent(value: val));
                    },
                  ),
                ],
              ),
            ),
            // Configurações de Assistência (preferências de navegação)
            BaseCard(
              semanticLabel: "Seção de Configurações de Assistência",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfileSectionHeader(
                    icon: Icons.brightness_low,
                    title: 'Configurações de Assistência',
                    color: AppTheme.spaceBlue,
                  ),
                  const SizedBox(height: 16),
                  ProfileSwitchRow(
                    title: 'Sinais Semafóricos Sonoros',
                    subtitle: 'Integração com semáforos inteligentes.',
                    value: state.soundTrafficSignals,
                    onChanged: (val) {
                      context
                          .read<ProfileNavigationBloc>()
                          .add(ToggleSoundTrafficSignalsEvent(value: val));
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
