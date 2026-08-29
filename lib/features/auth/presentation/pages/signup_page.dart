import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/colors/auth_colors.dart';
import '../bloc/auth_bloc.dart';

/// Tela de Cadastro.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isBlind = false;
  bool _reducedMobility = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;
    
    context.read<AuthBloc>().add(
      AuthSignUpRequested(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
        isBlind: _isBlind,
        reducedMobility: _reducedMobility,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
          return;
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFD32F2F),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo ────────────────────────────────────────────────
                Center(
                  child: SvgPicture.asset(
                    'assets/images/Logo_passoufs.svg',
                    height: 56,
                    semanticsLabel: 'Logo Passo Certo',
                  ),
                ),
                const SizedBox(height: 32),
                // ── Título ───────────────────────────────────────────────
                const Text(
                  'Crie sua conta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Preencha seus dados para começar a usar o aplicativo.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF718096),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                
                // ── Formulário ───────────────────────────────────────────
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return AbsorbPointer(
                      absorbing: isLoading,
                      child: Opacity(
                        opacity: isLoading ? 0.55 : 1.0,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nome
                              _AuthTextField(
                                controller: _nameController,
                                label: 'Nome Completo',
                                hint: 'Seu nome',
                                prefixIcon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                enabled: !isLoading,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe seu nome.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // E-mail
                              _AuthTextField(
                                controller: _emailController,
                                label: 'E-mail',
                                hint: 'seu@email.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                enabled: !isLoading,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe seu e-mail.';
                                  }
                                  if (!value.contains('@') || !value.contains('.')) {
                                    return 'E-mail inválido.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Senha
                              _AuthTextField(
                                controller: _passwordController,
                                label: 'Senha',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.next,
                                enabled: !isLoading,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF718096),
                                    size: 20,
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return 'A senha deve ter pelo menos 6 caracteres.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Telefone
                              _AuthTextField(
                                controller: _phoneController,
                                label: 'Telefone (Opcional)',
                                hint: '(11) 99999-9999',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                enabled: !isLoading,
                              ),
                              const SizedBox(height: 16),
                              
                              // Telefone de Emergência
                              _AuthTextField(
                                controller: _emergencyPhoneController,
                                label: 'Telefone de Emergência (Opcional)',
                                hint: '(11) 99999-9999',
                                prefixIcon: Icons.health_and_safety_outlined,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                enabled: !isLoading,
                              ),
                              const SizedBox(height: 24),
                              
                              // Perguntas de Acessibilidade
                              const Text(
                                'Acessibilidade',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              
                              SwitchListTile(
                                title: const Text('Possui deficiência visual (cego)?'),
                                value: _isBlind,
                                activeTrackColor: AuthColors.tealLink,
                                inactiveThumbColor: Colors.grey,
                                contentPadding: EdgeInsets.zero,
                                onChanged: isLoading
                                    ? null
                                    : (val) => setState(() => _isBlind = val),
                              ),
                              
                              SwitchListTile(
                                title: const Text('Possui mobilidade reduzida?'),
                                value: _reducedMobility,
                                activeTrackColor: AuthColors.tealLink,
                                inactiveThumbColor: Colors.grey,
                                contentPadding: EdgeInsets.zero,
                                onChanged: isLoading
                                    ? null
                                    : (val) => setState(() => _reducedMobility = val),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                // ── Botão principal ─────────────────────────────────────────
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return _GradientButton(
                      label: 'Cadastrar',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : _onSubmit,
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                // ── Rodapé: link para login ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Já tem uma conta? ',
                      style: TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: const Text(
                        'Entrar',
                        style: TextStyle(
                          color: AuthColors.tealLink,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Componentes internos ─────────────────────────────────────────────────────

/// Campo de texto estilizado (copiado de login_page para consistência local)
class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.suffixIcon,
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
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
        labelStyle: const TextStyle(color: Color(0xFF718096), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF718096), size: 20),
        suffixIcon: suffixIcon,
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

/// Botão de ação principal (copiado de login_page)
class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4DB6AC), // Verde claro
              Color(0xFF2E7D32), // Verde escuro
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: const Color(0xFF4DB6AC).withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
