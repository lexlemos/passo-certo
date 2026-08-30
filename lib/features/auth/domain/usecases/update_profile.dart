import '../../../../core/errors/failures.dart';
import '../../../../core/utils/either.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository repository;

  const UpdateProfileUseCase(this.repository);

  Future<Either<Failure, void>> call(User user) async {
    return await repository.updateProfile(user);
  }
}
