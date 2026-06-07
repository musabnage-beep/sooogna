import '../entities/ad_entity.dart';
import '../../../../core/enums/app_enums.dart';
import '../../../../core/utils/result.dart';

abstract class AdsRepository {
  Future<Result<AdsPage>> getAds({Object? lastDoc, int limit = 20, String? stateFilter});
  Future<Result<List<Ad>>> getFeaturedAds();
  Future<Result<Ad?>> getAdById(String id);
  Future<Result<List<Ad>>> getAdsByUser(String userId);
  Future<Result<AdsPage>> getAdsByCategory(String category, {Object? lastDoc, int limit = 20});
  Future<Result<List<Ad>>> searchAds(String query, {String? category, String? location, String? city, bool directOwnersOnly = false, double? minPrice, double? maxPrice, String? sortBy});
  Future<Result<String>> createAd(Ad ad, List<String> localImagePaths);
  Future<Result<void>> updateAd(Ad ad, List<String> newLocalImagePaths, List<String> removedImageUrls);
  Future<Result<void>> deleteAd(String adId, String userId);
  Future<Result<void>> incrementViewCount(String adId);
  Future<Result<void>> markAsSold(String adId, String userId);
  Future<Result<int>> getUserAdCountToday(String userId);
  Future<Result<List<Ad>>> getAdsByStatus(AdStatus status, {Object? lastDoc, int limit = 20});
  Future<Result<void>> updateAdStatus(String adId, AdStatus status, {String? rejectionReason});
  Future<Result<void>> toggleFeatured(String adId, bool isFeatured);
  Future<Result<void>> bumpAd(String adId);
  Future<Result<void>> requestFeatured(String adId);
}
