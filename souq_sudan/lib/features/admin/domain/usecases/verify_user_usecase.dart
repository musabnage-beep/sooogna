import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class VerifyUserUseCase {
  final AdminRepository _repository;
  VerifyUserUseCase(this._repository);
  Future<Result<void>> call(String userId, bool isVerified) => _repository.verifyUser(userId, isVerified);
}
