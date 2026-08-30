import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user.dart';

/// Contrato do repositório de autenticação.
///
/// Define as operações de auth que a camada de domínio conhece,
/// sem acoplamento a nenhum provedor concreto (Supabase, Firebase, etc.).
abstract class AuthRepository {
  /// Autentica um usuário existente com [email] e [password].
  ///
  /// Retorna o `userId` (UUID) do usuário autenticado em caso de sucesso,
  /// ou um [Failure] descritivo em caso de erro (credenciais inválidas,
  /// sem conectividade, etc.).
  Future<Either<Failure, String>> signIn({
    required String email,
    required String password,
  });

  /// Cria uma nova conta com [email] e [password].
  ///
  /// Retorna o `userId` do usuário recém-criado em caso de sucesso.
  /// O Supabase envia um e-mail de confirmação automaticamente se a
  /// opção "Email Confirmation" estiver ativa no projeto.
  Future<Either<Failure, String>> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? emergencyPhone,
    required bool isBlind,
    required bool reducedMobility,
  });

  /// Encerra a sessão atual do usuário.
  Future<Either<Failure, void>> signOut();

  /// Retorna o `userId` do usuário com sessão ativa, ou `null` se não
  /// houver sessão (usuário não autenticado / sessão expirada).
  ///
  /// Esta operação é **síncrona** — lê o estado em memória do cliente
  /// Supabase, sem round-trip de rede.
  String? getCurrentUserId();

  /// Busca a entidade de usuário completa baseando-se no ID atual.
  Future<User?> getCurrentUser();

  /// Atualiza os dados de perfil do usuário.
  Future<Either<Failure, void>> updateProfile(User user);
}
