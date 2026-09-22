import '../repositories/auth_repository.dart';

/// Verifica se há uma sessão ativa e retorna o `userId`, ou `null`.
///
/// Operação síncrona — não faz round-trip de rede.
class GetCurrentUserIdUseCase {
  final AuthRepository _repository;

  const GetCurrentUserIdUseCase(this._repository);

  String? call() => _repository.getCurrentUserId();
}
