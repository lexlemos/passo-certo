import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/base_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'profile_section_header.dart';

class EmergencyContactSection extends StatelessWidget {
  const EmergencyContactSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String emergencyPhone = 'Não informado';
        if (state is Authenticated &&
            state.user.emergencyPhone != null &&
            state.user.emergencyPhone!.isNotEmpty) {
          emergencyPhone = state.user.emergencyPhone!;
        }

        return Column(
          children: [
            BaseCard(
              semanticLabel: "Seção de Contato de Emergência",
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.tealPrimary,
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
                              icon: Icons.contact_phone,
                              title: 'Contato de Emergência',
                              color: AppColors.tealPrimary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Contato de Emergência Rápido',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.darkBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              emergencyPhone,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.darkBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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
