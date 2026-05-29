import '../repositories/ads_repository.dart';
import '../../../../core/utils/result.dart';

class DeleteAdUseCase {
  final AdsRepository _repository;
  DeleteAdUseCase(this._repository);

  Future<Result<void>> call(String adId, String userId) {
    return _repository.deleteAd(adId, userId);
  }
}
