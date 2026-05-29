import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class ApproveAdUseCase {
  final AdminRepository _repository;
  ApproveAdUseCase(this._repository);
  Future<Result<void>> call(String adId) => _repository.approveAd(adId);
}
