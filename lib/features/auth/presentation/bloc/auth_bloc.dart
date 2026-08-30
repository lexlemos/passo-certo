import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up.dart';
import '../../domain/usecases/update_profile.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

/// Verificação de sessão ativa ao abrir o app.
///
/// Emitido uma vez no startup — lê o `currentSession` do cliente Supabase
/// (operação síncrona, sem rede) e decide entre [Authenticated] e
/// [Unauthenticated].
class AuthCheckRequested extends AuthEvent {}

/// Solicita login com [email] e [password].
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Solicita criação de nova conta com [email] e [password].
class AuthSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String? phone;
  final String? emergencyPhone;
  final bool isBlind;
  final bool reducedMobility;

  const AuthSignUpRequested({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
    this.emergencyPhone,
    required this.isBlind,
    required this.reducedMobility,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        name,
        phone,
        emergencyPhone,
        isBlind,
        reducedMobility,
      ];
}

/// Solicita encerramento da sessão atual.
class AuthLogoutRequested extends AuthEvent {}

/// Solicita atualização do perfil do usuário.
class AuthUpdateProfileRequested extends AuthEvent {
  final User user;

  const AuthUpdateProfileRequested(this.user);

  @override
  List<Object?> get props => [user];
}

// ─── States ───────────────────────────────────────────────────────────────────

/// Estado inicial — antes de qualquer verificação de sessão.
class AuthInitial extends AuthState {}

/// Operação de auth em andamento (login, cadastro ou logout).
class AuthLoading extends AuthState {}

/// Usuário autenticado com sessão ativa.
class Authenticated extends AuthState {
  /// Entidade completa do usuário autenticado no Supabase.
  final User user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Nenhuma sessão ativa — usuário deve fazer login ou cadastro.
class Unauthenticated extends AuthState {}

/// Operação de auth falhou — [message] contém uma mensagem amigável ao usuário.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Base classes ─────────────────────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

/// Gerencia o ciclo de vida da autenticação do usuário.
///
/// ## Fluxo de inicialização
///
/// Ao registrar o BLoC, dispare [AuthCheckRequested] imediatamente:
/// ```dart
/// BlocProvider(
///   create: (_) => sl<AuthBloc>()..add(AuthCheckRequested()),
/// )
/// ```
///
/// ## Estados e transições
///
/// ```
/// AuthInitial
///   └─ AuthCheckRequested ──► Authenticated | Unauthenticated
///
/// Unauthenticated
///   ├─ AuthLoginRequested ──► AuthLoading → Authenticated | AuthError
///   └─ AuthSignUpRequested ─► AuthLoading → Authenticated | AuthError
///
/// Authenticated
///   └─ AuthLogoutRequested ─► AuthLoading → Unauthenticated | AuthError
/// ```
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;

  static const String _logName = 'AuthBloc';

  AuthBloc({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
  }) : _getCurrentUserUseCase = getCurrentUserUseCase,
       _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _signOutUseCase = signOutUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUpdateProfileRequested>(_onAuthUpdateProfileRequested);
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  /// Verifica se há uma sessão ativa ao abrir o app.
  ///
  /// Operação síncrona — sem loading state, para evitar flash de tela.
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('Verificando sessão ativa...', name: _logName);
    final user = await _getCurrentUserUseCase();
    if (user != null) {
      developer.log('Sessão encontrada. userId: ${user.id}', name: _logName);
      emit(Authenticated(user));
    } else {
      developer.log('Nenhuma sessão ativa.', name: _logName);
      emit(Unauthenticated());
    }
  }

  /// Processa a requisição de login.
  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('Login solicitado para: ${event.email}', name: _logName);
    emit(AuthLoading());

    final result = await _signInUseCase(
      email: event.email,
      password: event.password,
    );

    await result.fold(
      (failure) async {
        developer.log(
          'Login falhou: ${failure.message}',
          name: _logName,
        );
        emit(AuthError(failure.message));
      },
      (userId) async {
        developer.log('Login bem-sucedido. userId: $userId', name: _logName);
        final user = await _getCurrentUserUseCase();
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const AuthError('Erro ao buscar dados do usuário.'));
        }
      },
    );
  }

  /// Processa a requisição de cadastro.
  Future<void> _onAuthSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('Cadastro solicitado para: ${event.email}', name: _logName);
    emit(AuthLoading());

    final result = await _signUpUseCase(
      email: event.email,
      password: event.password,
      name: event.name,
      phone: event.phone,
      emergencyPhone: event.emergencyPhone,
      isBlind: event.isBlind,
      reducedMobility: event.reducedMobility,
    );

    await result.fold(
      (failure) async {
        developer.log(
          'Cadastro falhou: ${failure.message}',
          name: _logName,
        );
        emit(AuthError(failure.message));
      },
      (userId) async {
        developer.log(
          'Cadastro bem-sucedido. userId: $userId',
          name: _logName,
        );
        // Espera um tempinho pro banco (trigger) terminar de inserir o public.users se precisar.
        await Future.delayed(const Duration(milliseconds: 500));
        final user = await _getCurrentUserUseCase();
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const AuthError('Erro ao buscar dados do usuário recém-criado.'));
        }
      },
    );
  }

  /// Processa a requisição de logout.
  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('Logout solicitado.', name: _logName);
    emit(AuthLoading());

    final result = await _signOutUseCase();

    result.fold(
      (failure) {
        developer.log('Logout falhou: ${failure.message}', name: _logName);
        emit(AuthError(failure.message));
      },
      (_) {
        developer.log('Logout bem-sucedido.', name: _logName);
        emit(Unauthenticated());
      },
    );
  }

  /// Processa a atualização de perfil.
  Future<void> _onAuthUpdateProfileRequested(
    AuthUpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    developer.log('Update de perfil solicitado para: ${event.user.id}', name: _logName);
    // Guarda o estado anterior de sucesso (Authenticated) para fallback
    final currentState = state;
    if (currentState is! Authenticated) return;

    emit(AuthLoading());

    final result = await _updateProfileUseCase(event.user);
    
    result.fold(
      (failure) {
        developer.log('Update falhou: ${failure.message}', name: _logName);
        emit(AuthError(failure.message));
        // Devolve pro Authenticated pra tela voltar a funcionar se foi via dialog
        emit(currentState);
      },
      (_) {
        developer.log('Update bem-sucedido.', name: _logName);
        emit(Authenticated(event.user));
      },
    );
  }
}
