import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementação de [AuthRepository] usando o SDK do Supabase.
///
/// ## Mapeamento de exceções
///
/// | Exceção Supabase        | Failure retornado  | Cenário                         |
/// |-------------------------|--------------------|----------------------------------|
/// | `AuthException`         | `AuthFailure`      | Credenciais inválidas, e-mail    |
/// |                         |                    | não confirmado, usuário inativo. |
/// | Qualquer outra exceção  | `AuthFailure`      | Sem rede, timeout, etc.          |
///
/// ## getCurrentUserId
///
/// Leitura síncrona do `currentSession` em memória — sem round-trip de rede.
/// Retorna `null` quando não há sessão ativa (usuário não autenticado ou
/// sessão expirada e não renovada ainda).
///
/// ## Design decisions
///
/// - `GoTrueClient` é acessado via `supabaseClient.auth` para manter o
///   [SupabaseClient] como única dependência injetada.
/// - Os logs de sucesso/falha ficam no repositório; o BLoC não precisa
///   conhecer detalhes do provedor.
class SupabaseAuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabaseClient;

  static const String _logName = 'SupabaseAuthRepositoryImpl';

  const SupabaseAuthRepositoryImpl({required this.supabaseClient});

  // ─── signIn ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> signIn({
    required String email,
    required String password,
  }) async {
    developer.log('Iniciando signIn para: $email', name: _logName);
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final userId = response.user?.id;
      if (userId == null) {
        // Resposta inesperada sem user — não deveria ocorrer, mas tratamos.
        developer.log('signIn: resposta sem userId.', name: _logName);
        return const Left(AuthFailure('Autenticação falhou: usuário nulo.'));
      }

      developer.log('signIn bem-sucedido. userId: $userId', name: _logName);
      debugPrint('[AuthRepo] Login sucesso para usuário: $userId');
      return Right(userId);
    } on AuthException catch (e) {
      developer.log(
        'AuthException no signIn: ${e.message}',
        error: e,
        name: _logName,
      );
      debugPrint('[AuthRepo] Erro de Login (AuthException): ${e.message}');
      return Left(AuthFailure(_friendlyAuthMessage(e)));
    } catch (e) {
      developer.log(
        'Erro inesperado no signIn: $e',
        error: e,
        name: _logName,
      );
      debugPrint('[AuthRepo] Erro de Login (inesperado): $e');
      return Left(AuthFailure('Erro inesperado ao fazer login: $e'));
    }
  }

  // ─── signUp ───────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? emergencyPhone,
    required bool isBlind,
    required bool reducedMobility,
  }) async {
    developer.log('Iniciando signUp para: $email', name: _logName);
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (emergencyPhone != null && emergencyPhone.isNotEmpty)
            'emergencyPhone': emergencyPhone,
          'isBlind': isBlind,
          'reducedMobility': reducedMobility,
        },
      );

      final userId = response.user?.id;
      if (userId == null) {
        // Pode acontecer quando "Email Confirmation" está ativo: o usuário
        // é criado mas a sessão só é aberta após confirmar o e-mail.
        developer.log(
          'signUp: usuário criado, aguardando confirmação de e-mail.',
          name: _logName,
        );
        return const Left(
          AuthFailure(
            'Conta criada! Verifique seu e-mail para confirmar o cadastro.',
          ),
        );
      }

      developer.log('signUp bem-sucedido. userId: $userId', name: _logName);
      return Right(userId);
    } on AuthException catch (e) {
      developer.log(
        'AuthException no signUp: ${e.message}',
        error: e,
        name: _logName,
      );
      return Left(AuthFailure(_friendlyAuthMessage(e)));
    } catch (e) {
      developer.log(
        'Erro inesperado no signUp: $e',
        error: e,
        name: _logName,
      );
      return Left(AuthFailure('Erro inesperado ao criar conta: $e'));
    }
  }

  // ─── signOut ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> signOut() async {
    developer.log('Iniciando signOut.', name: _logName);
    try {
      await supabaseClient.auth.signOut();
      developer.log('signOut bem-sucedido.', name: _logName);
      return const Right(null);
    } on AuthException catch (e) {
      developer.log(
        'AuthException no signOut: ${e.message}',
        error: e,
        name: _logName,
      );
      return Left(AuthFailure(_friendlyAuthMessage(e)));
    } catch (e) {
      developer.log(
        'Erro inesperado no signOut: $e',
        error: e,
        name: _logName,
      );
      return Left(AuthFailure('Erro inesperado ao fazer logout: $e'));
    }
  }

  // ─── getCurrentUserId ─────────────────────────────────────────────────────

  @override
  String? getCurrentUserId() {
    final userId = supabaseClient.auth.currentSession?.user.id;
    developer.log(
      userId != null
          ? 'Sessão ativa. userId: $userId'
          : 'Nenhuma sessão ativa.',
      name: _logName,
    );
    return userId;
  }

  // ─── Helpers privados ─────────────────────────────────────────────────────

  /// Traduz mensagens de [AuthException] do Supabase para português.
  ///
  /// As mensagens originais são em inglês e voltadas para desenvolvedores;
  /// este helper as converte para mensagens amigáveis ao usuário final.
  String _friendlyAuthMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'E-mail ou senha inválidos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'E-mail ainda não confirmado. Verifique sua caixa de entrada.';
    }
    if (msg.contains('user already registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (msg.contains('password should be at least')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    if (msg.contains('rate limit')) {
      return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
    }
    // Fallback: mensagem original traduzida literalmente.
    return 'Erro de autenticação: ${e.message}';
  }
}
