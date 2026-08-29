import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../bloc/auth_bloc.dart';

/// Splash screen inteligente que atua como portão de autenticação.
///
/// Ao ser montado, dispara [AuthCheckRequested] para verificar se há uma
/// sessão Supabase ativa (operação síncrona, sem rede).
///
/// ## Transições de estado
///
/// | Estado recebido  | Ação                                         |
/// |------------------|----------------------------------------------|
/// | `AuthInitial`    | Exibe splash com logo (aguardando check)     |
/// | `AuthLoading`    | Exibe splash com logo (aguardando operação)  |
/// | `Authenticated`  | `pushReplacement` → `/home`                  |
/// | `Unauthenticated`| `pushReplacement` → `/login`                 |
/// | `AuthError`      | Redireciona para `/login` (segurança)         |
///
/// O `BlocListener` garante que a navegação ocorra apenas uma vez por
/// mudança de estado, sem re-renders desnecessários da splash.
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Dispara a verificação de sessão assim que o widget é montado.
    // O BLocListener abaixo reagirá ao estado resultante.
    context.read<AuthBloc>().add(AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.go('/home');
        } else if (state is Unauthenticated || state is AuthError) {
          context.go('/login');
        }
      },
      // Enquanto o estado for Initial ou Loading, exibe a splash.
      child: _SplashScreen(),
    );
  }
}

/// Splash screen com logo centralizada em fundo branco.
class _SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SvgPicture.asset(
          'assets/images/Logo_passoufs.svg',
          height: 80,
          semanticsLabel: 'Logo Passo Certo',
        ),
      ),
    );
  }
}
