import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

/// Autentica um usuário existente com e-mail e senha.
///
/// Retorna o `userId` em caso de sucesso ou um [AuthFailure] em caso de erro.
class SignInUseCase {
  final AuthRepository _repository;

  const SignInUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}
