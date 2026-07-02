import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            // Necessidades Físicas
            BaseCard(
              semanticLabel: "Seção de Necessidades Físicas",
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50), // Verde
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ProfileSectionHeader(
                              icon: Icons.accessible,
                              title: 'Necessidades Físicas',
                              color: Color(0xFF4CAF50),
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
                            Divider(height: 32, color: Colors.grey[200], thickness: 1),
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
                    ),
                  ],
                ),
              ),
            ),
            // Configurações de Assistência (preferências de navegação)
            BaseCard(
              semanticLabel: "Seção de Configurações de Assistência",
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF009688), // Teal/Azul Petróleo
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ProfileSectionHeader(
                              icon: Icons.brightness_low,
                              title: 'Configurações de Assistência',
                              color: Color(0xFF009688),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ProfileSwitchRow(
                                title: 'Sinais Semafóricos Sonoros',
                                subtitle: 'Integração com semáforos inteligentes.',
                                value: state.soundTrafficSignals,
                                onChanged: (val) {
                                  context
                                      .read<ProfileNavigationBloc>()
                                      .add(ToggleSoundTrafficSignalsEvent(value: val));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
