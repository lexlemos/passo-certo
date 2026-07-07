import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
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
                            TextFormField(
                              controller: _controller,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.darkBlue,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Nome do contato ou número',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.tealPrimary, width: 1.5),
                                ),
                              ),
                              validator: _validateEmergencyContact,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            BlocBuilder<ProfileEmergencyBloc, ProfileEmergencyState>(
              builder: (context, state) {
                return BaseButton(
                  label: 'Salvar Perfil',
                  semanticLabel: 'Botão. Salvar todas as configurações de acessibilidade.',
                  borderRadius: 12,
                  icon: const Icon(Icons.save, color: Colors.white),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.tealPrimary,
                      AppColors.switchGreen,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),

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
