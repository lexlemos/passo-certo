import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/base_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'profile_section_header.dart';
import 'profile_switch_row.dart';

class NavigationPreferencesSection extends StatelessWidget {
  const NavigationPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        bool reducedMobility = false;
        if (state is Authenticated) {
          reducedMobility = state.user.reducedMobility;
        }

        return Column(
          children: [
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
                        color: AppColors.physicalNeedsGreen,
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
                              color: AppColors.physicalNeedsGreen,
                            ),
                            const SizedBox(height: 16),
                            ProfileSwitchRow(
                              title: 'Evitar Escadas',
                              subtitle:
                                  'Prioriza rotas com rampas ou elevadores.',
                              value: reducedMobility,
                              onChanged: (val) {
                                if (state is Authenticated) {
                                  final updatedUser = state.user.copyWith(
                                    reducedMobility: val,
                                  );
                                  context.read<AuthBloc>().add(
                                    AuthUpdateProfileRequested(updatedUser),
                                  );
                                }
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
          ],
        );
      },
    );
  }
}
