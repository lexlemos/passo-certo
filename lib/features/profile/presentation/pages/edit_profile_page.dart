import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emergencyPhoneController;

  late User _currentUser;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUser = authState.user;
    } else {
      // Fallback fallback fallback
      _currentUser = User(
        id: '',
        role: '',
        name: '',
        email: '',
        isBlind: false,
        reducedMobility: false,
        createdAt: DateTime.now(),
      );
    }

    _nameController = TextEditingController(text: _currentUser.name);
    _phoneController = TextEditingController(text: _currentUser.phone ?? '');
    _emergencyPhoneController = TextEditingController(
      text: _currentUser.emergencyPhone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = _currentUser.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      emergencyPhone: _emergencyPhoneController.text.trim(),
    );

    context.read<AuthBloc>().add(AuthUpdateProfileRequested(updatedUser));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Se estava salvando e mudou pro estado autenticado (com sucesso), fecha.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          if (Navigator.canPop(context)) {
            context.pop();
          }
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFD32F2F),
              ),
            );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2E)),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Editar Perfil',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return AbsorbPointer(
              absorbing: isLoading,
              child: Opacity(
                opacity: isLoading ? 0.6 : 1.0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TextField(
                          controller: _nameController,
                          label: 'Nome',
                          hint: 'Seu nome completo',
                          prefixIcon: Icons.person_outline,
                          enabled: !isLoading,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Informe seu nome.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _TextField(
                          controller: _phoneController,
                          label: 'Telefone',
                          hint: '(00) 00000-0000',
                          prefixIcon: Icons.phone_outlined,
                          enabled: !isLoading,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        _TextField(
                          controller: _emergencyPhoneController,
                          label: 'Telefone de Emergência',
                          hint: '(00) 00000-0000',
                          prefixIcon: Icons.contact_phone_outlined,
                          enabled: !isLoading,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: isLoading ? null : _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tealPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Salvar Alterações',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool enabled;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(12));
    const borderColor = Color(0xFFE0E0E0);
    const focusBorderColor = Color(0xFF4DB6AC);

    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF718096), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF718096), size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: focusBorderColor, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: Color(0xFFD32F2F), width: 2),
        ),
      ),
    );
  }
}
