import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/base_button.dart';
import '../../../../core/widgets/base_card.dart';
import '../bloc/profile_emergency_bloc.dart';
import 'profile_section_header.dart';

class EmergencyContactSection extends StatefulWidget {
  const EmergencyContactSection({super.key});

  @override
  State<EmergencyContactSection> createState() => _EmergencyContactSectionState();
}

class _EmergencyContactSectionState extends State<EmergencyContactSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ProfileEmergencyBloc>();
    _controller = TextEditingController(text: bloc.state.contactText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<ProfileEmergencyBloc, ProfileEmergencyState>(
      listenWhen: (prev, curr) => prev.contactText != curr.contactText,
      listener: (context, state) {
        _controller.text = state.contactText;
      },
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            BaseCard(
              semanticLabel: "Seção de Contato de Emergência",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfileSectionHeader(
                    icon: Icons.contact_phone,
                    title: 'Contato de Emergência',
                    color: AppTheme.spaceBlue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Contato de Emergência Rápido',
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _controller,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Nome do contato ou número',
                      filled: true,
                      fillColor: theme.scaffoldBackgroundColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: _validateEmergencyContact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            BlocBuilder<ProfileEmergencyBloc, ProfileEmergencyState>(
              builder: (context, state) {
                return BaseButton(
                  label: 'Salvar Perfil',
                  semanticLabel: 'Botão. Salvar todas as configurações de acessibilidade.',
                  onPressed: state.isLoading
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() ?? false) {
                            context.read<ProfileEmergencyBloc>().add(
                                  SaveEmergencyContactEvent(contactInput: _controller.text),
                                );
                          }
                        },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmergencyContact(String? value) {
    if (value == null || value.trim().isEmpty) return 'Por favor, insira um contato de emergência.';
    if (value.trim().length < 3) return 'Contato deve ter pelo menos 3 caracteres.';
    return null;
  }
}
