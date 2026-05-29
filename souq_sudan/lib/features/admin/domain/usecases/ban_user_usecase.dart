import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class BanUserUseCase {
  final AdminRepository _repository;
  BanUserUseCase(this._repository);
  Future<Result<void>> call(String userId, String reason) => _repository.banUser(userId, reason);
}
