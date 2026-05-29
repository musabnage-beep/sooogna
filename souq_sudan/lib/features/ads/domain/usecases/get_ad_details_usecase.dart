import '../entities/ad_entity.dart';
import '../repositories/ads_repository.dart';
import '../../../../core/utils/result.dart';

class GetAdDetailsUseCase {
  final AdsRepository _repository;
  GetAdDetailsUseCase(this._repository);

  Future<Result<Ad?>> call(String adId) {
    return _repository.getAdById(adId);
  }
}
