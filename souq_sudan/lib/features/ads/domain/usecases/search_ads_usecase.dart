import '../entities/ad_entity.dart';
import '../repositories/ads_repository.dart';
import '../../../../core/utils/result.dart';

class SearchAdsUseCase {
  final AdsRepository _repository;
  SearchAdsUseCase(this._repository);

  Future<Result<List<Ad>>> call(String query, {String? category, String? location, double? minPrice, double? maxPrice, String? sortBy}) {
    return _repository.searchAds(query, category: category, location: location, minPrice: minPrice, maxPrice: maxPrice, sortBy: sortBy);
  }
}
