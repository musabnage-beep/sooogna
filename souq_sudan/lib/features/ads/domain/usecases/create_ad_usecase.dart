import '../entities/ad_entity.dart';
import '../repositories/ads_repository.dart';
import '../../../../core/utils/result.dart';

class CreateAdUseCase {
  final AdsRepository _repository;
  CreateAdUseCase(this._repository);

  Future<Result<String>> call(Ad ad, List<String> localImagePaths) {
    return _repository.createAd(ad, localImagePaths);
  }
}
