import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/theme/app_colors.dart';
import '../bloc/profile_navigation_bloc.dart';
import '../widgets/accessibility_settings_section.dart';
import '../widgets/emergency_contact_section.dart';
import '../widgets/navigation_preferences_section.dart';
import '../widgets/profile_header.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileNavigationBloc>.value(
          value: di.sl<ProfileNavigationBloc>()
            ..add(LoadNavigationSettingsEvent()),
        ),
      ],
      child: Builder(
        builder: (context) {
          return MultiBlocListener(
            listeners: [
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
              BlocListener<AuthBloc, AuthState>(
                listenWhen: (prev, curr) => prev != curr,
                listener: (context, state) {
                  if (state is Unauthenticated) {
                    context.go('/login');
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
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
                    _EditProfileButton(),
                    SizedBox(height: 12),
                    _LogoutButton(),
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

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          context.push('/edit-profile');
        },
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text(
          'Editar Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading
                ? null
                : () {
                    context.read<AuthBloc>().add(AuthLogoutRequested());
                  },
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.emergencyRed,
                    ),
                  )
                : const Icon(Icons.logout, color: AppColors.emergencyRed),
            label: Text(
              isLoading ? 'Saindo...' : 'Sair da Conta',
              style: const TextStyle(
                color: AppColors.emergencyRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.emergencyRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }
}
