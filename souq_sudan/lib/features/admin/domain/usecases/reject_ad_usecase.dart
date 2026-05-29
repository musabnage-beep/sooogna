import '../repositories/admin_repository.dart';
import '../../../../core/utils/result.dart';

class RejectAdUseCase {
  final AdminRepository _repository;
  RejectAdUseCase(this._repository);
  Future<Result<void>> call(String adId, String reason) => _repository.rejectAd(adId, reason);
}
