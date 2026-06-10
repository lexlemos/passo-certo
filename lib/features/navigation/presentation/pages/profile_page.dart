import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_button.dart';
import '../../../../core/widgets/base_card.dart';
import '../bloc/profile_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static Widget builder(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc(),
      child: const ProfilePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil do Usuário', style: theme.textTheme.titleLarge),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, semanticLabel: 'Voltar'),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listenWhen: (previous, current) => previous.isSuccess != current.isSuccess || previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configurações do perfil salvas com sucesso!'),
                backgroundColor: AppTheme.mintGreen,
              ),
            );
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppTheme.emergencyRed,
              ),
            );
          }
        },
        child: const SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeader(),
              SizedBox(height: 24),
              EmergencyContactForm(),
              SizedBox(height: 24),
              GpsStatusIndicator(),
              SizedBox(height: 32),
              SaveProfileButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Suas Configurações', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(
            'Personalize seus dados de segurança e preferências.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class EmergencyContactForm extends StatelessWidget {
  const EmergencyContactForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      semanticLabel: "Formulário de Contato de Emergência",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const Row(
              children: [
                Icon(Icons.contact_phone, color: AppTheme.spaceBlue),
                SizedBox(width: 8),
                Text(
                  'Contato de Emergência',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.spaceBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Campo Nome
          BlocBuilder<ProfileBloc, ProfileState>(
            buildWhen: (previous, current) =>
                previous.emergencyContactName != current.emergencyContactName ||
                previous.isNameValid != current.isNameValid,
            builder: (context, state) {
              return TextFormField(
                initialValue: state.emergencyContactName,
                onChanged: (val) => context.read<ProfileBloc>().add(UpdateEmergencyContactNameEvent(val)),
                decoration: InputDecoration(
                  labelText: 'Nome do Contato',
                  hintText: 'Ex: Maria Silva',
                  errorText: state.isNameValid ? null : 'Nome é obrigatório',
                  filled: true,
                  fillColor: AppTheme.softGreyBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Campo Telefone
          BlocBuilder<ProfileBloc, ProfileState>(
            buildWhen: (previous, current) =>
                previous.emergencyContactPhone != current.emergencyContactPhone ||
                previous.isPhoneValid != current.isPhoneValid,
            builder: (context, state) {
              return TextFormField(
                initialValue: state.emergencyContactPhone,
                onChanged: (val) => context.read<ProfileBloc>().add(UpdateEmergencyContactPhoneEvent(val)),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefone do Contato',
                  hintText: 'Ex: (79) 99999-9999',
                  errorText: state.isPhoneValid ? null : 'Telefone inválido (use o formato: DD + 9 dígitos)',
                  filled: true,
                  fillColor: AppTheme.softGreyBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class GpsStatusIndicator extends StatelessWidget {
  const GpsStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      semanticLabel: "Status da precisão do seu sinal de localização",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const Row(
              children: [
                Icon(Icons.gps_fixed, color: AppTheme.spaceBlue),
                SizedBox(width: 8),
                Text(
                  'Precisão de Localização (GPS)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.spaceBlue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<ProfileBloc, ProfileState>(
            buildWhen: (previous, current) =>
                previous.gpsAccuracy != current.gpsAccuracy ||
                previous.gpsStatus != current.gpsStatus,
            builder: (context, state) {
              final isWeakSignal = state.gpsAccuracy >= 15;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sinal Atual:', style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        state.gpsStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isWeakSignal ? AppTheme.emergencyRed : AppTheme.mintGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: (30 - state.gpsAccuracy).clamp(0, 30) / 30, // Normaliza o valor para a barra
                    backgroundColor: AppTheme.softGreyBg,
                    color: isWeakSignal ? AppTheme.emergencyRed : AppTheme.mintGreen,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Precisão de aproximadamente ${state.gpsAccuracy.toStringAsFixed(1)} metros.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Simula atualização do GPS vinda do GPS do dispositivo
                      context.read<ProfileBloc>().add(UpdateGpsAccuracyEvent(3.2));
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Simular Calibração GPS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.softGreyBg,
                      foregroundColor: AppTheme.spaceBlue,
                      elevation: 0,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class SaveProfileButton extends StatelessWidget {
  const SaveProfileButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      buildWhen: (previous, current) => previous.isSaving != current.isSaving,
      builder: (context, state) {
        return BaseButton(
          label: state.isSaving ? 'Salvando...' : 'Salvar Perfil',
          semanticLabel: 'Salvar alterações do perfil.',
          onPressed: state.isSaving
              ? null
              : () => context.read<ProfileBloc>().add(SaveProfileEvent()),
        );
      },
    );
  }
}
