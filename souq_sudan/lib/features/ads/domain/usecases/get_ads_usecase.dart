import '../entities/ad_entity.dart';
import '../repositories/ads_repository.dart';
import '../../../../core/utils/result.dart';

class GetAdsUseCase {
  final AdsRepository _repository;
  GetAdsUseCase(this._repository);

  Future<Result<List<Ad>>> call({Object? lastDoc, int limit = 20}) {
    return _repository.getAds(lastDoc: lastDoc, limit: limit);
  }
}
