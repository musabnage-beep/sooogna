import '../entities/ad_entity.dart';
import '../repositories/ads_repository.dart';
import '../../../../core/utils/result.dart';

class UpdateAdUseCase {
  final AdsRepository _repository;
  UpdateAdUseCase(this._repository);

  Future<Result<void>> call(Ad ad, List<String> newLocalImagePaths, List<String> removedImageUrls) {
    return _repository.updateAd(ad, newLocalImagePaths, removedImageUrls);
  }
}
