import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

class GetCurrentUserUseCase {
  final AuthRepository _repository;
  GetCurrentUserUseCase(this._repository);

  Future<Result<AppUser?>> call() {
    return _repository.getCurrentUser();
  }
}
