import '../../../../core/utils/result.dart';
import '../../../ads/domain/entities/ad_entity.dart';
import '../entities/favorite_ad.dart';

abstract class FavoritesRepository {
  Stream<List<FavoriteAd>> watchFavorites(String uid);
  Stream<Set<String>> watchFavoriteIds(String uid);
  Future<Result<void>> addFavorite(String uid, Ad ad);
  Future<Result<void>> removeFavorite(String uid, String adId);
}
