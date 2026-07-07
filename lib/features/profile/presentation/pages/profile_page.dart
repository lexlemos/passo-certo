import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/profile_emergency_bloc.dart';
import '../bloc/profile_navigation_bloc.dart';
import '../widgets/accessibility_settings_section.dart';
import '../widgets/emergency_contact_section.dart';
import '../widgets/navigation_preferences_section.dart';
import '../widgets/profile_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileNavigationBloc>(
          create: (context) => di.sl<ProfileNavigationBloc>()..add(LoadNavigationSettingsEvent()),
        ),
        BlocProvider<ProfileEmergencyBloc>(
          create: (context) => di.sl<ProfileEmergencyBloc>()..add(LoadEmergencyContactEvent()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MultiBlocListener(
            listeners: [
              BlocListener<ProfileEmergencyBloc, ProfileEmergencyState>(
                listenWhen: (prev, curr) =>
                    prev.isSaved != curr.isSaved || prev.errorMessage != curr.errorMessage,
                listener: (context, state) {
                  if (state.isSaved) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contato salvo com sucesso!'),
                        backgroundColor: AppTheme.mintGreen,
                      ),
                    );
                  }
                  if (state.errorMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage ?? ''),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                },
              ),
              BlocListener<ProfileNavigationBloc, ProfileNavigationState>(
                listenWhen: (prev, curr) => prev.hasError != curr.hasError,
                listener: (context, state) {
                  if (state.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Erro ao atualizar preferências.'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                },
              ),
            ],
            child: const Scaffold(
              backgroundColor: AppColors.greyBg,
              body: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfileHeader(),
                    SizedBox(height: 24),
                    AccessibilitySettingsSection(),
                    NavigationPreferencesSection(),
                    EmergencyContactSection(),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}