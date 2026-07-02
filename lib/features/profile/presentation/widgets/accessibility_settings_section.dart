import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                          icon: Icons.visibility,
                          title: 'Necessidades Visuais',
                          color: Color(0xFF009688),
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
                        Divider(height: 32, color: Colors.grey[200], thickness: 1),
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
                        Divider(height: 32, color: Colors.grey[200], thickness: 1),
                        Text(
                          'Tamanho do Texto',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF2C3E50),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(state.textSize),
                            initialValue: state.textSize,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              border: InputBorder.none,
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
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
