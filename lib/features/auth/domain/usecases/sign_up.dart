import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../repositories/auth_repository.dart';

/// Cria uma nova conta de usuário com e-mail e senha.
///
/// Retorna o `userId` do usuário criado ou um [AuthFailure] em caso de erro.
class SignUpUseCase {
  final AuthRepository _repository;

  const SignUpUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? emergencyPhone,
    required bool isBlind,
    required bool reducedMobility,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
      emergencyPhone: emergencyPhone,
      isBlind: isBlind,
      reducedMobility: reducedMobility,
    );
  }
}
