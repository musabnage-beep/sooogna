import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class UnbanUserUseCase {
  final AdminRepository _repository;
  UnbanUserUseCase(this._repository);
  Future<Result<void>> call(String userId) => _repository.unbanUser(userId);
}
